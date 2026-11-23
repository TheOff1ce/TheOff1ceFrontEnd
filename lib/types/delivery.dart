/// Models returned by TheOff1ceGeolocation (`DeliveryView` and realtime events).
library;

class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat, lng;

  factory GeoPoint.fromJson(Map<String, dynamic> json) =>
      GeoPoint((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble());

  @override
  bool operator ==(Object other) => other is GeoPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'GeoPoint($lat, $lng)';
}

/// Lifecycle states, in the order the patient sees them.
enum DeliveryStatus {
  created('CREATED', 'Buscando repartidor'),
  assigned('ASSIGNED', 'Repartidor asignado'),
  pickedUp('PICKED_UP', 'Pedido recogido'),
  inTransit('IN_TRANSIT', 'En camino'),
  arriving('ARRIVING', 'Llegando'),
  delivered('DELIVERED', 'Entregado'),
  cancelled('CANCELLED', 'Cancelado'),
  failed('FAILED', 'No se pudo entregar'),
  unknown('UNKNOWN', 'Estado desconocido');

  const DeliveryStatus(this.code, this.label);

  final String code, label;

  static DeliveryStatus fromCode(Object? code) =>
      values.firstWhere((s) => s.code == code, orElse: () => DeliveryStatus.unknown);

  /// The driver's location is shared only in these states.
  bool get isTracking => this == pickedUp || this == inTransit || this == arriving;

  bool get isFinished => this == delivered || this == cancelled || this == failed;

  /// Qué pasa ahora y qué sigue, dicho al paciente (visibilidad del estado).
  String get patientHint => switch (this) {
        created => 'Estamos buscando un repartidor. Te avisamos cuando alguien tome tu pedido.',
        assigned => 'Un repartidor va a la farmacia por tu pedido.',
        pickedUp => 'El repartidor ya tiene tu pedido y está por salir.',
        inTransit =>
          'Tu pedido va en camino. Al recibirlo, el repartidor te pedirá firmar en su celular, o te dará un código para confirmarlo aquí.',
        arriving => 'El repartidor está llegando. Al recibir, firma en su celular o escribe aquí el código que te dé.',
        delivered => 'Recibiste este pedido.',
        cancelled => 'Este pedido se canceló.',
        failed => 'El repartidor no pudo entregarlo. Puedes pedirlo de nuevo.',
        unknown => 'No pudimos leer el estado. Actualiza para intentarlo de nuevo.',
      };

  /// Qué debe hacer ahora el repartidor.
  String get driverHint => switch (this) {
        assigned => 'Ve a la farmacia y recoge el pedido.',
        pickedUp => 'Cuando salgas hacia la dirección de entrega, empieza el viaje.',
        inTransit || arriving =>
          'Al entregar, toca «Registrar entrega»: una foto, la firma de quien recibe y tu ubicación. O dile tu código al paciente.',
        delivered => 'Entrega terminada. ¡Buen trabajo!',
        failed => 'Marcaste que no se pudo entregar.',
        cancelled => 'El paciente canceló este pedido.',
        _ => '',
      };

  /// Main steps of the progress indicator (terminal failures are shown apart).
  static const steps = [created, assigned, pickedUp, inTransit, arriving, delivered];
}

class DeliveryPlace {
  const DeliveryPlace({required this.address, required this.point});

  final String address;
  final GeoPoint point;

  factory DeliveryPlace.fromJson(Map<String, dynamic> json) =>
      DeliveryPlace(address: json['address']?.toString() ?? '', point: GeoPoint.fromJson(json));
}

class DeliveryRoute {
  const DeliveryRoute({required this.encodedPolyline, required this.distanceMeters, required this.durationSeconds});

  final String encodedPolyline;
  final int distanceMeters, durationSeconds;

  factory DeliveryRoute.fromJson(Map<String, dynamic> json) => DeliveryRoute(
        encodedPolyline: json['encodedPolyline']?.toString() ?? '',
        distanceMeters: (json['distanceMeters'] as num?)?.round() ?? 0,
        durationSeconds: (json['durationSeconds'] as num?)?.round() ?? 0,
      );
}

