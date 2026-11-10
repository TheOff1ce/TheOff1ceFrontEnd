/// Modelos del servicio de órdenes y autorizaciones.
///
/// El frontend solo presenta lo que informa la EPS a través del backend: vigencia, autorización,
/// reclamación y elegibilidad llegan calculadas (manual §15). Los enums se leen con tolerancia: un
/// valor desconocido pasa a `sinInformacion` (o `desconocido` en los motivos) y nunca lanza.
library;

/// Autorización de un medicamento, según la EPS.
enum Autorizacion {
  autorizado('AUTORIZADO', 'Autorizado'),
  noRequiere('NO_REQUIERE', 'No requiere autorización'),
  porAutorizar('POR_AUTORIZAR', 'Por autorizar'),
  sinInformacion('SIN_INFORMACION', 'Sin información');

  const Autorizacion(this.wire, this.etiqueta);

  final String wire;
  final String etiqueta;

  static Autorizacion parse(Object? value) {
    for (final valor in values) {
      if (valor.wire == value) return valor;
    }
    return sinInformacion;
  }
}

/// Vigencia de una orden. La calcula el backend contra `consultadoEn`.
enum Vigencia {
  vigente('VIGENTE', 'Vigente'),
  vencida('VENCIDA', 'Vencida'),
  sinInformacion('SIN_INFORMACION', 'Sin información');

  const Vigencia(this.wire, this.etiqueta);

  final String wire;
  final String etiqueta;

  static Vigencia parse(Object? value) {
    for (final valor in values) {
      if (valor.wire == value) return valor;
    }
    return sinInformacion;
  }
}

/// Reclamación de un medicamento. No es el estado de un Pendiente.
enum Reclamacion {
  pendienteDeReclamar('PENDIENTE_DE_RECLAMAR', 'Por reclamar'),
  reclamado('RECLAMADO', 'Ya reclamado'),
  sinInformacion('SIN_INFORMACION', 'Reclamación sin información');

  const Reclamacion(this.wire, this.etiqueta);

  final String wire;
  final String etiqueta;

  static Reclamacion parse(Object? value) {
    for (final valor in values) {
      if (valor.wire == value) return valor;
    }
    return sinInformacion;
  }
}

/// Por qué un medicamento no se puede pedir a domicilio.
enum MotivoNoElegible {
  autorizacionPendiente('AUTORIZACION_PENDIENTE'),
  autorizacionSinInformacion('AUTORIZACION_SIN_INFORMACION'),
  yaReclamado('YA_RECLAMADO'),
  reclamacionSinInformacion('RECLAMACION_SIN_INFORMACION'),
  noPerteneceALaOrden('NO_PERTENECE_A_LA_ORDEN'),
  ordenVencida('ORDEN_VENCIDA'),
  ordenSinVencimiento('ORDEN_SIN_VENCIMIENTO'),
  desconocido('');

  const MotivoNoElegible(this.wire);

  final String wire;

  /// Los motivos de orden se muestran una sola vez, en la nota de la orden.
  bool get esDeOrden => this == ordenVencida || this == ordenSinVencimiento;

  static MotivoNoElegible parse(Object? value) {
    for (final valor in values) {
      if (valor.wire.isNotEmpty && valor.wire == value) return valor;
    }
    return desconocido;
  }
}

String _texto(Map<String, dynamic> json, String key, {String alternativa = ''}) {
  final value = json[key];
  if (value is String) return value;
  return alternativa;
}

String _textoRequerido(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
  }
  throw FormatException('Falta "${keys.first}"');
}

DateTime _fecha(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return DateTime.parse(value).toUtc();
  throw FormatException('Falta "$key"');
}

DateTime? _fechaOpcional(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) return DateTime.parse(value).toUtc();
  throw FormatException('"$key" no es una fecha');
}

List<Map<String, dynamic>> _objetos(Object? value, String key) {
  if (value == null) return const [];
  if (value is! List) throw FormatException('"$key" no es una lista');
  return [
    for (final item in value)
      if (item is Map<String, dynamic>) item else throw FormatException('Elemento inválido en "$key"'),
  ];
}

List<MotivoNoElegible> _motivos(Object? value) {
  if (value is! List) return const [];
  return [for (final item in value) MotivoNoElegible.parse(item is Map ? item['codigo'] : item)];
}

/// Un medicamento de una orden, con los estados que informa la EPS.
class MedicamentoOrden {
  const MedicamentoOrden({
    required this.id,
    required this.dci,
    required this.concentracion,
    required this.formaFarmaceutica,
    required this.cantidad,
    required this.unidad,
    required this.laboratorioFabricante,
    required this.autorizacion,
    required this.reclamacion,
    required this.elegibleParaDomicilio,
    required this.motivosNoElegible,
  });

