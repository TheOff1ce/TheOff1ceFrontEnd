import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

/// Google sign-in in the Android/iOS app.
///
/// The app opens `GET /auth/google?platform=app` of TheOff1ceAuth in an in-app browser tab. After
/// Google, Auth redirects to the app deep link with a one-time code in the fragment
/// (`farmago://auth/callback#code=…`) or an error in the query (`?error=…`). The app trades the
/// code with `POST /auth/google/exchange`, the same call the web uses.
abstract final class GoogleMobileSignIn {
  static const callbackScheme = 'farmago';

  static Uri startUrl(String authBaseUrl) =>
      Uri.parse('$authBaseUrl/auth/google').replace(queryParameters: const {'platform': 'app'});

  static final _codePattern = RegExp(r'^[A-Za-z0-9_-]{40,64}$');

  /// Reads the deep link Auth returned to. A malformed code counts as a failed sign-in.
  static GoogleCallback parse(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != callbackScheme) return const GoogleCallback.error('google_failed');
    final error = uri.queryParameters['error'];
    if (error != null && error.isNotEmpty) return GoogleCallback.error(error);
    final code = uri.fragment.isEmpty ? null : Uri.splitQueryString(uri.fragment)['code'];
    if (code == null || !_codePattern.hasMatch(code)) return const GoogleCallback.error('google_failed');
    return GoogleCallback.code(code);
  }

  /// Opens the browser tab and waits for the deep link. `null` when the person closed the tab.
  static Future<GoogleCallback?> authenticate(
    String authBaseUrl, {
    Future<String> Function({required String url, required String callbackUrlScheme})? open,
  }) async {
    final abrir = open ?? ({required url, required callbackUrlScheme}) =>
        FlutterWebAuth2.authenticate(url: url, callbackUrlScheme: callbackUrlScheme);
    try {
      final result = await abrir(url: startUrl(authBaseUrl).toString(), callbackUrlScheme: callbackScheme);
      return parse(result);
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') return null;
      rethrow;
    }
  }
}

/// Result of the Google deep link: a one-time [code] or an [error] code from Auth.
class GoogleCallback {
  const GoogleCallback.code(String this.code) : error = null;
  const GoogleCallback.error(String this.error) : code = null;

  final String? code;
  final String? error;
}
