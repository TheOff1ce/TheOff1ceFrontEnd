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
  });

  final String id, orderId;
  final DeliveryStatus status;
  final DeliveryPlace origin, destination;
  final DeliveryRoute route;
  final DateTime? eta;
  final bool driverAssigned;
  final DriverLocation? driverLocation;
  final int? distanceToDestinationMeters;

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
      );

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
      );
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? value.map((key, v) => MapEntry(key.toString(), v)) : <String, dynamic>{};
