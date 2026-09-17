import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../types/api_error.dart';

class ApiService {
  ApiService(this.baseUrl, {http.Client? client})
      : _client = client ?? http.Client();
  final String baseUrl;
  final http.Client _client;
  Future<Map<String, dynamic>> uploadImage(XFile image) async {
    try {
      final r = http.MultipartRequest('POST', Uri.parse('$baseUrl/analyze'));
      r.files.add(
        kIsWeb
            ? http.MultipartFile.fromBytes(
                'file',
                await image.readAsBytes(),
                filename: image.name,
                contentType: MediaType.parse(image.mimeType ?? 'image/jpeg'),
              )
            : await http.MultipartFile.fromPath(
                'file',
                image.path,
                contentType: MediaType.parse(image.mimeType ?? 'image/jpeg'),
              ),
      );
      final s = await _client.send(r);
      final response = await http.Response.fromStream(s);
      final body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300)
        throw ApiError.fromStatusCode(
          response.statusCode,
          message: body['error'] is Map
              ? (body['error'] as Map)['message']?.toString()
              : body['message']?.toString() ?? body['detail']?.toString(),
        );
      return body;
    } on SocketException {
      throw const ApiError(
        ApiErrorType.noConnection,
        'No hay conexión con el servicio. Revisa tu red e inténtalo otra vez.',
      );
    } on FormatException {
      throw const ApiError(
        ApiErrorType.unexpected,
        'El servicio devolvió una respuesta que no pudimos leer.',
      );
    }
  }

  void dispose() => _client.close();
}
