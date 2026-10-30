import 'package:flutter/foundation.dart';

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../services/delivery_service.dart';
import '../services/order_service.dart';
import '../types/delivery.dart';
import '../types/order.dart';

/// Driver side: orders waiting for a driver and the ones this driver took.
class DriverBoardController extends ChangeNotifier {
  DriverBoardController(this._orders, [this._deliveries]);

  final OrderService _orders;
  final DeliveryService? _deliveries;

  /// Live delivery status by `deliveryId` (from Geolocation), when available.
  Map<String, DeliveryStatus> deliveryStatuses = const {};

  /// Taken orders whose delivery is still in progress (finished ones are hidden).
  List<DriverOrder> get active => [
        for (final order in taken)
          if (order.status == OrderStatus.taken && !(deliveryStatuses[order.deliveryId]?.isFinished ?? false)) order,
      ];

  List<AvailableOrder> available = const [];
  List<DriverOrder> taken = const [];
  bool loading = false;
  String? takingId;
  AppError? error;
  bool _disposed = false;

  Future<void> load() async {
    loading = true;
    error = null;
    _notify();
    try {
      final (board, mine, statuses) = await (_orders.available(), _orders.taken(), _statuses()).wait;
      available = board;
      taken = mine;
      deliveryStatuses = statuses;
    } catch (e) {
      error = ErrorMapper.fromException(e);
    } finally {
      loading = false;
      _notify();
    }
  }

  /// Takes an order; on a lost race (409) the board is reloaded so it disappears.
  Future<(DriverOrder?, AppError?)> take(String orderId) async {
    takingId = orderId;
    _notify();
    try {
      final order = await _orders.take(orderId);
      available = [for (final o in available) if (o.id != orderId) o];
      taken = [order, ...taken];
      return (order, null);
    } catch (e) {
      final failure = ErrorMapper.fromException(e);
      if (failure.kind == AppErrorKind.conflict) await load();
      return (null, failure);
    } finally {
      takingId = null;
      _notify();
    }
  }

  /// The board still works if Geolocation does not answer: statuses are optional.
  Future<Map<String, DeliveryStatus>> _statuses() async {
    final service = _deliveries;
    if (service == null) return const {};
    try {
      return {for (final d in await service.listMine()) d.id: d.status};
    } catch (_) {
      return const {};
    }
  }

  DriverOrder? takenById(String orderId) {
    for (final order in taken) {
      if (order.id == orderId) return order;
    }
    return null;
  }

  void clear() {
    available = const [];
    taken = const [];
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
