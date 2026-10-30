import 'package:flutter/foundation.dart';

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../services/delivery_service.dart';
import '../services/order_service.dart';
import '../types/delivery.dart';
import '../types/order.dart';

/// Patient side: home-delivery requests and their list.
class PatientOrdersController extends ChangeNotifier {
  PatientOrdersController(this._orders, [this._deliveries]);

  final OrderService _orders;
  final DeliveryService? _deliveries;

  List<PatientOrder> orders = const [];

  /// Live delivery status by `deliveryId` (from Geolocation), when available.
  Map<String, DeliveryStatus> deliveryStatuses = const {};
  bool loading = false;
  bool submitting = false;
  AppError? error;
  bool _disposed = false;

  Future<void> load() async {
    loading = true;
    error = null;
    _notify();
    try {
      final (mine, statuses) = await (_orders.myOrders(), _statuses()).wait;
      orders = mine;
      deliveryStatuses = statuses;
    } catch (e) {
      error = ErrorMapper.fromException(e);
    } finally {
      loading = false;
      _notify();
    }
  }

  DeliveryStatus? deliveryStatusOf(PatientOrder order) => deliveryStatuses[order.deliveryId];

  /// The patient may cancel while no driver has picked the order up.
  bool canCancel(PatientOrder order) {
    final status = deliveryStatusOf(order);
    return order.status.cancellable &&
        (status == null || status == DeliveryStatus.created || status == DeliveryStatus.assigned);
  }

  /// The order list still works if Geolocation does not answer: statuses are optional.
  Future<Map<String, DeliveryStatus>> _statuses() async {
    final service = _deliveries;
    if (service == null) return const {};
    try {
      return {for (final d in await service.listMine()) d.id: d.status};
    } catch (_) {
      return const {};
    }
  }

  /// Returns the created order, or `null` with [error] set.
  Future<PatientOrder?> publish(DeliveryRequest request) async {
    submitting = true;
    error = null;
    _notify();
    try {
      final order = await _orders.publish(request);
      orders = [order, ...orders];
      return order;
    } catch (e) {
      error = ErrorMapper.fromException(e);
      return null;
    } finally {
      submitting = false;
      _notify();
    }
  }

  Future<AppError?> cancel(String orderId) async {
    try {
      final updated = await _orders.cancel(orderId);
      orders = [for (final o in orders) o.id == orderId ? updated : o];
      _notify();
      return null;
    } catch (e) {
      return ErrorMapper.fromException(e);
    }
  }

  /// Forgets everything when the session changes.
  void clear() {
    orders = const [];
    deliveryStatuses = const {};
    error = null;
    _notify();
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
