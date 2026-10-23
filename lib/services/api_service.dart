import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../errors/error_messages.dart';
import '../utils/constants.dart';
import 'access_token_source.dart';
import 'http_json.dart';

/// HTTP adapter for TheOff1ceAI. Throws only `AppError`.
///
/// Every call carries `Authorization: Bearer <access token>` issued by
/// TheOff1ceAuth (AI-001). A 401 triggers one token refresh and one retry.
class ApiService {
  ApiService(this.baseUrl, {http.Client? client, Duration? timeout, AccessTokenSource? tokens})
      : _client = client ?? http.Client(),
        _timeout = timeout ?? NetworkTimeouts.analysis,
        _tokens = tokens;

  final String baseUrl;
  final http.Client _client;
  final Duration _timeout;
  final AccessTokenSource? _tokens;

  Future<Map<String, dynamic>> uploadImage(XFile image) async {
    final tokens = _tokens;
    final token = await tokens?.currentAccessToken();
    if (tokens != null && token == null) {
      throw ErrorMapper.fromAi(401, const {'error': {'code': 'AUTH_REQUIRED'}});
    }
    var response = await _send(image, token);
    if (response.statusCode == 401 && tokens != null) {
      final fresh = await tokens.currentAccessToken(forceRefresh: true);
      if (fresh != null && fresh != token) response = await _send(image, fresh);
    }
    if (!isSuccess(response)) {
      throw ErrorMapper.fromAi(response.statusCode, decodeErrorBody(response.body));
    }
    return decodeJsonObject(response.body);
  }

  /// A multipart request can be sent only once, so each attempt builds its own.
  Future<http.Response> _send(XFile image, String? token) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/analyze'))
      ..headers['Accept'] = 'application/json'
      ..files.add(await _filePart(image));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    return sendWithin(_timeout, () async => http.Response.fromStream(await _client.send(request)));
  }

  /// Reads the picked image (already resized by `ImageService`) on every platform.
  Future<http.MultipartFile> _filePart(XFile image) async {
    final contentType = MediaType.parse(image.mimeType ?? _mimeFromName(image.name));
    return http.MultipartFile.fromBytes('file', await _readBytes(image),
        filename: image.name, contentType: contentType);
  }

  static Future<List<int>> _readBytes(XFile image) async {
    try {
      return await image.readAsBytes();
    } catch (error) {
      throw AppError(kind: AppErrorKind.invalidFile, userMessage: ErrorMessages.invalidFile, retryable: false, cause: error);
    }
  }

  static String _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void dispose() => _client.close();
}
