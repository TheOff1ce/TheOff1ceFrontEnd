import 'dart:async';

import 'package:flutter/foundation.dart';

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../services/delivery_service.dart';
import '../services/location_source.dart';
import '../types/delivery.dart';

/// Driver side of one delivery: status buttons and periodic location sharing.
///
/// The location is sent every [interval] only while the delivery is PICKED_UP, IN_TRANSIT or
/// ARRIVING, and sharing stops as soon as it is delivered (or fails).
class DriverDeliveryController extends ChangeNotifier {
  DriverDeliveryController({
    required this.deliveryId,
    required DeliveryService deliveries,
    required LocationSource location,
    this.interval = const Duration(seconds: 10),
  })  : _deliveries = deliveries,
        _location = location;

  final String deliveryId;
  final Duration interval;
  final DeliveryService _deliveries;
  final LocationSource _location;
  Timer? _timer;
  bool _sending = false;
  bool _disposed = false;

  Delivery? delivery;
  AppError? error;

  /// Last problem while sharing the location (permission, GPS, network).
  AppError? locationError;
  bool loading = true;
  bool updating = false;
  DateTime? lastSentAt;

  bool get sharing => _timer != null;

  /// Next status the driver can move to, as a primary action.
  DeliveryStatus? get nextStep => switch (delivery?.status) {
        DeliveryStatus.assigned => DeliveryStatus.pickedUp,
        DeliveryStatus.pickedUp => DeliveryStatus.inTransit,
        DeliveryStatus.inTransit || DeliveryStatus.arriving => DeliveryStatus.delivered,
        _ => null,
      };

  bool get canFail => switch (delivery?.status) {
        DeliveryStatus.assigned || DeliveryStatus.pickedUp || DeliveryStatus.inTransit || DeliveryStatus.arriving => true,
        _ => false,
      };

  Future<void> start() async {
    loading = true;
    _notify();
    try {
      delivery = await _deliveries.get(deliveryId);
      error = null;
    } catch (e) {
      error = ErrorMapper.fromException(e);
    } finally {
      loading = false;
      _notify();
    }
    await _syncSharing();
  }

  Future<AppError?> advance(DeliveryStatus status) async {
    updating = true;
    _notify();
    try {
      delivery = await _deliveries.changeStatus(deliveryId, status);
      await _syncSharing();
      return null;
    } catch (e) {
      return ErrorMapper.fromException(e);
    } finally {
      updating = false;
      _notify();
    }
  }

  Future<void> _syncSharing() async {
    final tracking = delivery?.status.isTracking ?? false;
    if (!tracking) {
      _stop();
      return;
    }
    if (sharing) return;
    try {
      await _location.ensureReady();
      locationError = null;
    } catch (e) {
      locationError = ErrorMapper.fromException(e);
      _notify();
      return;
    }
    _timer = Timer.periodic(interval, (_) => unawaited(sendNow()));
    unawaited(sendNow());
    _notify();
  }

  /// Sends one GPS fix (also used by the periodic timer).
  Future<void> sendNow() async {
    if (_sending || _disposed) return;
    _sending = true;
    try {
      final report = await _deliveries.reportLocation(deliveryId, await _location.currentFix());
      lastSentAt = DateTime.now();
      locationError = null;
      if (report.status != delivery?.status) delivery = await _deliveries.get(deliveryId);
    } catch (e) {
      locationError = ErrorMapper.fromException(e);
      if (locationError?.code == 'TRACKING_NOT_ACTIVE') _stop();
    } finally {
      _sending = false;
      _notify();
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stop();
    super.dispose();
  }
}
