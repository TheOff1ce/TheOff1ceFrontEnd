import 'dart:convert';
import 'dart:typed_data';

import 'package:farma_go/errors/app_error.dart';
import 'package:farma_go/services/access_token_source.dart';
import 'package:farma_go/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';

class FakeTokens implements AccessTokenSource {
  FakeTokens(this.tokens);

  final List<String?> tokens;
  final List<bool> requests = [];

  @override
  Future<String?> currentAccessToken({bool forceRefresh = false}) async {
    requests.add(forceRefresh);
    return tokens.removeAt(0);
  }
}

final image = XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'formula.png', mimeType: 'image/png');
final ok = http.Response(jsonEncode({'medications': []}), 200);
http.Response unauthorized() => http.Response(
      jsonEncode({
        'success': false,
        'error': {'code': 'TOKEN_INVALID', 'message': 'x'},
      }),
      401,
    );

void main() {
  test('AI-001: every analysis carries the Auth access token as Bearer', () async {
    final seen = <String?>[];
    final api = ApiService('https://ai.example', tokens: FakeTokens(['t1']), client: MockClient((request) async {
      seen.add(request.headers['Authorization']);
      return ok;
    }));
    await api.uploadImage(image);
    expect(seen, ['Bearer t1']);
  });

  test('a 401 refreshes the token once and retries with the new one', () async {
    final tokens = FakeTokens(['old', 'new']);
    final seen = <String?>[];
    final api = ApiService('https://ai.example', tokens: tokens, client: MockClient((request) async {
      seen.add(request.headers['Authorization']);
      return seen.length == 1 ? unauthorized() : ok;
    }));
    await api.uploadImage(image);
    expect(seen, ['Bearer old', 'Bearer new']);
    expect(tokens.requests, [false, true]);
  });

  test('a second 401 surfaces as "session ended" without looping', () async {
    var calls = 0;
    final api = ApiService('https://ai.example', tokens: FakeTokens(['old', 'new']), client: MockClient((_) async {
      calls++;
      return unauthorized();
    }));
    try {
      await api.uploadImage(image);
      fail('should throw');
    } on AppError catch (error) {
      expect(error.kind, AppErrorKind.unauthorized);
    }
    expect(calls, 2);
  });

  test('without a session the image is never uploaded', () async {
    var calls = 0;
    final api = ApiService('https://ai.example', tokens: FakeTokens([null]), client: MockClient((_) async {
      calls++;
      return ok;
    }));
    await expectLater(api.uploadImage(image), throwsA(isA<AppError>()));
    expect(calls, 0);
  });

  test('new AI codes have their own messages', () async {
    for (final (status, code, kind) in [
      (413, 'FILE_TOO_LARGE', AppErrorKind.invalidFile),
      (504, 'AI_TIMEOUT', AppErrorKind.timeout),
    ]) {
      final api = ApiService('https://ai.example', tokens: FakeTokens(['t']), client: MockClient((_) async {
        return http.Response(
            jsonEncode({
              'success': false,
              'error': {'code': code, 'message': 'x'},
            }),
            status);
      }));
      try {
        await api.uploadImage(image);
        fail('should throw');
      } on AppError catch (error) {
        expect(error.kind, kind, reason: code);
      }
    }
  });
}