  factory MedicamentoOrden.fromJson(Map<String, dynamic> json) {
    final cantidad = json['cantidad'];
    return MedicamentoOrden(
      id: _textoRequerido(json, const ['medicamentoId', 'id']),
      dci: _texto(json, 'dci'),
      concentracion: _texto(json, 'concentracion'),
      formaFarmaceutica: _texto(json, 'formaFarmaceutica'),
      cantidad: cantidad is num ? cantidad.toInt() : null,
      unidad: _texto(json, 'unidad'),
      laboratorioFabricante: _texto(json, 'laboratorioFabricante'),
      autorizacion: Autorizacion.parse(json['estadoAutorizacion']),
      reclamacion: Reclamacion.parse(json['estadoReclamacion']),
      elegibleParaDomicilio: json['elegibleParaDomicilio'] == true,
      motivosNoElegible: _motivos(json['motivosNoElegible']),
    );
  }

  final String id;
  final String dci;
  final String concentracion;
  final String formaFarmaceutica;
  final int? cantidad;
  final String unidad;
  final String laboratorioFabricante;
  final Autorizacion autorizacion;
  final Reclamacion reclamacion;
  final bool elegibleParaDomicilio;
  final List<MotivoNoElegible> motivosNoElegible;

  /// Refleja un cambio de elegibilidad que informó el backend (no recalcula ninguna regla).
  MedicamentoOrden conElegibilidad({required bool elegible, required List<MotivoNoElegible> motivos}) => MedicamentoOrden(
        id: id,
        dci: dci,
        concentracion: concentracion,
        formaFarmaceutica: formaFarmaceutica,
        cantidad: cantidad,
        unidad: unidad,
        laboratorioFabricante: laboratorioFabricante,
        autorizacion: autorizacion,
        reclamacion: reclamacion,
        elegibleParaDomicilio: elegible,
        motivosNoElegible: motivos,
      );

  /// «Metformina 850 mg»: DCI y concentración.
  String get nombre => [dci, concentracion].where((p) => p.trim().isNotEmpty).join(' ');

  /// «Tableta · 60 unidades · Laboratorio Simulado», sin las partes que la EPS no informó.
  String get detalle {
    final cantidadTexto = cantidad == null
        ? null
        : '$cantidad ${unidad.isEmpty ? (cantidad == 1 ? 'unidad' : 'unidades') : unidad}';
    return [formaFarmaceutica, cantidadTexto, laboratorioFabricante]
        .whereType<String>()
        .where((p) => p.trim().isNotEmpty)
        .join(' · ');
  }
}

/// Una orden de medicamento con su vigencia y sus medicamentos.
class Orden {
  const Orden({
    required this.id,
    required this.fechaOrden,
    required this.vencimiento,
    required this.vigencia,
    required this.permiteDomicilio,
    required this.soloLectura,
    required this.medicamentos,
  });

  factory Orden.fromJson(Map<String, dynamic> json) => Orden(
        id: _textoRequerido(json, const ['ordenId', 'id']),
        fechaOrden: _fecha(json, 'fechaOrden'),
        vencimiento: _fechaOpcional(json, 'vencimiento'),
        vigencia: Vigencia.parse(json['vigencia']),
        permiteDomicilio: json['permiteDomicilio'] == true,
        soloLectura: json['soloLectura'] == true,
        medicamentos: [for (final m in _objetos(json['medicamentos'], 'medicamentos')) MedicamentoOrden.fromJson(m)],
      );

  final String id;
  final DateTime fechaOrden;

  /// `null`: la EPS no informó hasta cuándo se puede reclamar. Sin arco.
  final DateTime? vencimiento;
  final Vigencia vigencia;
  final bool permiteDomicilio;
  final bool soloLectura;
  final List<MedicamentoOrden> medicamentos;

  /// Solo estas órdenes muestran casillas (AC-27 a AC-29, AC-35).
  bool get admiteSeleccion => permiteDomicilio && !soloLectura;

  List<MedicamentoOrden> get elegibles =>
      admiteSeleccion ? [for (final m in medicamentos) if (m.elegibleParaDomicilio) m] : const [];

  bool get tienePorAutorizar => medicamentos.any((m) => m.autorizacion == Autorizacion.porAutorizar);

  Orden copyWith({List<MedicamentoOrden>? medicamentos}) => Orden(
        id: id,
        fechaOrden: fechaOrden,
        vencimiento: vencimiento,
        vigencia: vigencia,
        permiteDomicilio: permiteDomicilio,
        soloLectura: soloLectura,
        medicamentos: medicamentos ?? this.medicamentos,
      );
}

/// Respuesta de `GET /ordenes`: lo que la EPS informó en `consultadoEn`.
class RespuestaOrdenes {
  const RespuestaOrdenes({
    required this.consultadoEn,
    required this.eps,
    required this.documentoEnmascarado,
    required this.ordenes,
  });

