import 'package:flutter/foundation.dart';

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../services/admin_service.dart';
import '../services/delivery_service.dart';
import '../types/admin.dart';
import '../types/delivery.dart';

/// Every order for administrators, pending ones first by default, with live delivery status.
class AdminOrdersController extends ChangeNotifier {
  AdminOrdersController(this._admin, [this._deliveries]);

  final AdminService _admin;
  final DeliveryService? _deliveries;

  List<AdminOrder> orders = const [];
  Map<String, DeliveryStatus> deliveryStatuses = const {};
  AdminOrderFilter filter = AdminOrderFilter.pending;
  bool loading = false;
  AppError? error;
  int _generation = 0;
  bool _disposed = false;

  Future<void> load() async {
    final generation = ++_generation;
    loading = true;
    error = null;
    _notify();
    try {
      final pendingStatuses = _statuses(); // never throws; runs in parallel with the list
      final list = await _admin.orders(filter);
      final statuses = await pendingStatuses;
      if (generation != _generation) return;
      orders = list;
      deliveryStatuses = statuses;
    } catch (e) {
      if (generation == _generation) error = ErrorMapper.fromException(e);
    } finally {
      if (generation == _generation) {
        loading = false;
        _notify();
      }
    }
  }

  void setFilter(AdminOrderFilter value) {
    if (value == filter) return;
    filter = value;
    load();
  }

  DeliveryStatus? deliveryStatusOf(AdminOrder order) => deliveryStatuses[order.order.deliveryId];

  /// Administrators can cancel until the delivery ends.
  bool canCancel(AdminOrder order) {
    final status = deliveryStatusOf(order);
    return order.order.status.cancellable && (status == null || !status.isFinished);
  }

  Future<AppError?> cancel(AdminOrder order) async {
    try {
      await _admin.cancelOrder(order.id);
      await load();
      return null;
    } catch (e) {
      return ErrorMapper.fromException(e);
    }
  }

  /// Geolocation lists every delivery for an administrator; the list still works without it.
  Future<Map<String, DeliveryStatus>> _statuses() async {
    final service = _deliveries;
    if (service == null) return const {};
    try {
      return {for (final d in await service.listMine()) d.id: d.status};
    } catch (_) {
      return const {};
    }
  }

  void clear() {
    _generation++;
    orders = const [];
    deliveryStatuses = const {};
    filter = AdminOrderFilter.pending;
    error = null;
    loading = false;
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
