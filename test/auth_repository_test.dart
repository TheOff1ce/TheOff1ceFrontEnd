import 'dart:convert';

import 'package:farma_go/auth/auth_models.dart';
import 'package:farma_go/auth/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('login uses the implemented Nest contract', () async {
    final repository = AuthRepository('https://auth.example',
        client: MockClient((request) async {
      expect(request.url.path, '/auth/login');
      expect(request.headers['content-type'], 'application/json');
      expect(jsonDecode(request.body),
          {'email': 'ana@example.com', 'password': 'Password123!'});
      return http.Response(
          jsonEncode({
            'status': 'verification_required',
            'message': 'Revisa tu correo para continuar.'
          }),
          200);
    }));
    expect(
        await repository.login(
            email: 'ana@example.com', password: 'Password123!'),
        contains('correo'));
  });

  test('maps authentication failures to safe UI messages', () async {
    final repository = AuthRepository('https://auth.example',
        client: MockClient((_) async => http.Response(
            jsonEncode({'message': 'Credenciales inválidas'}), 401)));
    expect(
        () => repository.login(
            email: 'ana@example.com', password: 'Password123!'),
        throwsA(isA<AuthFailure>()));
  });

  test('sends the real password-reset payload', () async {
    final repository = AuthRepository('https://auth.example',
        client: MockClient((request) async {
      expect(request.url.path, '/auth/reset-password');
      expect(jsonDecode(request.body), {
        'email': 'ana@example.com',
        'code': '123456',
        'newPassword': 'NuevaClave123!'
      });
      return http.Response(
          jsonEncode({'message': 'Contraseña actualizada correctamente.'}),
          200);
    }));
    expect(
      await repository.resetPassword(
        email: 'ana@example.com',
        code: '123456',
        newPassword: 'NuevaClave123!',
      ),
      contains('actualizada'),
    );
  });

  test('verifies a reset code before accepting a new password', () async {
    final repository = AuthRepository('https://auth.example',
        client: MockClient((request) async {
      expect(request.url.path, '/auth/verify-reset-code');
      expect(jsonDecode(request.body),
          {'email': 'ana@example.com', 'code': '123456'});
      return http.Response(jsonEncode({'status': 'code_verified'}), 200);
    }));
    await repository.verifyPasswordResetCode(
        email: 'ana@example.com', code: '123456');
  });
}
