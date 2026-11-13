/// Reporte de calificaciones para administradores (`GET /deliveries/ratings`).
///
/// Los promedios y conteos los calcula Geolocation; aquí solo se leen.
class ReporteCalificaciones {
  const ReporteCalificaciones({
    required this.dias,
    required this.total,
    required this.promedio,
    required this.distribucion,
    required this.repartidores,
    required this.malas,
    required this.truncado,
  });

  final int dias, total;

  /// `null` si nadie calificó en la ventana.
  final double? promedio;

  /// Cantidad de calificaciones de 1 a 5 estrellas (índice 0 = 1 estrella).
  final List<int> distribucion;

  /// Peor promedio primero.
  final List<CalificacionRepartidor> repartidores;

  /// Calificaciones de 1 o 2 estrellas, la más reciente primero, con su comentario.
  final List<CalificacionMala> malas;
  final bool truncado;

  factory ReporteCalificaciones.fromJson(Map<String, dynamic> json) {
    final dist = json['distribution'] is Map ? json['distribution'] as Map : const {};
    return ReporteCalificaciones(
      dias: _int(json['days']),
      total: _int(json['count']),
      promedio: (json['average'] as num?)?.toDouble(),
      distribucion: [for (var i = 1; i <= 5; i++) _int(dist['$i'])],
      repartidores: [
        for (final item in _list(json['drivers']))
          if (item is Map<String, dynamic>) CalificacionRepartidor.fromJson(item),
      ],
      malas: [
        for (final item in _list(json['lowRatings']))
          if (item is Map<String, dynamic>) CalificacionMala.fromJson(item),
      ],
      truncado: json['truncated'] == true,
    );
  }
}

class CalificacionRepartidor {
  const CalificacionRepartidor({
    required this.repartidorId,
    required this.cantidad,
    required this.promedio,
    required this.malas,
    this.ultima,
  });

  final String repartidorId;
  final int cantidad, malas;
  final double promedio;
  final DateTime? ultima;

  factory CalificacionRepartidor.fromJson(Map<String, dynamic> json) => CalificacionRepartidor(
        repartidorId: json['driverId']?.toString() ?? '',
        cantidad: _int(json['count']),
        promedio: (json['average'] as num?)?.toDouble() ?? 0,
        malas: _int(json['low']),
        ultima: DateTime.tryParse(json['lastRatedAt']?.toString() ?? ''),
      );
}

class CalificacionMala {
  const CalificacionMala({
    required this.entregaId,
    required this.pedidoId,
    required this.repartidorId,
    required this.estrellas,
    required this.comentario,
    required this.fecha,
  });

  final String entregaId, pedidoId;
  final String? repartidorId, comentario;
  final int estrellas;
  final DateTime? fecha;

  factory CalificacionMala.fromJson(Map<String, dynamic> json) => CalificacionMala(
        entregaId: json['deliveryId']?.toString() ?? '',
        pedidoId: json['orderId']?.toString() ?? '',
        repartidorId: json['driverId']?.toString(),
        estrellas: _int(json['stars']),
        comentario: switch (json['comment']) { final String c when c.trim().isNotEmpty => c.trim(), _ => null },
        fecha: DateTime.tryParse(json['ratedAt']?.toString() ?? ''),
      );
}

int _int(Object? value) => (value as num?)?.toInt() ?? 0;
List<Object?> _list(Object? value) => value is List ? value : const [];
