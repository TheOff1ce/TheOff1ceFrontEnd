import 'dart:io';

abstract final class AppConfig {
  static const _url = String.fromEnvironment('API_BASE_URL');
  static String get apiBaseUrl => _url.isNotEmpty
      ? _url
      : (Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000');
}
