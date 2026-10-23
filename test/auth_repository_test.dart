import 'dart:convert';

import 'package:farma_go/auth/auth_repository.dart';
import 'package:farma_go/errors/app_error.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response jsonResponse(Object body, int status, {Map<String, String> headers = const {}}) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json', ...headers});

Map<String, dynamic> errorBody(String code, [String message = 'server text']) => {
      'success': false,
      'error': {'code': code, 'message': message},
    };

AuthRepository repo(MockClientHandler handler, {bool browser = true, FlutterSecureStorage? storage}) =>
    AuthRepository('https://auth.example',
        client: MockClient(handler), usesBrowserCookies: browser, storage: storage);

void main() {
  test('login uses the implemented Nest contract', () async {
    final repository = repo((request) async {
      expect(request.url.path, '/auth/login');
      expect(request.headers['content-type'], 'application/json');
      expect(jsonDecode(request.body), {'email': 'ana@example.com', 'password': 'Password123!'});
      return jsonResponse({'status': 'verification_required'}, 200);
    });
    await repository.login(email: 'ana@example.com', password: 'Password123!');
  });

  test('maps backend codes to human messages and never shows server text', () async {
    final repository = repo((_) async => jsonResponse(errorBody('INVALID_CREDENTIALS', 'Credenciales inválidas'), 401));
    final error = await repository
        .login(email: 'ana@example.com', password: 'Password123!')
        .then<AppError?>((_) => null, onError: (Object e) => e as AppError);
    expect(error!.kind, AppErrorKind.invalidCredentials);
    expect(error.userMessage, isNot(contains('Credenciales inválidas')));
  });

  test('a framework 404 such as "Cannot POST" is never shown', () async {
    final repository = repo((_) async => jsonResponse({'statusCode': 404, 'message': 'Cannot POST /auth/x'}, 404));
    try {
      await repository.verifyPasswordResetCode(email: 'a@b.co', code: '123456');
      fail('should throw');
    } on AppError catch (error) {
      expect(error.kind, AppErrorKind.notFound);
      expect(error.userMessage, isNot(contains('Cannot POST')));
    }
  });

  test('verifies a reset code against POST /auth/verify-reset-code', () async {
    final repository = repo((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/auth/verify-reset-code');
      expect(jsonDecode(request.body), {'email': 'ana@example.com', 'code': '123456'});
      return jsonResponse({'status': 'code_verified'}, 200);
    });
    await repository.verifyPasswordResetCode(email: 'ana@example.com', code: '123456');
  });

  test('sends the real password-reset payload', () async {
    final repository = repo((request) async {
      expect(request.url.path, '/auth/reset-password');
      expect(jsonDecode(request.body), {'email': 'ana@example.com', 'code': '123456', 'newPassword': 'NuevaClave123!'});
      return jsonResponse({'message': 'ok'}, 200);
    });
    await repository.resetPassword(email: 'ana@example.com', code: '123456', newPassword: 'NuevaClave123!');
  });

  test('refresh returns a 600-second session by default', () async {
    final repository = repo((_) async => jsonResponse({'accessToken': 'a'}, 200));
    final session = await repository.refresh();
    expect(session.expiresIn, 600);
    expect(session.isValid, isTrue);
  });

  test('transport failures become a network error', () async {
    final repository = repo((_) async => throw http.ClientException('XMLHttpRequest error'));
    try {
      await repository.refresh();
      fail('should throw');
    } on AppError catch (error) {
      expect(error.kind, AppErrorKind.network);
      expect(error.isTransient, isTrue);
    }
  });

  test('a slow service becomes a timeout error', () async {
    final repository = AuthRepository('https://auth.example',
        usesBrowserCookies: true,
        timeout: const Duration(milliseconds: 10),
        client: MockClient((_) => Future.delayed(const Duration(seconds: 1), () => jsonResponse({}, 200))));
    try {
      await repository.refresh();
      fail('should throw');
    } on AppError catch (error) {
      expect(error.kind, AppErrorKind.timeout);
    }
  });

  test('an HTML error page from a proxy still maps by status', () async {
    final repository = repo((_) async => http.Response('<html>Bad gateway</html>', 502));
    try {
      await repository.refresh();
      fail('should throw');
    } on AppError catch (error) {
      expect(error.kind, AppErrorKind.server);
      expect(error.userMessage, isNot(contains('html')));
    }
  });

  test('outside the browser the refresh cookie is captured and replayed', () async {
    FlutterSecureStorage.setMockInitialValues({});
    var calls = 0;
    final repository = repo(browser: false, storage: const FlutterSecureStorage(), (request) async {
      calls++;
      if (calls == 1) {
        return jsonResponse({'accessToken': 'a', 'expiresIn': 600}, 200,
            headers: {'set-cookie': 'refresh_token=abc123; Path=/auth; HttpOnly'});
      }
      expect(request.headers['Cookie'], 'refresh_token=abc123');
      return jsonResponse({'accessToken': 'b', 'expiresIn': 600}, 200);
    });
    await repository.verifyCode(email: 'a@b.co', code: '123456');
    await repository.refresh();
    expect(calls, 2);
  });
}
