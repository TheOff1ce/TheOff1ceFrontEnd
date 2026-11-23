import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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

  /// `multipart/form-data` POST (archivos y campos de texto); la respuesta es JSON.
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required List<MultipartFilePart> files,
  }) async {
    final response = await _authorized((token) {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
        ..headers['Accept'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $token'
        ..fields.addAll(fields)
        ..files.addAll([for (final part in files) part.toHttp()]);
      return request;
    });
    return decodeJsonObject(response.body);
  }

  /// GET de un archivo binario (p. ej. la foto de una prueba de entrega).
  Future<Uint8List> getBytes(String path) async {
    final response = await _authorized((token) => http.Request('GET', Uri.parse('$baseUrl$path'))
      ..headers['Authorization'] = 'Bearer $token');
    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> _send(String method, String path, [Map<String, dynamic>? body]) async {
    final response = await _authorized((token) {
      final request = http.Request(method, Uri.parse('$baseUrl$path'))
        ..headers['Accept'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $token';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      return request;
    });
    return decodeJsonObject(response.body);
  }

  /// Sends the request built by [build] with the current token; a 401 triggers one refresh and
  /// one retry (the request is built again: a sent request cannot be reused). Throws `AppError`.
  Future<http.Response> _authorized(http.BaseRequest Function(String token) build) async {
    final token = await _tokens.currentAccessToken();
    if (token == null) throw _errorMapper(401, const {'error': {'code': 'TOKEN_REQUIRED'}});
    var response = await _once(build(token));
    if (response.statusCode == 401) {
      final fresh = await _tokens.currentAccessToken(forceRefresh: true);
      if (fresh != null && fresh != token) response = await _once(build(fresh));
    }
    if (!isSuccess(response)) throw _errorMapper(response.statusCode, decodeErrorBody(response.body));
    return response;
  }

  Future<http.Response> _once(http.BaseRequest request) =>
      sendWithin(_timeout, () async => http.Response.fromStream(await _client.send(request)));

  void dispose() => _client.close();
}

/// Un archivo de un envío `multipart/form-data`.
class MultipartFilePart {
  const MultipartFilePart({required this.field, required this.bytes, required this.filename, required this.contentType});

  final String field, filename;
  final Uint8List bytes;

  /// Tipo MIME, p. ej. `image/jpeg`.
  final String contentType;

  http.MultipartFile toHttp() =>
      http.MultipartFile.fromBytes(field, bytes, filename: filename, contentType: MediaType.parse(contentType));
}
