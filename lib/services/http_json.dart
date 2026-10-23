import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';

/// Sends a request within a time budget and turns transport failures into
/// [AppError]s (FE-004). Works the same on web (ClientException) and on
/// native platforms (SocketException wrapped or not).
Future<http.Response> sendWithin(Duration budget, Future<http.Response> Function() request) async {
  try {
    return await request().timeout(budget);
  } on TimeoutException catch (error) {
    throw ErrorMapper.fromException(error);
  } on AppError {
    rethrow;
  } on Exception catch (error) {
    throw ErrorMapper.network(error);
  }
}

/// Decodes a JSON object body; an empty body is an empty object.
Map<String, dynamic> decodeJsonObject(String body) {
  if (body.trim().isEmpty) return <String, dynamic>{};
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
  } on FormatException catch (error) {
    throw ErrorMapper.fromException(error);
  }
  throw ErrorMapper.fromException(const FormatException('Expected a JSON object'));
}

bool isSuccess(http.Response response) => response.statusCode >= 200 && response.statusCode < 300;

/// Error bodies may be HTML from a proxy; they are only inspected for a code.
Map<String, dynamic> decodeErrorBody(String body) {
  try {
    return decodeJsonObject(body);
  } on AppError {
    return <String, dynamic>{};
  }
}
