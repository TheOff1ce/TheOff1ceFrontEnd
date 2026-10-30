import 'package:flutter/foundation.dart';

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../errors/error_messages.dart';
import 'auth_repository.dart';

enum ResetStep { requestEmail, enterCode, choosePassword, done }

/// Password recovery flow, separate from the session (FE-010).
class PasswordResetController extends ChangeNotifier {
  PasswordResetController(this._repository);

  final AuthRepository _repository;

  ResetStep step = ResetStep.requestEmail;
  String? email;
  String? _verifiedCode;

  Future<AppError?> requestCode(String value) => _run(() async {
        await _repository.requestPasswordReset(value);
        email = value;
        _verifiedCode = null;
        _go(ResetStep.enterCode);
      });

  Future<AppError?> resendCode() async {
    final current = email;
    if (current == null) return null;
    return _run(() => _repository.requestPasswordReset(current));
  }

  Future<AppError?> verifyCode(String code) async {
    final current = email;
    if (current == null) return null;
    return _run(() async {
      await _repository.verifyPasswordResetCode(email: current, code: code);
      _verifiedCode = code;
      _go(ResetStep.choosePassword);
    });
  }

  /// FE-016: an expired code sends the user back to the code step with an explanation.
  Future<AppError?> resetPassword(String newPassword) async {
    final current = email;
    final code = _verifiedCode;
    if (current == null || code == null) {
      _go(ResetStep.enterCode);
      return null;
    }
    final error = await _run(() async {
      await _repository.resetPassword(email: current, code: code, newPassword: newPassword);
      _verifiedCode = null;
      _go(ResetStep.done);
    });
    if (error?.kind != AppErrorKind.invalidCode) return error;
    _verifiedCode = null;
    _go(ResetStep.enterCode);
    return AppError(
      kind: AppErrorKind.invalidCode,
      userMessage: ErrorMessages.resetCodeExpired,
      retryable: false,
      code: error!.code,
      referenceId: error.referenceId,
    );
  }

  void backToCode() {
    _verifiedCode = null;
    _go(ResetStep.enterCode);
  }

  void restart() {
    email = null;
    _verifiedCode = null;
    _go(ResetStep.requestEmail);
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  void _go(ResetStep next) {
    step = next;
    notifyListeners();
  }

  Future<AppError?> _run(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on AppError catch (error) {
      ErrorReporter.report(error);
      return error;
    } catch (error, stackTrace) {
      ErrorReporter.reportUnexpected(error, stackTrace);
      return ErrorMapper.fromException(error);
    }
  }
}
