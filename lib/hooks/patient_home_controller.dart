import 'dart:async';

import 'package:flutter/foundation.dart';

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../services/delivery_service.dart';
import '../services/pendientes_service.dart';
import '../types/delivery.dart';
import '../types/order.dart';
import '../types/pendiente.dart';
import 'patient_orders_controller.dart';

/// Lo que la home muestra primero: el estado real del paciente.
///
/// Solo se construye con datos que ya entregan los servicios. Nunca se inventa un estado.
sealed class FocoInicio {
  const FocoInicio();
}

/// Un domicilio en curso: tiene un estado de entrega distinto de los terminales.
final class FocoDomicilio extends FocoInicio {
  const FocoDomicilio({required this.pedido, required this.estado, this.detalle});

  final PatientOrder pedido;
  final DeliveryStatus estado;

  /// Detalle de la entrega (llegada estimada, distancia). `null` si Geolocation no respondió.
  final Delivery? detalle;
}

/// Un pendiente que conviene mirar: el primero que sigue vigente, o el más reciente.
final class FocoPendiente extends FocoInicio {
  const FocoPendiente(this.pendiente);

  final PendienteResumen pendiente;
}

/// No hay domicilio en curso ni pendientes.
final class FocoVacio extends FocoInicio {
  const FocoVacio();
}

/// Regla de selección del foco. Pura y sin red: se prueba directamente.
///
/// 1. Domicilio en curso (el más reciente), con estado de entrega conocido y no terminal.
/// 2. Pendiente vigente con la fecha límite más cercana.
/// 3. Si no hay vigentes, el pendiente más reciente (el backend lo entrega primero).
/// 4. Nada de lo anterior: vacío.
FocoInicio elegirFoco({
  required List<PatientOrder> pedidos,
  required DeliveryStatus? Function(PatientOrder pedido) estadoDe,
  required List<PendienteResumen> pendientes,
  Delivery? Function(PatientOrder pedido)? detalleDe,
}) {
  final activos = <(PatientOrder, DeliveryStatus)>[];
  for (final pedido in pedidos) {
    final estado = estadoDe(pedido);
    if (estado == null || estado.isFinished || estado == DeliveryStatus.unknown) continue;
    if (pedido.status == OrderStatus.cancelled || pedido.status == OrderStatus.unknown) continue;
    activos.add((pedido, estado));
  }
  if (activos.isNotEmpty) {
    activos.sort((a, b) => (b.$1.createdAt ?? DateTime(0)).compareTo(a.$1.createdAt ?? DateTime(0)));
    final (pedido, estado) = activos.first;
    return FocoDomicilio(pedido: pedido, estado: estado, detalle: detalleDe?.call(pedido));
  }

  if (pendientes.isEmpty) return const FocoVacio();
  final vigentes = pendientes.where((p) => p.cumplimientoPlazo == CumplimientoPlazo.vigente).toList()
    ..sort((a, b) => a.fechaLimite.compareTo(b.fechaLimite));
  return FocoPendiente(vigentes.isNotEmpty ? vigentes.first : pendientes.first);
}

/// Entrega recibida que el paciente aún no califica: la home se lo recuerda.
final class PorCalificar {
  const PorCalificar({required this.deliveryId, this.farmacia});

  final String deliveryId;

  /// Nombre de la farmacia del pedido, si se conoce.
  final String? farmacia;
}

/// Solo se recuerda durante unos días: después ya no aporta.
const ventanaRecordatorio = Duration(days: 7);

/// La entrega más reciente que se puede calificar (recibida hace menos de [ventanaRecordatorio]).
/// Pura y sin red.
PorCalificar? elegirPorCalificar({
  required List<Delivery> entregas,
  required List<PatientOrder> pedidos,
  required DateTime ahora,
}) {
  final candidatas = entregas
      .where((d) => d.canBeRated && (d.deliveredAt == null || ahora.difference(d.deliveredAt!) <= ventanaRecordatorio))
      .toList()
    ..sort((a, b) => (b.deliveredAt ?? DateTime(0)).compareTo(a.deliveredAt ?? DateTime(0)));
  if (candidatas.isEmpty) return null;
  final entrega = candidatas.first;
  final pedido = pedidos.where((p) => p.deliveryId == entrega.id).firstOrNull;
  return PorCalificar(deliveryId: entrega.id, farmacia: pedido?.pharmacy.name);
}

/// Carga la home del paciente con los controladores y servicios que ya existen.
class PatientHomeController extends ChangeNotifier {
  PatientHomeController({
    required PatientOrdersController orders,
    required PendientesService pendientes,
    required DeliveryService deliveries,
  })  : _orders = orders,
        _pendientes = pendientes,
        _deliveries = deliveries;

  final PatientOrdersController _orders;
  final PendientesService _pendientes;
  final DeliveryService _deliveries;

  /// Pendientes que se consultan para elegir el foco (la lista completa no hace falta aquí).
  static const limitePendientes = 25;

  FocoInicio? foco;

  /// Recordatorio «¿Cómo estuvo tu entrega?» (null si no hay nada por calificar).
  PorCalificar? porCalificar;
  List<PendienteResumen> pendientes = const [];
  Delivery? detalleEntrega;
  AppError? errorPedidos;
  AppError? errorPendientes;
  bool loading = false;
  bool _disposed = false;

  final Stopwatch _desdeCarga = Stopwatch();

  /// Tiempo desde que llegaron los pendientes (el reloj se calcula contra el servidor).
  Duration get desdeCarga => _desdeCarga.elapsed;

  /// Ambas fuentes fallaron: no hay nada que mostrar.
  bool get sinDatos => foco == null && errorPedidos != null && errorPendientes != null;

  Future<void> load() async {
    loading = true;
    _notify();
    final pedidos = _orders.load();
    final lista = _pendientes.listar(pagina: 1, limite: limitePendientes);
    await Future.wait([pedidos, lista.then<void>((_) {}, onError: (_) {})]);

    errorPedidos = _orders.error;
    try {
      final pagina = await lista;
      pendientes = pagina.items;
      errorPendientes = null;
      _desdeCarga
        ..reset()
        ..start();
    } catch (e) {
      pendientes = const [];
      errorPendientes = ErrorMapper.fromException(e);
    }

    final elegido = elegirFoco(
      pedidos: _orders.orders,
      estadoDe: _orders.deliveryStatusOf,
      pendientes: pendientes,
    );
    porCalificar = elegirPorCalificar(entregas: _orders.deliveries, pedidos: _orders.orders, ahora: DateTime.now());
    detalleEntrega = null;
    if (elegido is FocoDomicilio) {
      detalleEntrega = await _detalle(elegido.pedido.deliveryId);
    }
    foco = detalleEntrega == null
        ? elegido
        : elegirFoco(
            pedidos: _orders.orders,
            estadoDe: _orders.deliveryStatusOf,
            pendientes: pendientes,
            detalleDe: (_) => detalleEntrega,
          );
    loading = false;
    _notify();
  }

  /// Llegada estimada y distancia. Si falla, la home sigue con el estado de la lista.
  Future<Delivery?> _detalle(String deliveryId) async {
    if (deliveryId.isEmpty) return null;
    try {
      return await _deliveries.get(deliveryId);
    } catch (_) {
      return null;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