  factory RespuestaOrdenes.fromJson(Map<String, dynamic> json) {
    final eps = json['eps'];
    final nombreEps = eps is Map ? eps['nombre'] : eps;
    final afiliacion = json['afiliacion'];
    final documento = json['documentoEnmascarado'] ?? (afiliacion is Map ? afiliacion['documentoEnmascarado'] : null);
    return RespuestaOrdenes(
      consultadoEn: _fecha(json, 'consultadoEn'),
      eps: nombreEps is String && nombreEps.isNotEmpty ? nombreEps : null,
      documentoEnmascarado: documento is String && documento.isNotEmpty ? documento : null,
      ordenes: [for (final o in _objetos(json['ordenes'], 'ordenes')) Orden.fromJson(o)],
    );
  }

  final DateTime consultadoEn;
  final String? eps;
  final String? documentoEnmascarado;
  final List<Orden> ordenes;

  /// Medicamentos que se pueden pedir a domicilio (solo banderas del backend).
  int get totalElegibles => ordenes.fold(0, (suma, o) => suma + o.elegibles.length);

  /// Medicamentos por autorizar en órdenes vigentes.
  int get totalPorAutorizar => ordenes.fold(
        0,
        (suma, o) => o.vigencia != Vigencia.vigente
            ? suma
            : suma + o.medicamentos.where((m) => m.autorizacion == Autorizacion.porAutorizar).length,
      );

  List<Orden> get vigentes => [for (final o in ordenes) if (o.vigencia == Vigencia.vigente) o];

  /// Vencimiento más próximo entre las órdenes vigentes que lo informan.
  DateTime? get proximoVencimiento {
    DateTime? menor;
    for (final orden in vigentes) {
      final v = orden.vencimiento;
      if (v != null && (menor == null || v.isBefore(menor))) menor = v;
    }
    return menor;
  }

  /// Reemplaza una orden en su lugar (sin reordenar), p. ej. tras un 409.
  RespuestaOrdenes reemplazando(Orden nueva) => RespuestaOrdenes(
        consultadoEn: consultadoEn,
        eps: eps,
        documentoEnmascarado: documentoEnmascarado,
        ordenes: [for (final o in ordenes) o.id == nueva.id ? nueva : o],
      );
}

/// Resultado de la verificación de un medicamento antes de enviar.
class VerificacionMedicamento {
  const VerificacionMedicamento({required this.id, required this.elegible, required this.motivos});

  factory VerificacionMedicamento.fromJson(Map<String, dynamic> json) => VerificacionMedicamento(
        id: _textoRequerido(json, const ['medicamentoId', 'id']),
        elegible: json['elegible'] == true,
        motivos: _motivos(json['motivos'] ?? json['motivosNoElegible']),
      );

  final String id;
  final bool elegible;
  final List<MotivoNoElegible> motivos;
}

/// Respuesta de `POST /ordenes/{id}/domicilio/verificacion`.
class VerificacionDomicilio {
  const VerificacionDomicilio({required this.medicamentos});

  factory VerificacionDomicilio.fromJson(Map<String, dynamic> json) => VerificacionDomicilio(
        medicamentos: [
          for (final m in _objetos(json['medicamentos'] ?? json['resultados'], 'medicamentos'))
            VerificacionMedicamento.fromJson(m),
        ],
      );

  final List<VerificacionMedicamento> medicamentos;

  bool get todosElegibles => medicamentos.isNotEmpty && medicamentos.every((m) => m.elegible);
}

/// Respuesta 202 de `POST /ordenes/{id}/domicilio`. La referencia se muestra tal cual.
class DomicilioAceptado {
  const DomicilioAceptado({required this.referencia});

  factory DomicilioAceptado.fromJson(Map<String, dynamic> json) =>
      DomicilioAceptado(referencia: _textoRequerido(json, const ['referencia']));

  final String referencia;
}

/// Un medicamento que la EPS cambió mientras el paciente elegía (409 `ELEGIBILIDAD_CAMBIADA`).
class CambioElegibilidad {
  const CambioElegibilidad({required this.id, required this.motivos});

  factory CambioElegibilidad.fromJson(Map<String, dynamic> json) => CambioElegibilidad(
        id: _textoRequerido(json, const ['medicamentoId', 'id']),
        motivos: _motivos(json['motivos'] ?? json['motivosNoElegible']),
      );

  final String id;
  final List<MotivoNoElegible> motivos;

  /// Lee `detalles.cambios` de un 409; ignora entradas mal formadas.
  static List<CambioElegibilidad> listaDe(Map<String, dynamic>? detalles) {
    final cambios = detalles?['cambios'];
    if (cambios is! List) return const [];
    return [
      for (final c in cambios)
        if (c is Map<String, dynamic> && (c['medicamentoId'] ?? c['id']) is String) CambioElegibilidad.fromJson(c),
    ];
  }

  /// Lee `detalles.orden` de un 409 o `null` si falta o está mal formada.
  static Orden? ordenDe(Map<String, dynamic>? detalles) {
    final orden = detalles?['orden'];
    if (orden is! Map<String, dynamic>) return null;
    try {
      return Orden.fromJson(orden);
    } on FormatException {
      return null;
    }
  }
}
