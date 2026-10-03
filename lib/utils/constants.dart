import 'dart:io';

abstract final class AppConfig {
  static const _aiUrl = String.fromEnvironment('API_BASE_URL');
  static const _authUrl = String.fromEnvironment('AUTH_BASE_URL');
  static String get apiBaseUrl => _aiUrl.isNotEmpty
      ? _aiUrl
      : (Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000');

  /// The Nest authentication service. This is intentionally separate from AI.
  static String get authBaseUrl => _authUrl.isNotEmpty
      ? _authUrl
      : (Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000');
}
