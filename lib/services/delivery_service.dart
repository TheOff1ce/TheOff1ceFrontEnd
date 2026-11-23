import 'dart:typed_data';

import '../errors/error_mapper.dart';
import '../types/calificaciones.dart';
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

  /// El paciente confirma que recibió el pedido con el código que le dio el repartidor.
  Future<Delivery> confirm(String deliveryId, String code) async =>
      _parse(await _client.post('/deliveries/${_id(deliveryId)}/confirm', {'code': code}));

  /// El paciente califica la entrega una sola vez (1 a 5 estrellas y un comentario opcional).
  Future<Delivery> rate(String deliveryId, int stars, {String? comment}) async {
    final text = comment?.trim() ?? '';
    return _parse(await _client.post('/deliveries/${_id(deliveryId)}/rating', {
      'stars': stars,
      if (text.isNotEmpty) 'comment': text,
    }));
  }

  /// Administradores: promedio por repartidor y calificaciones malas de los últimos [days] días.
  Future<ReporteCalificaciones> ratingsReport({int days = 30}) async {
    final json = await _client.get('/deliveries/ratings?days=$days');
    try {
      return ReporteCalificaciones.fromJson(json);
    } on TypeError catch (error) {
      throw ErrorMapper.fromException(FormatException('Unexpected ratings payload: $error'));
    }
  }

  Future<LocationReport> reportLocation(String deliveryId, GpsFix fix) async {
    final json = await _client.post('/deliveries/${_id(deliveryId)}/locations', fix.toJson());
    return LocationReport(
      accepted: json['accepted'] == true,
      reason: json['reason']?.toString(),
      status: DeliveryStatus.fromCode(json['status']),
    );
  }

  /// CU-14: el repartidor cierra la entrega con la foto, la firma (PNG) y su ubicación en la
  /// puerta. El servidor exige estar cerca de la dirección y una ubicación reciente y precisa.
  Future<Delivery> registerProof(
    String deliveryId, {
    required Uint8List photo,
    required String photoContentType,
    required Uint8List signaturePng,
    required GpsFix fix,
    String? receiverName,
  }) async {
    final name = receiverName?.trim() ?? '';
    final extension = switch (photoContentType) { 'image/png' => 'png', 'image/webp' => 'webp', _ => 'jpg' };
    return _parse(await _client.postMultipart(
      '/deliveries/${_id(deliveryId)}/proof',
      fields: {
        'lat': '${fix.point.lat}',
        'lng': '${fix.point.lng}',
        'accuracy': '${fix.accuracy}',
        'recordedAt': fix.recordedAt.toUtc().toIso8601String(),
        if (name.isNotEmpty) 'receiverName': name,
      },
      files: [
        MultipartFilePart(field: 'photo', bytes: photo, filename: 'entrega.$extension', contentType: photoContentType),
        MultipartFilePart(field: 'signature', bytes: signaturePng, filename: 'firma.png', contentType: 'image/png'),
      ],
    ));
  }

  /// La foto o la firma de la prueba de entrega (paciente dueño, repartidor asignado o admin).
  Future<Uint8List> proofImage(String deliveryId, DeliveryProofImage image) =>
      _client.getBytes('/deliveries/${_id(deliveryId)}/proof/${image.path}');

  static String _id(String id) => Uri.encodeComponent(id);

  static Delivery _parse(Map<String, dynamic> json) {
    try {
      return Delivery.fromJson(json);
    } on TypeError catch (error) {
      throw ErrorMapper.fromException(FormatException('Unexpected delivery payload: $error'));
    }
  }
}
