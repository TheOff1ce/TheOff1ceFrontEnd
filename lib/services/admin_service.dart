import '../errors/error_mapper.dart';
import '../types/admin.dart';
import 'authorized_json_client.dart';

/// Administrator back-office: user directory in TheOff1ceAuth and every order in OrderDelivery.
class AdminService {
  AdminService({required AuthorizedJsonClient auth, required AuthorizedJsonClient orders})
      : _auth = auth,
        _orders = orders;

  final AuthorizedJsonClient _auth;
  final AuthorizedJsonClient _orders;

  Future<UserPage> users({String search = '', UserRole? role, int page = 1}) async {
    final query = Uri(queryParameters: {
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (role != null) 'role': role.code,
      'page': '$page',
    }).query;
    return _parse(await _auth.get('/admin/users?$query'), UserPage.fromJson);
  }

  /// Changes the role and signs that user out everywhere (Auth revokes their sessions).
  Future<AdminUser> changeRole(String userId, UserRole role) async => _parse(
        await _auth.patch('/admin/users/${Uri.encodeComponent(userId)}/role', {'role': role.code}),
        AdminUser.fromJson,
      );

  Future<List<AdminOrder>> orders(AdminOrderFilter filter) async {
    final json = await _orders.get('/orders/admin?status=${filter.code}');
    final raw = json['orders'];
    if (raw is! List) throw ErrorMapper.fromException(const FormatException('Expected an orders list'));
    return [for (final item in raw) if (item is Map<String, dynamic>) _parse(item, AdminOrder.fromJson)];
  }

  /// Cancels any order (Orders also cancels its delivery in Geolocation).
  Future<void> cancelOrder(String orderId) => _orders.post('/orders/${Uri.encodeComponent(orderId)}/cancel');

  static T _parse<T>(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    try {
      return fromJson(json);
    } on TypeError catch (error) {
      throw ErrorMapper.fromException(FormatException('Unexpected admin payload: $error'));
    } on FormatException catch (error) {
      throw ErrorMapper.fromException(error);
    }
  }
}
