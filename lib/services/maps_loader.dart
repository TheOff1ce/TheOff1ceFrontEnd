import 'maps_loader_stub.dart' if (dart.library.js_interop) 'maps_loader_web.dart' as impl;

/// Makes sure the Google Maps JavaScript API is loaded (web only; no-op on Android/iOS,
/// where the SDK key comes from the platform configuration).
Future<bool> ensureGoogleMapsLoaded(String apiKey) => impl.ensureGoogleMapsLoaded(apiKey);
