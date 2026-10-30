import 'package:farma_go/utils/constants.dart';
import 'package:farma_go/utils/validators.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('deployed defaults', () {
    test('Auth and AI point to Azure unless a --dart-define overrides them', () {
      expect(AppConfig.authBaseUrl, 'https://farmago-auth-jl.azurewebsites.net');
      expect(AppConfig.apiBaseUrl, 'https://farmago-ai-jl.azurewebsites.net');
    });
  });

  group('FE-001 AppConfig.resolve', () {
    test('uses --dart-define first', () {
      expect(
        AppConfig.resolve(defined: 'https://auth.farmago.co/', port: 3000, isWeb: true, platform: TargetPlatform.android),
        'https://auth.farmago.co',
      );
    });

    test('on the web it never touches dart:io and follows the page host', () {
      expect(
        AppConfig.resolve(
          defined: '',
          port: 3000,
          isWeb: true,
          platform: TargetPlatform.android,
          pageUri: Uri.parse('http://127.0.0.1:5173/login'),
        ),
        'http://127.0.0.1:3000',
      );
      expect(AppConfig.resolve(defined: '', port: 8000, isWeb: true, platform: TargetPlatform.linux), 'http://localhost:8000');
    });

    test('Android emulator reaches the host through 10.0.2.2', () {
      expect(AppConfig.resolve(defined: '', port: 8000, isWeb: false, platform: TargetPlatform.android), 'http://10.0.2.2:8000');
      expect(AppConfig.resolve(defined: '', port: 8000, isWeb: false, platform: TargetPlatform.iOS), 'http://localhost:8000');
    });
  });

  group('FE-019 maskEmail', () {
    test('never throws and keeps the domain', () {
      expect(maskEmail('ana.perez@example.com'), 'an•••@example.com');
      expect(maskEmail('a@b.co'), 'a•••@b.co');
      expect(maskEmail(''), 'tu correo');
      expect(maskEmail(null), 'tu correo');
      expect(maskEmail('@x.co'), '•••');
      expect(maskEmail('sin-arroba'), '•••');
    });
  });

  group('Validators', () {
    test('messages are specific', () {
      expect(Validators.email('x'), contains('nombre@dominio.com'));
      expect(Validators.email('ana@example.com'), isNull);
      expect(Validators.password('short'), contains('8'));
      expect(Validators.confirmation(() => 'abc')('abd'), 'Las contraseñas no coinciden.');
      expect(Validators.isCode('123456'), isTrue);
      expect(Validators.isCode('12a456'), isFalse);
    });
  });
}
