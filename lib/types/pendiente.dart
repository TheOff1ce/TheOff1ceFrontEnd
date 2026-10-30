/// Modelos de la API de Pendientes (`pendientes-service`, contrato provisional v0.4.0).
///
/// El frontend solo presenta lo que entrega el backend: los estados y la fecha límite se calculan
/// allá (manual §15). Un valor desconocido en un enum lanza [FormatException] en lugar de
/// inventar un estado.
library;

/// Estado de entrega del pendiente o de un medicamento.
enum EstadoEntrega {
  pendiente('PENDIENTE'),
  entregado('ENTREGADO');

  const EstadoEntrega(this.wire);

  /// Valor que viaja por la API.
  final String wire;

  static EstadoEntrega parse(Object? value) {
    for (final estado in values) {
      if (estado.wire == value) return estado;
    }
    throw FormatException('estadoEntrega desconocido: $value');
  }
}

/// Cumplimiento del plazo de 48 h, calculado por el backend en `evaluadoEn`.
enum CumplimientoPlazo {
  vigente('VIGENTE', 'Vigente'),
  cumplido('CUMPLIDO', 'Cumplido'),
  incumplido('INCUMPLIDO', 'Incumplido');

  const CumplimientoPlazo(this.wire, this.etiqueta);

  final String wire;

  /// Palabra del sello de estado (vocabulario fijo del manual, §11).
  final String etiqueta;

  static CumplimientoPlazo parse(Object? value) {
    for (final estado in values) {
      if (estado.wire == value) return estado;
    }
    throw FormatException('cumplimientoPlazo desconocido: $value');
  }
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Falta "$key"');
}

int _int(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value.toInt();
  throw FormatException('Falta "$key"');
}

DateTime _date(Map<String, dynamic> json, String key) => DateTime.parse(_string(json, key)).toUtc();

DateTime? _dateOrNull(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) return DateTime.parse(value).toUtc();
  throw FormatException('"$key" no es una fecha');
}

List<Map<String, dynamic>> _objects(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) throw FormatException('Falta la lista "$key"');
  return [
    for (final item in value)
      if (item is Map<String, dynamic>) item else throw FormatException('Elemento inválido en "$key"'),
  ];
}

/// Pendiente tal como llega en la lista (sin medicamentos ni novedades).
class PendienteResumen {
  const PendienteResumen({
    required this.id,
    required this.ordenMedicamentoId,
    required this.pacienteId,
    required this.epsUserId,
    required this.dispensarioId,
    required this.fechaEvento,
    required this.fechaRegistro,
    required this.fechaLimite,
    required this.estadoEntrega,
    required this.fechaEntrega,
    required this.cumplimientoPlazo,
    required this.evaluadoEn,
    required this.medicamentosTotal,
    required this.medicamentosEntregados,
    required this.cantidadNovedades,
  });

  factory PendienteResumen.fromJson(Map<String, dynamic> json) => PendienteResumen(
        id: _string(json, 'id'),
        ordenMedicamentoId: _string(json, 'ordenMedicamentoId'),
        pacienteId: _string(json, 'pacienteId'),
        epsUserId: _string(json, 'epsUserId'),
        dispensarioId: _string(json, 'dispensarioId'),
        fechaEvento: _date(json, 'fechaEvento'),
        fechaRegistro: _date(json, 'fechaRegistro'),
        fechaLimite: _date(json, 'fechaLimite'),
        estadoEntrega: EstadoEntrega.parse(json['estadoEntrega']),
        fechaEntrega: _dateOrNull(json, 'fechaEntrega'),
        cumplimientoPlazo: CumplimientoPlazo.parse(json['cumplimientoPlazo']),
        evaluadoEn: _date(json, 'evaluadoEn'),
        medicamentosTotal: _int(json, 'medicamentosTotal'),
        medicamentosEntregados: _int(json, 'medicamentosEntregados'),
        cantidadNovedades: _int(json, 'cantidadNovedades'),
      );

  final String id;

  /// Pedido de origen (`OrdenMedicamento`).
  final String ordenMedicamentoId;
  final String pacienteId;
  final String epsUserId;
  final String dispensarioId;

  /// Dispensación incompleta en el origen: inicia el plazo.
  final DateTime fechaEvento;
  final DateTime fechaRegistro;

  /// `fechaEvento` + plazo (48 h corridas). Siempre viene del backend.
  final DateTime fechaLimite;
  final EstadoEntrega estadoEntrega;

  /// Última entrega; `null` mientras falte algún medicamento.
  final DateTime? fechaEntrega;
  final CumplimientoPlazo cumplimientoPlazo;

  /// Instante del servidor en que se calculó [cumplimientoPlazo].
  final DateTime evaluadoEn;
  final int medicamentosTotal;
  final int medicamentosEntregados;
  final int cantidadNovedades;

  /// Plazo total (por defecto 48 h, configurable en el backend).
  Duration get plazoTotal => fechaLimite.difference(fechaEvento);

