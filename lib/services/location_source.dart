import 'package:geolocator/geolocator.dart';

import '../errors/app_error.dart';
import '../errors/error_messages.dart';
import '../types/delivery.dart';
import 'delivery_service.dart';

/// Device location for drivers (abstracted so controllers can be tested without GPS).
abstract interface class LocationSource {
  /// Asks for permission if needed; throws [AppError] when location cannot be used.
  Future<void> ensureReady();

  Future<GpsFix> currentFix();
}

class GeolocatorLocationSource implements LocationSource {
  @override
  Future<void> ensureReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) throw _error(ErrorMessages.locationDisabled);
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw _error(ErrorMessages.locationPermission);
    }
  }

  @override
  Future<GpsFix> currentFix() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      return GpsFix(
        point: GeoPoint(position.latitude, position.longitude),
        accuracy: position.accuracy,
        heading: position.heading,
        speed: position.speed,
        recordedAt: position.timestamp,
      );
    } catch (error) {
      throw AppError(kind: AppErrorKind.unknown, userMessage: ErrorMessages.locationUnavailable, retryable: true, cause: error);
    }
  }

  static AppError _error(String message) =>
      AppError(kind: AppErrorKind.forbidden, userMessage: message, retryable: false, code: 'LOCATION_UNAVAILABLE');
}
