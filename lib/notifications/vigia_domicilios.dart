import 'dart:async';

import '../services/delivery_service.dart';
import '../services/order_service.dart';
import '../types/delivery.dart';
import '../types/order.dart';

/// Tono del aviso de un cambio: informa, confirma algo bueno o alerta de un problema.
enum TonoEvento { info, exito, problema }

/// Un cambio en un domicilio que la persona debe saber aunque no tenga abierto el seguimiento.
class EventoDomicilio {
  const EventoDomicilio({required this.clave, required this.titulo, required this.mensaje, required this.ruta, this.tono = TonoEvento.info});

  /// Identifica el cambio (domicilio + estado) para no avisarlo dos veces.
  final String clave;
  final String titulo;
  final String mensaje;

  /// Pantalla que abre la notificación.
  final String ruta;
  final TonoEvento tono;
}

/// Lo que se sabe de los domicilios de la persona en una revisión.
class FotoDomicilios {
  const FotoDomicilios({this.estados = const {}, this.farmacias = const {}, this.pedidos = const {}, this.disponibles = const {}});

  /// Estado de cada domicilio por `deliveryId`.
  final Map<String, DeliveryStatus> estados;

  /// Nombre de la farmacia de cada domicilio (`deliveryId` → farmacia).
  final Map<String, String> farmacias;

  /// Pedido de cada domicilio (`deliveryId` → `orderId`), para abrir la pantalla del repartidor.
  final Map<String, String> pedidos;

  /// Repartidor: pedidos esperando quién los tome (`orderId` → farmacia).
  final Map<String, String> disponibles;
}

typedef RutaDomicilio = String Function(String deliveryId);

/// Cambios del paciente: un repartidor tomó el pedido, lo recogió, va en camino, está llegando o
/// no pudo entregarlo. La entrega y la cancelación las hace el mismo paciente, así que no se avisan.
List<EventoDomicilio> cambiosDelPaciente(FotoDomicilios antes, FotoDomicilios ahora, RutaDomicilio ruta) => [
      for (final MapEntry(key: id, value: estado) in ahora.estados.entries)
        if (_avanzo(antes.estados[id] ?? DeliveryStatus.created, estado))
          if (_mensajePaciente(estado, ahora.farmacias[id]) case (final titulo, final mensaje, final tono))
            EventoDomicilio(clave: '$id:${estado.code}', titulo: titulo, mensaje: mensaje, ruta: ruta(id), tono: tono),
    ];

(String, String, TonoEvento)? _mensajePaciente(DeliveryStatus estado, String? farmacia) {
  final de = farmacia == null ? '' : ' de $farmacia';
  return switch (estado) {
    DeliveryStatus.assigned => ('Un repartidor tomó tu pedido', 'Va a recoger tu pedido$de.', TonoEvento.info),
    DeliveryStatus.pickedUp => ('Tu pedido salió de la farmacia', 'El repartidor ya recogió tu pedido$de.', TonoEvento.info),
    DeliveryStatus.inTransit => ('Tu pedido va en camino', 'Síguelo en el mapa hasta tu puerta.', TonoEvento.info),
    DeliveryStatus.arriving => ('Tu repartidor está llegando', 'Ten a mano tu código de entrega.', TonoEvento.info),
    DeliveryStatus.failed => ('No se pudo entregar tu pedido', 'El repartidor no pudo completar la entrega$de.', TonoEvento.problema),
    _ => null,
  };
}

/// Cambios del repartidor: el paciente canceló o confirmó una entrega suya, o hay pedidos nuevos
/// para tomar.
List<EventoDomicilio> cambiosDelRepartidor(
  FotoDomicilios antes,
  FotoDomicilios ahora, {
  required String Function(String orderId) rutaEntrega,
  required String rutaTablero,
}) {
  final eventos = <EventoDomicilio>[];
  for (final MapEntry(key: id, value: estado) in ahora.estados.entries) {
    final previo = antes.estados[id];
    if (previo == null || previo.isFinished || previo == estado) continue;
    final farmacia = ahora.farmacias[id];
    final pedido = ahora.pedidos[id];
    final abrir = pedido == null ? rutaTablero : rutaEntrega(pedido);
    if (estado == DeliveryStatus.cancelled) {
      eventos.add(EventoDomicilio(
        clave: '$id:${estado.code}',
        titulo: 'El paciente canceló un pedido',
        mensaje: farmacia == null ? 'Ya no tienes que entregarlo.' : 'Ya no tienes que recoger el pedido de $farmacia.',
        ruta: rutaTablero,
        tono: TonoEvento.problema,
      ));
    } else if (estado == DeliveryStatus.delivered) {
      eventos.add(EventoDomicilio(
        clave: '$id:${estado.code}',
        titulo: 'Entrega confirmada',
        mensaje: farmacia == null ? 'El paciente confirmó con tu código.' : 'El pedido de $farmacia quedó entregado.',
        ruta: abrir,
        tono: TonoEvento.exito,
      ));
    }
  }
  final nuevos = [for (final e in ahora.disponibles.entries) if (!antes.disponibles.containsKey(e.key)) e];
  if (nuevos.isNotEmpty) {
    eventos.add(EventoDomicilio(
      clave: 'disponibles:${nuevos.map((e) => e.key).join(',')}',
      titulo: nuevos.length == 1 ? 'Hay un pedido nuevo para tomar' : 'Hay ${nuevos.length} pedidos nuevos para tomar',
      mensaje: nuevos.length == 1 ? 'Recógelo en ${nuevos.single.value}.' : 'Míralos en Domicilios.',
      ruta: rutaTablero,
    ));
  }
  return eventos;
}