  /// Hora del servidor [desdeCarga] después de haber recibido los datos.
  ///
  /// Se ancla a [evaluadoEn] y no al reloj del dispositivo, para que un reloj desajustado
  /// no cambie el tiempo restante que ve la persona.
  DateTime ahora(Duration desdeCarga) => evaluadoEn.add(desdeCarga);

  Duration restante(Duration desdeCarga) => fechaLimite.difference(ahora(desdeCarga));

  /// El backend aún dice "vigente", pero la fecha límite ya pasó: hay que volver a consultar.
  bool vencioSinActualizar(Duration desdeCarga) =>
      cumplimientoPlazo == CumplimientoPlazo.vigente && restante(desdeCarga) <= Duration.zero;

  PendienteResumen conNovedadAgregada() => PendienteResumen(
        id: id,
        ordenMedicamentoId: ordenMedicamentoId,
        pacienteId: pacienteId,
        epsUserId: epsUserId,
        dispensarioId: dispensarioId,
        fechaEvento: fechaEvento,
        fechaRegistro: fechaRegistro,
        fechaLimite: fechaLimite,
        estadoEntrega: estadoEntrega,
        fechaEntrega: fechaEntrega,
        cumplimientoPlazo: cumplimientoPlazo,
        evaluadoEn: evaluadoEn,
        medicamentosTotal: medicamentosTotal,
        medicamentosEntregados: medicamentosEntregados,
        cantidadNovedades: cantidadNovedades + 1,
      );
}

/// Medicamento faltante de un pendiente. La API solo entrega su identificador de origen.
class MedicamentoPendiente {
  const MedicamentoPendiente({
    required this.medicamentoId,
    required this.fechaHabilitacion,
    required this.fechaEntrega,
    required this.estadoEntrega,
  });

  factory MedicamentoPendiente.fromJson(Map<String, dynamic> json) => MedicamentoPendiente(
        medicamentoId: _string(json, 'medicamentoId'),
        fechaHabilitacion: _dateOrNull(json, 'fechaHabilitacion'),
        fechaEntrega: _dateOrNull(json, 'fechaEntrega'),
        estadoEntrega: EstadoEntrega.parse(json['estadoEntrega']),
      );

  final String medicamentoId;

  /// La EPS lo habilitó para entrega a domicilio. Habilitar no es entregar.
  final DateTime? fechaHabilitacion;
  final DateTime? fechaEntrega;
  final EstadoEntrega estadoEntrega;
}

class Novedad {
  const Novedad({required this.id, required this.fechaHora, required this.tipo, required this.detalle});

  factory Novedad.fromJson(Map<String, dynamic> json) => Novedad(
        id: _string(json, 'id'),
        fechaHora: _date(json, 'fechaHora'),
        tipo: _string(json, 'tipo'),
        detalle: _string(json, 'detalle'),
      );

  final String id;
  final DateTime fechaHora;

  /// Texto libre provisional: el catálogo de tipos de novedad no está definido.
  final String tipo;
  final String detalle;
}

/// Detalle de un pendiente: resumen + medicamentos + novedades (en orden cronológico).
class PendienteDetalle {
  const PendienteDetalle({required this.resumen, required this.medicamentos, required this.novedades});

  factory PendienteDetalle.fromJson(Map<String, dynamic> json) => PendienteDetalle(
        resumen: PendienteResumen.fromJson(json),
        medicamentos: [for (final item in _objects(json, 'medicamentos')) MedicamentoPendiente.fromJson(item)],
        novedades: [for (final item in _objects(json, 'novedades')) Novedad.fromJson(item)],
      );

  final PendienteResumen resumen;
  final List<MedicamentoPendiente> medicamentos;
  final List<Novedad> novedades;

  PendienteDetalle conNovedad(Novedad novedad) => PendienteDetalle(
        resumen: resumen.conNovedadAgregada(),
        medicamentos: medicamentos,
        novedades: [...novedades, novedad],
      );
}

/// Página de resultados de `GET /pendientes`.
class PaginaPendientes {
  const PaginaPendientes({required this.items, required this.pagina, required this.limite, required this.total});

  factory PaginaPendientes.fromJson(Map<String, dynamic> json) => PaginaPendientes(
        items: [for (final item in _objects(json, 'items')) PendienteResumen.fromJson(item)],
        pagina: _int(json, 'pagina'),
        limite: _int(json, 'limite'),
        total: _int(json, 'total'),
      );

  final List<PendienteResumen> items;
  final int pagina;
  final int limite;
  final int total;

  /// Posición (1-based) del primer elemento de la página dentro del total.
  int get desde => items.isEmpty ? 0 : (pagina - 1) * limite + 1;
  int get hasta => items.isEmpty ? 0 : (pagina - 1) * limite + items.length;
  bool get hayAnterior => pagina > 1;
  bool get haySiguiente => pagina * limite < total;
}
