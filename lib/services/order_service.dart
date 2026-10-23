import '../errors/error_mapper.dart';
import '../types/order.dart';
import 'authorized_json_client.dart';

/// TheOff1ceOrderDelivery: patients request home deliveries, drivers take them.
class OrderService {
  OrderService(this._client);

  final AuthorizedJsonClient _client;

  Future<PatientOrder> publish(DeliveryRequest request) async =>
      _parse(await _client.post('/orders', request.toJson()), PatientOrder.fromJson);

  Future<List<PatientOrder>> myOrders() async => _list(await _client.get('/orders/mine'), PatientOrder.fromJson);

  Future<PatientOrder> cancel(String orderId) async =>
      _parse(await _client.post('/orders/${Uri.encodeComponent(orderId)}/cancel'), PatientOrder.fromJson);

  Future<List<AvailableOrder>> available() async =>
      _list(await _client.get('/orders/available'), AvailableOrder.fromJson);

  Future<List<DriverOrder>> taken() async => _list(await _client.get('/orders/taken'), DriverOrder.fromJson);

  Future<DriverOrder> take(String orderId) async =>
      _parse(await _client.post('/orders/${Uri.encodeComponent(orderId)}/take'), DriverOrder.fromJson);

  static T _parse<T>(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    try {
      return fromJson(json);
    } on TypeError catch (error) {
      throw ErrorMapper.fromException(FormatException('Unexpected order payload: $error'));
    }
  }

  static List<T> _list<T>(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    final orders = json['orders'];
    if (orders is! List) throw ErrorMapper.fromException(const FormatException('Expected an orders list'));
    return [for (final item in orders) if (item is Map<String, dynamic>) _parse(item, fromJson)];
  }
}
