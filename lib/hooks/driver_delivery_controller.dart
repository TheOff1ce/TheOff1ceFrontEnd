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
///
/// Sin señal: cada ubicación que no se pudo enviar se guarda (hasta [maxPendientes]) y, al volver
/// la conexión, se envían en orden antes de la actual. Geolocation descarta las de más de 2 min
/// (STALE), así que las más viejas que [vigenciaPendiente] se dejan de intentar.
class DriverDeliveryController extends ChangeNotifier {
  DriverDeliveryController({
    required this.deliveryId,
    required DeliveryService deliveries,
    required LocationSource location,
    this.interval = const Duration(seconds: 10),
    DateTime Function()? now,
  })  : _deliveries = deliveries,
        _location = location,
        _now = now ?? DateTime.now;

  static const maxPendientes = 30;
  static const vigenciaPendiente = Duration(seconds: 110);

  final String deliveryId;
  final Duration interval;
  final DeliveryService _deliveries;
  final LocationSource _location;
  final DateTime Function() _now;
  final List<GpsFix> _pendientes = [];
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

  /// La última ubicación no salió por falta de conexión; se reintenta sola.
  bool sinSenal = false;

  /// Ubicaciones guardadas que aún no llegan al servidor.
  int get pendientesSinEnviar => _pendientes.length;

  bool get sharing => _timer != null;

  /// Next status the driver can move to, as a primary action. There is no "delivered": the
  /// patient closes the delivery by typing the driver's code.
  DeliveryStatus? get nextStep => switch (delivery?.status) {
        DeliveryStatus.assigned => DeliveryStatus.pickedUp,
        DeliveryStatus.pickedUp => DeliveryStatus.inTransit,
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

  /// Sends one GPS fix (also used by the periodic timer), after the ones saved without signal.
  Future<void> sendNow() async {
    if (_sending || _disposed) return;
    _sending = true;
    try {
      _guardar(await _location.currentFix());
      await _enviarPendientes();
    } catch (e) {
      locationError = ErrorMapper.fromException(e);
      if (locationError?.code == 'TRACKING_NOT_ACTIVE') {
        _pendientes.clear();
        sinSenal = false;
        // Usually the patient just confirmed with the code: show the final status, not an error.
        _stop();
        locationError = null;
        await _reload();
      }
    } finally {
      _sending = false;
      _notify();
    }
  }

  void _guardar(GpsFix fix) {
    _pendientes.add(fix);
    if (_pendientes.length > maxPendientes) _pendientes.removeRange(0, _pendientes.length - maxPendientes);
  }

  /// Envía en orden lo guardado. Sin señal se detiene y conserva el resto para la próxima vez.
  Future<void> _enviarPendientes() async {
    final ahora = _now();
    _pendientes.removeWhere((f) => ahora.difference(f.recordedAt) > vigenciaPendiente);
    var cambioEstado = false;
    while (_pendientes.isNotEmpty) {
      final LocationReport report;
      try {
        report = await _deliveries.reportLocation(deliveryId, _pendientes.first);
      } catch (e) {
        final error = ErrorMapper.fromException(e);
        if (!_esFaltaDeSenal(error)) {
          // El servidor la rechazó por otra razón: reintentarla no sirve.
          _pendientes.removeAt(0);
          rethrow;
        }
        sinSenal = true;
        locationError = null;
        return;
      }
      _pendientes.removeAt(0);
      sinSenal = false;
      lastSentAt = _now();
      locationError = null;
      if (report.status != delivery?.status) cambioEstado = true;
    }
    if (cambioEstado) delivery = await _deliveries.get(deliveryId);
  }

  static bool _esFaltaDeSenal(AppError error) =>
      error.kind == AppErrorKind.network || error.kind == AppErrorKind.timeout || error.kind == AppErrorKind.server;

  Future<void> _reload() async {
    try {
      delivery = await _deliveries.get(deliveryId);
    } catch (_) {
      // Keeps the last known delivery; the next manual refresh will retry.
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _pendientes.clear();
    sinSenal = false;
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
