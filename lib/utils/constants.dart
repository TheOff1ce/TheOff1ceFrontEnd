import 'package:flutter/foundation.dart';

/// Resolves service URLs from `--dart-define` first and then from safe,
/// platform-aware defaults. It never touches `dart:io`, so it also works on
/// Flutter Web (FE-001).
abstract final class AppConfig {
  static const _aiUrl = String.fromEnvironment('API_BASE_URL');
  static const _authUrl = String.fromEnvironment('AUTH_BASE_URL');

  static const aiPort = 8000;
  static const authPort = 3000;

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

  /// After this delay the analysis screen explains that it is taking longer.
  static const slowAnalysisHint = Duration(seconds: 12);
}
