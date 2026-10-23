import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../services/access_token_source.dart';
import '../types/auth_models.dart';
import 'auth_repository.dart';

enum AuthStatus { checking, unreachable, unauthenticated, verifying, authenticated }

/// Owns the session: sign-in steps, silent refresh and sign-out.
///
/// Refresh is resilient (FE-003): only a rejected session (401) ends it;
/// network failures, 429 and 5xx keep the user signed in and retry with
/// backoff while a banner explains the situation.
class AuthController extends ChangeNotifier implements AccessTokenSource {
  AuthController(
    this._repository, {
    List<Duration>? retryDelays,
    this.refreshMargin = const Duration(seconds: 30),
  }) : _retryDelays = retryDelays ?? _defaultRetryDelays;

  static const _defaultRetryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(seconds: 60),
  ];
  static const _minimumRefreshDelay = Duration(seconds: 5);

  final AuthRepository _repository;
  final List<Duration> _retryDelays;
  final Duration refreshMargin;

  AuthStatus status = AuthStatus.checking;
  AuthUser? user;
  String? pendingEmail;

  /// True while the silent refresh is failing for transient reasons.
  bool connectionIssue = false;

  /// Why the user was sent back to the login screen (e.g. session ended).
  AppError? sessionNotice;

  /// Why the session could not be checked at start-up.
  AppError? startupError;

  String? _accessToken;
  DateTime? _accessTokenExpiresAt;
  String? _returnTo;
  Timer? _refreshTimer;
  Future<void>? _refreshing;
  int _retryAttempt = 0;
  bool _disposed = false;

  /// Access token kept only in memory, for future authenticated calls.
  String? get accessToken => _accessToken;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  @override
  Future<String?> currentAccessToken({bool forceRefresh = false}) async {
    if (!isAuthenticated) return null;
    final expiresAt = _accessTokenExpiresAt;
    final nearExpiry = expiresAt == null || DateTime.now().isAfter(expiresAt.subtract(refreshMargin));
    if (forceRefresh || nearExpiry) await refreshNow();
    return isAuthenticated ? _accessToken : null;
  }

  Future<void> restore() async {
    _setStatus(AuthStatus.checking);
    startupError = null;
    await _repository.restoreStoredRefresh();
    try {
      await _acceptSession(await _repository.refresh());
    } on AppError catch (error) {
      if (error.isTransient) {
        ErrorReporter.report(error);
        startupError = error;
        _setStatus(AuthStatus.unreachable);
      } else {
        await _repository.discardLocalSession();
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (error, stackTrace) {
      ErrorReporter.reportUnexpected(error, stackTrace);
      startupError = ErrorMapper.fromException(error);
      _setStatus(AuthStatus.unreachable);
    }
  }

  /// Continue without a verified session after start-up failed (public pages only).
  void continueSignedOut() => _setStatus(AuthStatus.unauthenticated);

  Future<AppError?> signUp({required String name, required String email, required String password}) =>
      _run(() async {
        await _repository.signUp(name: name, email: email, password: password);
        _startVerification(email);
      });

  Future<AppError?> login({required String email, required String password}) => _run(() async {
        await _repository.login(email: email, password: password);
        _startVerification(email);
      });

  Future<AppError?> verify(String code) async {
    final email = pendingEmail;
    if (email == null) return null;
    return _run(() async => _acceptSession(await _repository.verifyCode(email: email, code: code)));
  }

  Future<AppError?> resend() async {
    final email = pendingEmail;
    if (email == null) return null;
    return _run(() => _repository.resendCode(email));
  }

  void cancelVerification() {
    pendingEmail = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  /// Signs out locally even when the server cannot be reached.
  Future<void> logout() async {
    _refreshTimer?.cancel();
    try {
      await _repository.logout();
    } on AppError catch (error) {
      ErrorReporter.report(error);
    } finally {
      _clearSession();
      sessionNotice = null;
      _returnTo = null;
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// Single-flight refresh, used by the timer and by retries.
  Future<void> refreshNow() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  void showNotice(AppError notice) {
    sessionNotice = notice;
    _notify();
  }

  void clearNotice() => sessionNotice = null;

  /// Remembers where a signed-out user wanted to go (no rebuild).
  void rememberReturnTo(String location) => _returnTo = location;

  String? takeReturnTo() {
    final location = _returnTo;
    _returnTo = null;
    return location;
  }

  Future<void> _refresh() async {
    try {
      await _acceptSession(await _repository.refresh());
    } on AppError catch (error) {
      ErrorReporter.report(error);
      if (error.isTransient) {
        _scheduleRetry();
      } else {
        await _endSession(error);
      }
    } catch (error, stackTrace) {
      ErrorReporter.reportUnexpected(error, stackTrace);
      _scheduleRetry();
    }
  }

  Future<void> _acceptSession(AuthSession session) async {
    if (!session.isValid) throw ErrorMapper.fromException(const FormatException('Invalid session payload'));
    final profile = await _repository.me(session.accessToken);
    if (!profile.isValid) throw ErrorMapper.fromException(const FormatException('Invalid profile payload'));
    _accessToken = session.accessToken;
    _accessTokenExpiresAt = DateTime.now().add(session.lifetime);
    user = profile;
    pendingEmail = null;
    connectionIssue = false;
    sessionNotice = null;
    _retryAttempt = 0;
    _scheduleRefresh(session.lifetime);
    _setStatus(AuthStatus.authenticated);
  }

  void _scheduleRefresh(Duration lifetime) {
    final wait = lifetime - refreshMargin;
    _restartTimer(wait < _minimumRefreshDelay ? _minimumRefreshDelay : wait);
  }

  void _scheduleRetry() {
    final delay = _retryDelays[min(_retryAttempt, _retryDelays.length - 1)];
    _retryAttempt++;
    connectionIssue = true;
    _restartTimer(delay);
    _notify();
  }

  void _restartTimer(Duration delay) {
    _refreshTimer?.cancel();
    if (_disposed) return;
    _refreshTimer = Timer(delay, () => refreshNow());
  }

  Future<void> _endSession(AppError reason) async {
    await _repository.discardLocalSession();
    _clearSession();
    sessionNotice = reason;
    _setStatus(AuthStatus.unauthenticated);
  }

  void _clearSession() {
    _refreshTimer?.cancel();
    _accessToken = null;
    _accessTokenExpiresAt = null;
    user = null;
    pendingEmail = null;
    connectionIssue = false;
    _retryAttempt = 0;
  }

  void _startVerification(String email) {
    pendingEmail = email;
    _setStatus(AuthStatus.verifying);
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

  void _setStatus(AuthStatus next) {
    status = next;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _refreshTimer?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
