import 'dart:async';

import 'package:farma_go/errors/app_error.dart';
import 'package:farma_go/errors/error_mapper.dart';
import 'package:farma_go/errors/error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> body(String code) => {
      'success': false,
      'error': {'code': code, 'message': 'internal english text'},
    };

void main() {
  group('AI codes', () {
    test('non-retryable file problems ask for another image', () {
      for (final code in ['INVALID_FILE', 'UNSUPPORTED_MEDIA_TYPE']) {
        final error = ErrorMapper.fromAi(code == 'INVALID_FILE' ? 400 : 415, body(code));
        expect(error.retryable, isFalse, reason: code);
        expect(error.userMessage, isNot(contains('internal')));
      }
    });

    test('an unreadable analysis (422) is not reported as an invalid file', () {
      final error = ErrorMapper.fromAi(422, body('INVALID_AI_RESPONSE'));
      expect(error.kind, AppErrorKind.unreadableAnalysis);
      expect(error.retryable, isTrue);
    });

    test('timeouts and unavailability are transient', () {
      expect(ErrorMapper.fromAi(504, body('AI_TIMEOUT')).kind, AppErrorKind.timeout);
      expect(ErrorMapper.fromAi(503, body('AI_UNAVAILABLE')).isTransient, isTrue);
    });

    test('a FastAPI detail list is never shown', () {
      final error = ErrorMapper.fromAi(422, {
        'detail': [
          {'type': 'missing', 'loc': ['body', 'file']},
        ],
      });
      expect(error.userMessage, ErrorMessages.validation);
    });
  });

  group('Auth codes', () {
    test('every documented code has its own message', () {
      expect(ErrorMapper.fromAuth(401, body('INVALID_CREDENTIALS')).userMessage, ErrorMessages.invalidCredentials);
      expect(ErrorMapper.fromAuth(401, body('CODE_INVALID')).kind, AppErrorKind.invalidCode);
      expect(ErrorMapper.fromAuth(401, body('SESSION_INVALID')).endsSession, isTrue);
      expect(ErrorMapper.fromAuth(409, body('ACCOUNT_EXISTS')).userMessage, ErrorMessages.accountExists);
      expect(ErrorMapper.fromAuth(429, body('RATE_LIMITED')).kind, AppErrorKind.rateLimit);
      expect(ErrorMapper.fromAuth(403, body('FORBIDDEN')).userMessage, ErrorMessages.forbidden);
    });

    test('unknown bodies fall back to the HTTP status', () {
      expect(ErrorMapper.fromAuth(500, {}).kind, AppErrorKind.server);
      expect(ErrorMapper.fromAuth(500, {}).showsReference, isTrue);
      expect(ErrorMapper.fromAuth(403, {}).kind, AppErrorKind.forbidden);
      expect(ErrorMapper.fromAuth(404, {}).kind, AppErrorKind.notFound);
    });
  });

  test('client-side exceptions are translated', () {
    expect(ErrorMapper.fromException(TimeoutException('x')).kind, AppErrorKind.timeout);
    expect(ErrorMapper.fromException(const FormatException('x')).kind, AppErrorKind.invalidResponse);
    expect(ErrorMapper.fromException(StateError('x')).kind, AppErrorKind.unknown);
  });

  test('Google redirect codes map to human messages', () {
    expect(ErrorMapper.googleRedirectMessage('google_account_conflict'), ErrorMessages.googleConflict);
    expect(ErrorMapper.googleRedirectMessage('oauth_state_invalid'), ErrorMessages.googleState);
    expect(ErrorMapper.googleRedirectMessage(null), ErrorMessages.googleFailed);
  });

  test('every error carries a short support reference', () {
    expect(ErrorMapper.fromAuth(500, {}).referenceId, matches(RegExp(r'^FG-[A-Z0-9]{6}$')));
  });
}
