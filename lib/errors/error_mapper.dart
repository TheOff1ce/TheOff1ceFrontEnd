import 'dart:async';

import 'app_error.dart';
import 'error_messages.dart';

typedef _Entry = (AppErrorKind kind, String message, bool retryable);

/// Central translation from technical failures to [AppError] (FE-002).
///
/// Backend `message`/`detail` texts are never shown: only stable codes and
/// HTTP statuses are used to pick a sentence from [ErrorMessages].
abstract final class ErrorMapper {
  static const Map<String, _Entry> _aiCodes = {
    'INVALID_FILE': (AppErrorKind.invalidFile, ErrorMessages.invalidFile, false),
    'UNSUPPORTED_MEDIA_TYPE': (AppErrorKind.unsupportedFile, ErrorMessages.unsupportedFile, false),
    'INVALID_REQUEST': (AppErrorKind.validation, ErrorMessages.analysisRequest, false),
    'INVALID_AI_RESPONSE': (AppErrorKind.unreadableAnalysis, ErrorMessages.unreadableAnalysis, true),
    'AI_UNAVAILABLE': (AppErrorKind.server, ErrorMessages.analysisUnavailable, true),
    'AI_TIMEOUT': (AppErrorKind.timeout, ErrorMessages.analysisTimeout, true),
    'INTERNAL_ERROR': (AppErrorKind.server, ErrorMessages.server, true),
    'FILE_TOO_LARGE': (AppErrorKind.invalidFile, ErrorMessages.fileTooLarge, false),
    'AUTH_REQUIRED': (AppErrorKind.unauthorized, ErrorMessages.sessionEnded, false),
    'TOKEN_INVALID': (AppErrorKind.unauthorized, ErrorMessages.sessionEnded, false),
    'NOT_FOUND': (AppErrorKind.notFound, ErrorMessages.notFound, false),
  };

  static const Map<String, _Entry> _authCodes = {
    'INVALID_CREDENTIALS': (AppErrorKind.invalidCredentials, ErrorMessages.invalidCredentials, false),
    'CODE_INVALID': (AppErrorKind.invalidCode, ErrorMessages.invalidCode, false),
    'SESSION_INVALID': (AppErrorKind.unauthorized, ErrorMessages.sessionEnded, false),
    'TOKEN_INVALID': (AppErrorKind.unauthorized, ErrorMessages.sessionEnded, false),
    'TOKEN_REQUIRED': (AppErrorKind.unauthorized, ErrorMessages.sessionEnded, false),
    'UNAUTHORIZED': (AppErrorKind.unauthorized, ErrorMessages.sessionEnded, false),
    'ACCOUNT_EXISTS': (AppErrorKind.conflict, ErrorMessages.accountExists, false),
    'ACCOUNT_INVALID': (AppErrorKind.forbidden, ErrorMessages.accountBlocked, false),
    'FORBIDDEN': (AppErrorKind.forbidden, ErrorMessages.forbidden, false),
    'RATE_LIMITED': (AppErrorKind.rateLimit, ErrorMessages.rateLimit, true),
    'EMAIL_DELIVERY_FAILED': (AppErrorKind.server, ErrorMessages.emailDelivery, true),
    'VALIDATION_FAILED': (AppErrorKind.validation, ErrorMessages.validation, false),
    'NOT_FOUND': (AppErrorKind.notFound, ErrorMessages.notFound, false),
    'SERVICE_UNAVAILABLE': (AppErrorKind.server, ErrorMessages.server, true),
    'INTERNAL_ERROR': (AppErrorKind.server, ErrorMessages.server, true),
  };

  /// Error answered by TheOff1ceAI (`{success:false, error:{code,message}}`).
  static AppError fromAi(int status, Map<String, dynamic> body) =>
      _fromCode(_aiCodes, status, body);

  /// Error answered by TheOff1ceAuth (`{success:false, error:{code,message}}`).
  static AppError fromAuth(int status, Map<String, dynamic> body) =>
      _fromCode(_authCodes, status, body);

  /// Transport and client-side failures.
  static AppError fromException(Object error) {
    if (error is AppError) return error;
    if (error is TimeoutException) {
      return AppError(kind: AppErrorKind.timeout, userMessage: ErrorMessages.timeout, retryable: true, cause: error);
    }
    if (error is FormatException) {
      return AppError(
          kind: AppErrorKind.invalidResponse,
          userMessage: ErrorMessages.invalidResponse,
          retryable: true,
          cause: error);
    }
    return AppError(kind: AppErrorKind.unknown, userMessage: ErrorMessages.unexpected, retryable: true, cause: error);
  }

  /// Any exception raised while the request travels (ClientException,
  /// SocketException, TLS errors…) means the service could not be reached.
  static AppError network(Object cause) =>
      AppError(kind: AppErrorKind.network, userMessage: ErrorMessages.network, retryable: true, cause: cause);

  static String? codeOf(Map<String, dynamic> body) {
    final error = body['error'];
    if (error is Map && error['code'] is String) return error['code'] as String;
    return null;
  }

  static AppError _fromCode(Map<String, _Entry> catalog, int status, Map<String, dynamic> body) {
    final code = codeOf(body);
    final entry = catalog[code] ?? _fromStatus(status);
    return AppError(kind: entry.$1, userMessage: entry.$2, retryable: entry.$3, code: code ?? 'HTTP_$status');
  }

  static _Entry _fromStatus(int status) {
    if (status == 400 || status == 422) return (AppErrorKind.validation, ErrorMessages.validation, false);
    if (status == 401) return (AppErrorKind.unauthorized, ErrorMessages.sessionEnded, false);
    if (status == 403) return (AppErrorKind.forbidden, ErrorMessages.forbidden, false);
    if (status == 404) return (AppErrorKind.notFound, ErrorMessages.notFound, false);
    if (status == 409) return (AppErrorKind.conflict, ErrorMessages.conflict, true);
    if (status == 429) return (AppErrorKind.rateLimit, ErrorMessages.rateLimit, true);
    if (status == 504) return (AppErrorKind.timeout, ErrorMessages.timeout, true);
    if (status >= 500) return (AppErrorKind.server, ErrorMessages.server, true);
    return (AppErrorKind.unknown, ErrorMessages.unexpected, true);
  }

  /// Message for the `?error=` code that the auth service puts in the Google redirect.
  static String googleRedirectMessage(String? code) => switch (code) {
        'google_account_conflict' => ErrorMessages.googleConflict,
        'oauth_state_invalid' => ErrorMessages.googleState,
        _ => ErrorMessages.googleFailed,
      };
}
