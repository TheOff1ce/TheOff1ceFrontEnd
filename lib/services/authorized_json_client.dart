import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import 'access_token_source.dart';
import 'http_json.dart';

/// JSON client for the delivery services (TheOff1ceOrderDelivery and TheOff1ceGeolocation).
///
/// Every call carries `Authorization: Bearer <access token>` from TheOff1ceAuth; a 401 triggers
/// one refresh and one retry, like `ApiService`. Throws only `AppError`.
class AuthorizedJsonClient {
  AuthorizedJsonClient(
    this.baseUrl, {
    required AccessTokenSource tokens,
    http.Client? client,
    required Duration timeout,
    AppError Function(int status, Map<String, dynamic> body)? errorMapper,
  })  : _tokens = tokens,
        _client = client ?? http.Client(),
        _timeout = timeout,
        _errorMapper = errorMapper ?? ErrorMapper.fromDelivery;

  final String baseUrl;
  final AccessTokenSource _tokens;
  final http.Client _client;
  final Duration _timeout;

  /// Traduce las respuestas de error del servicio; por defecto, las de los servicios de domicilios.
  final AppError Function(int status, Map<String, dynamic> body) _errorMapper;

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) => _send('POST', path, body);

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) => _send('PATCH', path, body);

  Future<Map<String, dynamic>> _send(String method, String path, [Map<String, dynamic>? body]) async {
    final token = await _tokens.currentAccessToken();
    if (token == null) throw _errorMapper(401, const {'error': {'code': 'TOKEN_REQUIRED'}});
    var response = await _once(method, path, body, token);
    if (response.statusCode == 401) {
      final fresh = await _tokens.currentAccessToken(forceRefresh: true);
      if (fresh != null && fresh != token) response = await _once(method, path, body, fresh);
    }
    if (!isSuccess(response)) throw _errorMapper(response.statusCode, decodeErrorBody(response.body));
    return decodeJsonObject(response.body);
  }

  Future<http.Response> _once(String method, String path, Map<String, dynamic>? body, String token) {
    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    return sendWithin(_timeout, () async => http.Response.fromStream(await _client.send(request)));
  }

  void dispose() => _client.close();
}
