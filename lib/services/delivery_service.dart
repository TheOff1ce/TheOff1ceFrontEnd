import '../errors/error_mapper.dart';
import '../types/delivery.dart';
import 'authorized_json_client.dart';

/// A GPS sample from the driver's device.
class GpsFix {
  const GpsFix({required this.point, required this.accuracy, required this.recordedAt, this.heading, this.speed});

  final GeoPoint point;
  final double accuracy;
  final DateTime recordedAt;
  final double? heading, speed;

  Map<String, dynamic> toJson() => {
        'lat': point.lat,
        'lng': point.lng,
        'accuracy': accuracy,
        if (heading != null && heading! >= 0 && heading! <= 360) 'heading': heading,
        if (speed != null && speed! >= 0 && speed! <= 100) 'speed': speed,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
      };
}

/// Result of `POST /deliveries/:id/locations`.
class LocationReport {
  const LocationReport({required this.accepted, required this.status, this.reason});

  final bool accepted;
  final String? reason;
  final DeliveryStatus status;
}

/// TheOff1ceGeolocation: delivery detail, driver status changes and GPS reports.
class DeliveryService {
  DeliveryService(this._client);

  final AuthorizedJsonClient _client;

  /// Deliveries of the caller (patient: their own; driver: the ones assigned to them).
  Future<List<Delivery>> listMine() async {
    final json = await _client.get('/deliveries');
    final items = json['deliveries'];
    if (items is! List) throw ErrorMapper.fromException(const FormatException('Expected a deliveries list'));
    return [for (final item in items) if (item is Map<String, dynamic>) _parse(item)];
  }

  Future<Delivery> get(String deliveryId) async => _parse(await _client.get('/deliveries/${_id(deliveryId)}'));

  Future<Delivery> changeStatus(String deliveryId, DeliveryStatus status) async =>
      _parse(await _client.patch('/deliveries/${_id(deliveryId)}/status', {'status': status.code}));

  Future<LocationReport> reportLocation(String deliveryId, GpsFix fix) async {
    final json = await _client.post('/deliveries/${_id(deliveryId)}/locations', fix.toJson());
    return LocationReport(
      accepted: json['accepted'] == true,
      reason: json['reason']?.toString(),
      status: DeliveryStatus.fromCode(json['status']),
    );
  }

  static String _id(String id) => Uri.encodeComponent(id);

  static Delivery _parse(Map<String, dynamic> json) {
    try {
      return Delivery.fromJson(json);
    } on TypeError catch (error) {
      throw ErrorMapper.fromException(FormatException('Unexpected delivery payload: $error'));
    }
  }
}
