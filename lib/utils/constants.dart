import 'package:flutter/foundation.dart';

/// Resolves service URLs from `--dart-define` first and then from defaults.
/// Auth and AI default to their Azure App Service deployments; the delivery
/// services still default to platform-aware localhost URLs. It never touches
/// `dart:io`, so it also works on Flutter Web (FE-001).
abstract final class AppConfig {
  /// Deployed services (Azure App Service). Override with `--dart-define` to use local ones,
  /// e.g. `--dart-define=AUTH_BASE_URL=http://localhost:3000`.
  static const deployedAuthUrl = 'https://farmago-auth-jl.azurewebsites.net';
  static const deployedAiUrl = 'https://farmago-ai-jl.azurewebsites.net';

  static const _aiUrl = String.fromEnvironment('API_BASE_URL', defaultValue: deployedAiUrl);
  static const _authUrl = String.fromEnvironment('AUTH_BASE_URL', defaultValue: deployedAuthUrl);
  static const _ordersUrl = String.fromEnvironment('ORDERS_BASE_URL');
  static const _geolocationUrl = String.fromEnvironment('GEOLOCATION_BASE_URL');

  /// Client key for Google Maps (browser/app key restricted by referrer or package),
  /// never the server key. Empty: the app shows a simplified map.
  static const mapsApiKey = String.fromEnvironment('MAPS_API_KEY');

  static bool get hasMapsKey => mapsApiKey.isNotEmpty;

  static const aiPort = 8000;
  static const authPort = 3000;
  static const geolocationPort = 3001;
  static const ordersPort = 3002;

  static String get apiBaseUrl => resolve(
        defined: _aiUrl,
        port: aiPort,
        isWeb: kIsWeb,
        platform: defaultTargetPlatform,
        pageUri: kIsWeb ? Uri.base : null,
      );

  /// The Nest authentication service. This is intentionally separate from AI.
  static String get authBaseUrl => resolve(
        defined: _authUrl,
        port: authPort,
        isWeb: kIsWeb,
        platform: defaultTargetPlatform,
        pageUri: kIsWeb ? Uri.base : null,
      );

  /// TheOff1ceOrderDelivery: patients request deliveries, drivers take them.
  static String get ordersBaseUrl => resolve(
        defined: _ordersUrl,
        port: ordersPort,
        isWeb: kIsWeb,
        platform: defaultTargetPlatform,
        pageUri: kIsWeb ? Uri.base : null,
      );

  /// TheOff1ceGeolocation: delivery tracking (REST and Socket.IO).
  static String get geolocationBaseUrl => resolve(
        defined: _geolocationUrl,
        port: geolocationPort,
        isWeb: kIsWeb,
        platform: defaultTargetPlatform,
        pageUri: kIsWeb ? Uri.base : null,
      );

  /// Pure resolution rule, exposed for tests.
  ///
  /// On the web the default host is the host serving the page, so the
  /// refresh cookie of the auth service stays same-site (`localhost` and
  /// `127.0.0.1` are different sites for cookies).
  @visibleForTesting
  static String resolve({
    required String defined,
    required int port,
    required bool isWeb,
    required TargetPlatform platform,
    Uri? pageUri,
  }) {
    if (defined.isNotEmpty) return defined.replaceAll(RegExp(r'/+$'), '');
    if (isWeb) {
      final host = (pageUri == null || pageUri.host.isEmpty) ? 'localhost' : pageUri.host;
      return 'http://$host:$port';
    }
    if (platform == TargetPlatform.android) return 'http://10.0.2.2:$port';
    return 'http://localhost:$port';
  }
}

/// Network budgets used by every repository (FE-004).
abstract final class NetworkTimeouts {
  static const auth = Duration(seconds: 15);
  static const analysis = Duration(seconds: 90);

  /// Publishing an order geocodes addresses and computes a route in Geolocation.
  static const orders = Duration(seconds: 25);
  static const tracking = Duration(seconds: 15);

  /// After this delay the analysis screen explains that it is taking longer.
  static const slowAnalysisHint = Duration(seconds: 12);
}

/// Delivery tracking cadence.
abstract final class TrackingConfig {
  /// How often the driver's app sends its location while on the way.
  static const locationInterval = Duration(seconds: 10);
}
