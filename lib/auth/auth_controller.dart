import 'dart:async';
import 'package:flutter/foundation.dart';
import 'auth_models.dart';
import 'auth_repository.dart';

enum AuthStatus { checking, unauthenticated, verifying, authenticated }

class AuthController extends ChangeNotifier {
  AuthController(this._repository);
  final AuthRepository _repository;
  AuthStatus status = AuthStatus.checking;
  AuthUser? user;
  String? pendingEmail;
  String? resetEmail;
  String? _verifiedResetCode;
  String? error;
  bool loading = false;
  Timer? _refreshTimer;

  Future<void> restore() async {
    await _repository.restoreNativeRefresh();
    try {
      await _acceptSession(await _repository.refresh());
    } on AuthFailure {
      status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> signUp(
      {required String name,
      required String email,
      required String password}) async {
    return _run(() async {
      await _repository.signUp(name: name, email: email, password: password);
      pendingEmail = email;
      status = AuthStatus.verifying;
    });
  }

  Future<bool> login({required String email, required String password}) async {
    return _run(() async {
      await _repository.login(email: email, password: password);
      pendingEmail = email;
      status = AuthStatus.verifying;
    });
  }

  Future<bool> verify(String code) async {
    if (pendingEmail == null) {
      return false;
    }
    return _run(() async => _acceptSession(
        await _repository.verifyCode(email: pendingEmail!, code: code)));
  }

  Future<bool> resend() async {
    if (pendingEmail == null) {
      return false;
    }
    return _run(() async {
      await _repository.resendCode(pendingEmail!);
    });
  }

  Future<bool> requestPasswordReset(String email) async {
    return _run(() async {
      await _repository.requestPasswordReset(email);
      resetEmail = email;
    });
  }

  Future<bool> resetPassword({
    required String newPassword,
  }) async {
    if (resetEmail == null || _verifiedResetCode == null) {
      return false;
    }
    return _run(() async {
      await _repository.resetPassword(
        email: resetEmail!,
        code: _verifiedResetCode!,
        newPassword: newPassword,
      );
      _verifiedResetCode = null;
    });
  }

  Future<bool> verifyPasswordResetCode(String code) async {
    if (resetEmail == null) {
      return false;
    }
    return _run(() async {
      await _repository.verifyPasswordResetCode(email: resetEmail!, code: code);
      _verifiedResetCode = code;
    });
  }

  Future<void> logout() async {
    _refreshTimer?.cancel();
    loading = true;
    error = null;
    notifyListeners();
    await _repository.logout();
    user = null;
    pendingEmail = null;
    resetEmail = null;
    _verifiedResetCode = null;
    status = AuthStatus.unauthenticated;
    loading = false;
    notifyListeners();
  }

  void backToPublic() {
    error = null;
    pendingEmail = null;
    resetEmail = null;
    _verifiedResetCode = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void showPublicError(String message) {
    error = message;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AuthFailure catch (e) {
      error = e.message;
      return false;
    } catch (_) {
      error = 'No pudimos completar la acción. Inténtalo otra vez.';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _acceptSession(AuthSession session) async {
    if (session.accessToken.isEmpty || session.expiresIn <= 0) {
      throw const AuthFailure('La sesión recibida no es válida.');
    }
    user = await _repository.me(session.accessToken);
    status = AuthStatus.authenticated;
    _refreshTimer?.cancel();
    _refreshTimer = Timer(
        Duration(seconds: (session.expiresIn - 15).clamp(1, session.expiresIn)),
        () async {
      try {
        await _acceptSession(await _repository.refresh());
        notifyListeners();
      } on AuthFailure {
        await logout();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
