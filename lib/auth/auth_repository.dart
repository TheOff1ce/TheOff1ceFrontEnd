import 'dart:convert';
import 'dart:io' show Platform, SocketException;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../services/auth_http_client.dart';
import 'auth_models.dart';

class AuthRepository {
  AuthRepository(this.baseUrl,
      {http.Client? client, FlutterSecureStorage? storage})
      : _client = client ?? createAuthHttpClient(),
        _storage = storage ?? const FlutterSecureStorage();
  final String baseUrl;
  final http.Client _client;
  final FlutterSecureStorage _storage;
  String? _nativeRefreshToken;
  Uri _uri(String path) => Uri.parse('$baseUrl/auth/$path');

  Future<String> signUp(
      {required String name,
      required String email,
      required String password}) async {
    final data = await _post(
        'signup', {'name': name, 'email': email, 'password': password});
    return data['message']?.toString() ??
        'Revisa tu correo para verificar la cuenta.';
  }

  Future<String> login(
      {required String email, required String password}) async {
    final data = await _post('login', {'email': email, 'password': password});
    return data['message']?.toString() ?? 'Revisa tu correo para continuar.';
  }

  Future<AuthSession> verifyCode(
          {required String email, required String code}) async =>
      AuthSession.fromJson(
          await _post('verify-code', {'email': email, 'code': code}));
  Future<String> resendCode(String email) async {
    final data = await _post('resend-code', {'email': email});
    return data['message']?.toString() ??
        'Si existe un desafío activo, se envió un nuevo código.';
  }

  Future<String> requestPasswordReset(String email) async {
    final data = await _post('forgot-password', {'email': email});
    return data['message']?.toString() ??
        'Si el correo está registrado, recibirás un código para restablecer la contraseña.';
  }

  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final data = await _post('reset-password', {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
    return data['message']?.toString() ??
        'Contraseña actualizada correctamente.';
  }

  Future<void> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    await _post('verify-reset-code', {'email': email, 'code': code});
  }

  Future<AuthSession> refresh() async =>
      AuthSession.fromJson(await _post('refresh', null));
  Future<AuthUser> me(String accessToken) async {
    final response = await _client
        .get(_uri('me'), headers: {'Authorization': 'Bearer $accessToken'});
    return AuthUser.fromJson(_decode(response));
  }

  Future<void> logout() async {
    try {
      await _post('logout', null);
    } finally {
      await _clearNativeRefresh();
    }
  }

  Future<Map<String, dynamic>> _post(
      String endpoint, Map<String, dynamic>? payload) async {
    try {
      final headers = <String, String>{'Accept': 'application/json'};
      if (payload != null) {
        headers['Content-Type'] = 'application/json';
      }
      if (_isNative && _nativeRefreshToken != null) {
        headers['Cookie'] = 'refresh_token=$_nativeRefreshToken';
      }
      final response = await _client.post(_uri(endpoint),
          headers: headers, body: payload == null ? null : jsonEncode(payload));
      await _saveNativeRefresh(response);
      return _decode(response);
    } on SocketException {
      throw const AuthFailure(
          'No pudimos conectar con el servicio de autenticación.');
    } on FormatException {
      throw const AuthFailure(
          'El servicio respondió con información no válida.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    if (response.statusCode == 401) {
      throw const AuthFailure('Verifica tus datos o solicita un código nuevo.');
    }
    if (response.statusCode == 409) {
      throw const AuthFailure('Ya existe una cuenta con este correo.');
    }
    if (response.statusCode == 429) {
      throw const AuthFailure(
          'Has realizado varios intentos. Espera unos minutos.');
    }
    if (response.statusCode == 400) {
      throw const AuthFailure(
          'Revisa los datos ingresados e inténtalo de nuevo.');
    }
    throw AuthFailure(body['message']?.toString() ??
        'No pudimos completar la acción. Inténtalo otra vez.');
  }

  bool get _isNative => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  Future<void> _saveNativeRefresh(http.Response response) async {
    if (!_isNative) {
      return;
    }
    final match = RegExp(r'refresh_token=([^;]+)')
        .firstMatch(response.headers['set-cookie'] ?? '');
    if (match != null) {
      _nativeRefreshToken = match.group(1);
      await _storage.write(
          key: 'farma_go_refresh_token', value: _nativeRefreshToken);
    }
  }

  Future<void> restoreNativeRefresh() async {
    if (_isNative) {
      _nativeRefreshToken = await _storage.read(key: 'farma_go_refresh_token');
    }
  }

  Future<void> _clearNativeRefresh() async {
    _nativeRefreshToken = null;
    if (_isNative) {
      await _storage.delete(key: 'farma_go_refresh_token');
    }
  }

  void dispose() => _client.close();
}