/// Orden del recorrido: solo se avisa cuando el domicilio avanza (una respuesta vieja no repite avisos).
bool _avanzo(DeliveryStatus antes, DeliveryStatus ahora) {
  if (antes == ahora) return false;
  if (ahora == DeliveryStatus.failed || ahora == DeliveryStatus.cancelled) return !antes.isFinished;
  return _orden(ahora) > _orden(antes);
}

int _orden(DeliveryStatus s) => switch (s) {
      DeliveryStatus.created => 0,
      DeliveryStatus.assigned => 1,
      DeliveryStatus.pickedUp => 2,
      DeliveryStatus.inTransit => 3,
      DeliveryStatus.arriving => 4,
      DeliveryStatus.delivered || DeliveryStatus.failed || DeliveryStatus.cancelled => 5,
      DeliveryStatus.unknown => -1,
    };

enum RolVigilado { paciente, repartidor }

/// Revisa los domicilios cada [intervalo] mientras la app está visible y avisa de cada cambio.
///
/// La primera revisión solo toma la foto de partida: no avisa de lo que ya pasó. Si una revisión
/// falla (sin señal), se conserva la foto anterior y se intenta en la siguiente.
class VigiaDomicilios {
  VigiaDomicilios({
    required OrderService orders,
    required DeliveryService deliveries,
    required this.onEvento,
    required this.rutaSeguimiento,
    required this.rutaEntrega,
    required this.rutaTablero,
    this.intervalo = const Duration(seconds: 20),
  })  : _orders = orders,
        _deliveries = deliveries;

  final OrderService _orders;
  final DeliveryService _deliveries;
  final void Function(EventoDomicilio evento) onEvento;
  final RutaDomicilio rutaSeguimiento;
  final String Function(String orderId) rutaEntrega;
  final String rutaTablero;
  final Duration intervalo;

  RolVigilado? _rol;
  FotoDomicilios? _foto;
  Timer? _temporizador;
  bool _revisando = false;
  int _generacion = 0;
  final _avisados = <String>{};

  RolVigilado? get rol => _rol;

  /// Empieza a vigilar (o cambia de persona). Sin rol que vigilar, se detiene.
  void iniciar(RolVigilado? rol) {
    if (rol == _rol && _temporizador != null) return;
    detener();
    _rol = rol;
    if (rol == null) return;
    reanudar();
  }

  /// La app vuelve a verse: revisa ya y sigue cada [intervalo].
  void reanudar() {
    if (_rol == null) return;
    _temporizador?.cancel();
    _temporizador = Timer.periodic(intervalo, (_) => unawaited(revisarAhora()));
    unawaited(revisarAhora());
  }

  /// La app se oculta: no gasta datos ni batería revisando.
  void pausar() {
    _temporizador?.cancel();
    _temporizador = null;
  }

  void detener() {
    pausar();
    _rol = null;
    _foto = null;
    _avisados.clear();
    _generacion++;
  }

  Future<void> revisarAhora() async {
    final rol = _rol;
    if (rol == null || _revisando) return;
    _revisando = true;
    final generacion = _generacion;
    try {
      final ahora = rol == RolVigilado.paciente ? await _fotoPaciente() : await _fotoRepartidor();
      if (generacion != _generacion) return; // cerró sesión mientras tanto
      final antes = _foto;
      _foto = ahora;
      if (antes == null) return;
      final eventos = rol == RolVigilado.paciente
          ? cambiosDelPaciente(antes, ahora, rutaSeguimiento)
          : cambiosDelRepartidor(antes, ahora, rutaEntrega: rutaEntrega, rutaTablero: rutaTablero);
      for (final evento in eventos) {
        if (_avisados.add(evento.clave)) onEvento(evento);
      }
    } catch (_) {
      // Sin señal o servicio caído: se intenta en la siguiente revisión.
    } finally {
      _revisando = false;
    }
  }

  Future<FotoDomicilios> _fotoPaciente() async {
    final (pedidos, entregas) = await (_orders.myOrders(), _deliveries.listMine()).wait;
    return FotoDomicilios(
      estados: {for (final d in entregas) d.id: d.status},
      farmacias: {for (final p in pedidos) p.deliveryId: p.pharmacy.name},
    );
  }

  Future<FotoDomicilios> _fotoRepartidor() async {
    final (tomados, entregas, disponibles) =
        await (_orders.taken(), _deliveries.listMine(), _orders.available()).wait;
    final estados = {for (final d in entregas) d.id: d.status};
    // Un pedido cancelado puede seguir con el domicilio sin cerrar en Geolocation.
    for (final p in tomados) {
      if (p.status == OrderStatus.cancelled) estados[p.deliveryId] = DeliveryStatus.cancelled;
    }
    return FotoDomicilios(
      estados: estados,
      farmacias: {for (final p in tomados) p.deliveryId: p.pharmacy.name},
      pedidos: {for (final p in tomados) p.deliveryId: p.id},
      disponibles: {for (final o in disponibles) o.id: o.pharmacy.name},
    );
  }
}
