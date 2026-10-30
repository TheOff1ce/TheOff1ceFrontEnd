import 'dart:developer' as developer;
import 'dart:math';

/// What went wrong, independent of which service produced it.
enum AppErrorKind {
  network,
  timeout,
  validation,
  invalidCredentials,
  invalidCode,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  rateLimit,
  server,
  invalidFile,
  unsupportedFile,
  unreadableAnalysis,
  invalidResponse,
  unknown,
}

/// The single error type the UI ever sees (FE-002). [userMessage] is already
/// human, in Spanish and actionable; [cause] is only for logs.
class AppError implements Exception {
  AppError({
    required this.kind,
    required this.userMessage,
    required this.retryable,
    this.code,
    this.cause,
    String? referenceId,
  }) : referenceId = referenceId ?? _newReferenceId();

  final AppErrorKind kind;
  final String userMessage;
  final bool retryable;

  /// Stable backend code (e.g. `CODE_INVALID`), used for decisions, never shown.
  final String? code;
  final Object? cause;

  /// Short id shown discreetly for support and attached to the log entry.
  final String referenceId;

  /// Whether the reference should be offered to the user (server/unknown faults).
  bool get showsReference =>
      kind == AppErrorKind.server ||
      kind == AppErrorKind.unknown ||
      kind == AppErrorKind.invalidResponse;

  /// The session is gone: only signing in again fixes it.
  bool get endsSession => kind == AppErrorKind.unauthorized;

  /// Transient failures that deserve an automatic retry with backoff.
  bool get isTransient =>
      kind == AppErrorKind.network ||
      kind == AppErrorKind.timeout ||
      kind == AppErrorKind.rateLimit ||
      kind == AppErrorKind.server ||
      kind == AppErrorKind.invalidResponse;

  static final Random _random = Random();
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String _newReferenceId() =>
      'FG-${List.generate(6, (_) => _alphabet[_random.nextInt(_alphabet.length)]).join()}';

  @override
  String toString() => 'AppError($kind, code: $code, ref: $referenceId)';
}

/// Technical log of every error shown to the user, without personal data.
abstract final class ErrorReporter {
  static void report(AppError error, [StackTrace? stackTrace]) {
    developer.log(
      '${error.kind.name} code=${error.code ?? '-'} ref=${error.referenceId}',
      name: 'farma_go.error',
      error: error.cause,
      stackTrace: stackTrace,
    );
  }

  static void reportUnexpected(Object error, StackTrace? stackTrace) {
    developer.log('unexpected', name: 'farma_go.error', error: error, stackTrace: stackTrace);
  }
}
