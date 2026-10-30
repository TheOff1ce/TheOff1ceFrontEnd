import 'dart:async';

import 'package:flutter/foundation.dart';

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../services/delivery_service.dart';
import '../services/tracking_channel.dart';
import '../types/delivery.dart';

/// Live view of one delivery for the patient: first a REST snapshot, then realtime events.
class TrackingController extends ChangeNotifier {
  TrackingController({required this.deliveryId, required DeliveryService deliveries, required TrackingChannel channel})
      : _deliveries = deliveries,
        _channel = channel;

  final String deliveryId;
  final DeliveryService _deliveries;
  final TrackingChannel _channel;
  StreamSubscription<TrackingEvent>? _subscription;

  Delivery? delivery;
  AppError? error;
  bool connected = false;
  bool loading = true;
  bool _disposed = false;

  Future<void> start() async {
    loading = true;
    error = null;
    _notify();
    try {
      delivery = await _deliveries.get(deliveryId);
    } catch (e) {
      error = ErrorMapper.fromException(e);
    } finally {
      loading = false;
      _notify();
    }
    if (delivery == null || delivery!.status.isFinished) return;
    _subscription ??= _channel.events.listen(_apply);
    _channel.watch(deliveryId);
  }

  void _apply(TrackingEvent event) {
    final current = delivery;
    switch (event) {
      case DeliverySnapshot(:final delivery):
        this.delivery = delivery;
      case LocationChanged(:final payload):
        if (current != null) delivery = current.withLocation(payload);
      case RouteChanged(:final payload):
        if (current != null) delivery = current.withRoute(payload);
      case TrackingEnded():
        _channel.close();
        connected = false;
      case ConnectionChanged(:final connected, :final errorCode):
        this.connected = connected && errorCode == null;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    _channel.close();
    super.dispose();
  }
}
