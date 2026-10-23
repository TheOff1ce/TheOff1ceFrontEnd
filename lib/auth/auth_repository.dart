import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../errors/error_mapper.dart';
import '../services/auth_http_client.dart';
import '../services/http_json.dart';
import '../types/auth_models.dart';
import '../utils/constants.dart';

/// HTTP adapter for TheOff1ceAuth. Every failure surfaces as `AppError`.
///
/// Refresh-token handling: on the web the browser keeps the `HttpOnly`
/// cookie; on mobile and desktop the token is read from `set-cookie` and kept
/// in secure storage, because those clients have no cookie jar.
class AuthRepository {
  AuthRepository(
    this.baseUrl, {
    http.Client? client,
    FlutterSecureStorage? storage,
    Duration? timeout,
    bool? usesBrowserCookies,
  })  : _client = client ?? createAuthHttpClient(),
        _storage = storage ?? const FlutterSecureStorage(),
        _timeout = timeout ?? NetworkTimeouts.auth,
        _usesBrowserCookies = usesBrowserCookies ?? kIsWeb;

  static const _refreshKey = 'farma_go_refresh_token';

  final String baseUrl;
  final http.Client _client;
  final FlutterSecureStorage _storage;
  final Duration _timeout;
  final bool _usesBrowserCookies;
  String? _storedRefreshToken;

  Uri _uri(String path) => Uri.parse('$baseUrl/auth/$path');

  Future<void> signUp({required String name, required String email, required String password}) =>
      _post('signup', {'name': name, 'email': email, 'password': password});

  Future<void> login({required String email, required String password}) =>
      _post('login', {'email': email, 'password': password});

  Future<AuthSession> verifyCode({required String email, required String code}) async =>
      AuthSession.fromJson(await _post('verify-code', {'email': email, 'code': code}));

  Future<void> resendCode(String email) => _post('resend-code', {'email': email});

  Future<void> requestPasswordReset(String email) => _post('forgot-password', {'email': email});

  Future<void> verifyPasswordResetCode({required String email, required String code}) =>
      _post('verify-reset-code', {'email': email, 'code': code});

  Future<void> resetPassword({required String email, required String code, required String newPassword}) =>
      _post('reset-password', {'email': email, 'code': code, 'newPassword': newPassword});

  Future<AuthSession> refresh() async => AuthSession.fromJson(await _post('refresh', null));

  Future<AuthUser> me(String accessToken) async {
    final response = await sendWithin(
      _timeout,
      () => _client.get(_uri('me'), headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      }),
    );
    return AuthUser.fromJson(_decode(response));
  }

  /// Revokes the server session when reachable; the local token is always dropped.
  Future<void> logout() async {
    try {
      await _post('logout', null);
    } finally {
      await _clearStoredRefresh();
    }
  }

  /// Drops a refresh token the server already rejected, without a network call.
  Future<void> discardLocalSession() => _clearStoredRefresh();

  Future<void> restoreStoredRefresh() async {
    if (_usesBrowserCookies) return;
    try {
      _storedRefreshToken = await _storage.read(key: _refreshKey);
    } catch (_) {
      // Unreadable secure storage behaves like "no stored session".
      _storedRefreshToken = null;
    }
  }

  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic>? payload) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (payload != null) headers['Content-Type'] = 'application/json';
    final stored = _storedRefreshToken;
    if (!_usesBrowserCookies && stored != null) headers['Cookie'] = 'refresh_token=$stored';
    final response = await sendWithin(
      _timeout,
      () => _client.post(_uri(endpoint), headers: headers, body: payload == null ? null : jsonEncode(payload)),
    );
    await _captureRefresh(response);
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (!isSuccess(response)) {
      throw ErrorMapper.fromAuth(response.statusCode, decodeErrorBody(response.body));
    }
    return decodeJsonObject(response.body);
  }

  Future<void> _captureRefresh(http.Response response) async {
    if (_usesBrowserCookies) return;
    final match = RegExp(r'refresh_token=([^;,\s]*)').firstMatch(response.headers['set-cookie'] ?? '');
    if (match == null) return;
    final token = match.group(1) ?? '';
    if (token.isEmpty) {
      await _clearStoredRefresh();
      return;
    }
    _storedRefreshToken = token;
    try {
      await _storage.write(key: _refreshKey, value: token);
    } catch (_) {
      // Keeps working for this run; the session simply will not survive a restart.
    }
  }

  Future<void> _clearStoredRefresh() async {
    _storedRefreshToken = null;
    if (_usesBrowserCookies) return;
    try {
      await _storage.delete(key: _refreshKey);
    } catch (_) {
      // Nothing else to clean: the in-memory token is already gone.
    }
  }

  void dispose() => _client.close();
}