class DriverLocation {
  const DriverLocation({required this.point, required this.recordedAt, this.heading, this.speed});

  final GeoPoint point;
  final DateTime recordedAt;
  final double? heading, speed;

  factory DriverLocation.fromJson(Map<String, dynamic> json) => DriverLocation(
        point: GeoPoint.fromJson(json),
        recordedAt: DateTime.tryParse(json['recordedAt']?.toString() ?? '') ?? DateTime.now(),
        heading: (json['heading'] as num?)?.toDouble(),
        speed: (json['speed'] as num?)?.toDouble(),
      );
}

/// Calificación que el paciente dejó al recibir (el comentario no vuelve del servidor).
class DeliveryRating {
  const DeliveryRating({required this.stars, this.ratedAt});

  final int stars;
  final DateTime? ratedAt;

  static DeliveryRating? fromJson(Object? json) {
    if (json is! Map) return null;
    final stars = (json['stars'] as num?)?.toInt();
    if (stars == null || stars < 1 || stars > 5) return null;
    return DeliveryRating(stars: stars, ratedAt: DateTime.tryParse(json['ratedAt']?.toString() ?? ''));
  }
}

/// Prueba de entrega que registró el repartidor (CU-14): foto, firma y ubicación en la puerta.
/// Las imágenes se piden aparte con `DeliveryService.proofImage`.
class DeliveryProof {
  const DeliveryProof({
    required this.recordedAt,
    required this.location,
    required this.accuracyMeters,
    required this.distanceToDestinationMeters,
    this.receiverName,
  });

  final DateTime recordedAt;
  final GeoPoint location;
  final double accuracyMeters;
  final int distanceToDestinationMeters;

  /// Quién recibió el pedido, si el repartidor lo anotó.
  final String? receiverName;

  static DeliveryProof? fromJson(Object? json) {
    if (json is! Map) return null;
    final location = json['location'];
    final at = DateTime.tryParse(json['recordedAt']?.toString() ?? '');
    if (location is! Map || at == null) return null;
    final name = json['receiverName']?.toString().trim() ?? '';
    return DeliveryProof(
      recordedAt: at,
      location: GeoPoint.fromJson(_map(location)),
      accuracyMeters: (location['accuracy'] as num?)?.toDouble() ?? 0,
      distanceToDestinationMeters: (json['distanceToDestinationMeters'] as num?)?.round() ?? 0,
      receiverName: name.isEmpty ? null : name,
    );
  }
}

/// Qué imagen de la prueba de entrega se pide.
enum DeliveryProofImage {
  photo('photo'),
  signature('signature');

  const DeliveryProofImage(this.path);

  final String path;
}

class Delivery {
  const Delivery({
    required this.id,
    required this.orderId,
    required this.status,
    required this.origin,
    required this.destination,
    required this.route,
    required this.eta,
    required this.driverAssigned,
    required this.driverLocation,
    required this.distanceToDestinationMeters,
    this.deliveryCode,
    this.rating,
    this.proof,
    this.deliveredAt,
    this.statusTimes = const {},
  });

  final String id, orderId;
  final DeliveryStatus status;
  final DeliveryPlace origin, destination;
  final DeliveryRoute route;
  final DateTime? eta;
  final bool driverAssigned;
  final DriverLocation? driverLocation;
  final int? distanceToDestinationMeters;

  /// Código de 6 dígitos que el repartidor le dice al paciente al entregar. Solo llega en las
  /// respuestas del repartidor asignado, mientras el envío está abierto; el paciente nunca lo ve.
  final String? deliveryCode;

  /// `null` mientras el paciente no haya calificado.
  final DeliveryRating? rating;

  /// Prueba de entrega del repartidor (CU-14); `null` si se cerró con el código o sigue abierto.
  final DeliveryProof? proof;

  /// Cuándo se confirmó la entrega (`statusTimestamps.DELIVERED`).
  final DateTime? deliveredAt;

  /// Cuándo entró a cada estado (`statusTimestamps`), p. ej. desde cuándo espera repartidor.
  final Map<DeliveryStatus, DateTime> statusTimes;

  /// Cuándo pasó al estado en que está ahora.
  DateTime? get since => statusTimes[status];

  /// Ya entregado y sin calificar: el paciente puede dejar sus estrellas.
  bool get canBeRated => status == DeliveryStatus.delivered && rating == null;

  /// El paciente cierra la entrega escribiendo el código (solo en camino o llegando).
  bool get awaitsCode => status == DeliveryStatus.inTransit || status == DeliveryStatus.arriving;

  /// El repartidor puede cerrar la entrega con foto, firma y ubicación (mismos estados que el código).
  bool get acceptsProof => awaitsCode;

  factory Delivery.fromJson(Map<String, dynamic> json) => Delivery(
        id: json['id']?.toString() ?? '',
        orderId: json['orderId']?.toString() ?? '',
        status: DeliveryStatus.fromCode(json['status']),
        origin: DeliveryPlace.fromJson(_map(json['origin'])),
        destination: DeliveryPlace.fromJson(_map(json['destination'])),
        route: DeliveryRoute.fromJson(_map(json['route'])),
        eta: DateTime.tryParse(json['eta']?.toString() ?? ''),
        driverAssigned: json['driverAssigned'] == true,
        driverLocation: json['driverLocation'] is Map ? DriverLocation.fromJson(_map(json['driverLocation'])) : null,
        distanceToDestinationMeters: (json['distanceToDestinationMeters'] as num?)?.round(),
        deliveryCode: switch (json['deliveryCode']) { final String code when code.isNotEmpty => code, _ => null },
        rating: DeliveryRating.fromJson(json['rating']),
        proof: DeliveryProof.fromJson(json['proof']),
        deliveredAt: json['statusTimestamps'] is Map
            ? DateTime.tryParse((json['statusTimestamps'] as Map)['DELIVERED']?.toString() ?? '')
            : null,
        statusTimes: _times(json['statusTimestamps']),
      );

  static Map<DeliveryStatus, DateTime> _times(Object? raw) {
    if (raw is! Map) return const {};
    final out = <DeliveryStatus, DateTime>{};
    raw.forEach((key, value) {
      final status = DeliveryStatus.fromCode(key);
      final at = DateTime.tryParse(value?.toString() ?? '');
      if (status != DeliveryStatus.unknown && at != null) out[status] = at;
    });
    return out;
  }

  /// Applies a `delivery.location` event.
  Delivery withLocation(Map<String, dynamic> event) => _copy(
        driverLocation: event['driverLocation'] is Map ? DriverLocation.fromJson(_map(event['driverLocation'])) : null,
        eta: DateTime.tryParse(event['eta']?.toString() ?? '') ?? eta,
        distance: (event['distanceToDestinationMeters'] as num?)?.round(),
      );

  /// Applies a `delivery.route` event.
  Delivery withRoute(Map<String, dynamic> event) => _copy(
        route: event['route'] is Map ? DeliveryRoute.fromJson(_map(event['route'])) : route,
        eta: DateTime.tryParse(event['eta']?.toString() ?? '') ?? eta,
        driverLocation: driverLocation,
        distance: distanceToDestinationMeters,
      );

  Delivery _copy({DeliveryRoute? route, DateTime? eta, DriverLocation? driverLocation, int? distance}) => Delivery(
        id: id,
        orderId: orderId,
        status: status,
        origin: origin,
        destination: destination,
        route: route ?? this.route,
        eta: eta ?? this.eta,
        driverAssigned: driverAssigned,
        driverLocation: driverLocation,
        distanceToDestinationMeters: distance,
        deliveryCode: deliveryCode,
        rating: rating,
        proof: proof,
        deliveredAt: deliveredAt,
        statusTimes: statusTimes,
      );
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? value.map((key, v) => MapEntry(key.toString(), v)) : <String, dynamic>{};
