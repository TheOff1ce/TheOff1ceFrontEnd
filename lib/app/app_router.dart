import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/auth_controller.dart';
import '../pages/account_page.dart';
import '../pages/analysis_page.dart';
import '../pages/forgot_password_page.dart';
import '../pages/google_auth_callback_page.dart';
import '../pages/home_page.dart';
import '../pages/landing_page.dart';
import '../pages/login_page.dart';
import '../pages/notifications_page.dart';
import '../pages/register_page.dart';
import '../pages/reset_password_page.dart';
import '../pages/result_page.dart';
import '../pages/system_pages.dart';
import '../pages/upload_page.dart';
import '../pages/verify_email_page.dart';
import 'app_dependencies.dart';
import 'app_routes.dart';

/// Declarative routes and access rules (FE-010: extracted from the app widget).
class AppRouter {
  AppRouter(this._deps);

  final AppDependencies _deps;

  AuthController get _auth => _deps.auth;

  static const publicRoutes = {
    AppRoutes.landing,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
    AppRoutes.resetPassword,
    AppRoutes.googleCallback,
  };

  static const protectedRoutes = {
    AppRoutes.home,
    AppRoutes.uploadPrescription,
    AppRoutes.analyzingPrescription,
    AppRoutes.prescriptionResult,
    AppRoutes.notifications,
    AppRoutes.account,
  };

  late final GoRouter router = GoRouter(
    refreshListenable: _auth,
    redirect: redirect,
    routes: [..._legacyRoutes, ..._publicPages, ..._privatePages],
    errorBuilder: (context, state) => UnknownRoutePage(
      onHome: () => context.go(_auth.isAuthenticated ? AppRoutes.home : AppRoutes.landing),
    ),
  );

  /// Access rules. Signed-out users keep the place they wanted (FE-003).
  @visibleForTesting
  String? redirect(BuildContext context, GoRouterState state) {
    final path = state.uri.path;
    switch (_auth.status) {
      case AuthStatus.checking:
      case AuthStatus.unreachable:
        return null;
      case AuthStatus.verifying:
        return path == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;
      case AuthStatus.authenticated:
        if (publicRoutes.contains(path) || path == AppRoutes.verifyEmail) {
          return _auth.takeReturnTo() ?? AppRoutes.home;
        }
        return null;
      case AuthStatus.unauthenticated:
        return _signedOutRedirect(state);
    }
  }

  String? _signedOutRedirect(GoRouterState state) {
    final path = state.uri.path;
    if (protectedRoutes.contains(path)) {
      // The processing step needs the in-memory image, so it resumes at the upload step.
      _auth.rememberReturnTo(
        path == AppRoutes.analyzingPrescription ? AppRoutes.uploadPrescription : state.uri.toString(),
      );
      return AppRoutes.login;
    }
    if (path == AppRoutes.verifyEmail) return AppRoutes.login;
    final error = state.uri.queryParameters['error'];
    if (path == AppRoutes.login && error != null) {
      return Uri(path: AppRoutes.googleCallback, queryParameters: {'error': error}).toString();
    }
    if (path == AppRoutes.resetPassword && _deps.passwordReset.email == null) return AppRoutes.forgotPassword;
    return null;
  }

  /// Pages that need a known session state show loading or "unavailable" first.
  Widget _gate(Widget child) => ListenableBuilder(
        listenable: _auth,
        builder: (context, _) => switch (_auth.status) {
          AuthStatus.checking => const SessionLoadingPage(),
          AuthStatus.unreachable => SessionUnavailablePage(
              error: _auth.startupError,
              onRetry: _auth.restore,
              onContinue: _auth.continueSignedOut,
            ),
          _ => child,
        },
      );

  List<RouteBase> get _legacyRoutes => [
        GoRoute(
          path: LegacyRoutes.login,
          redirect: (context, state) {
            final error = state.uri.queryParameters['error'];
            return error == null
                ? AppRoutes.login
                : Uri(path: AppRoutes.googleCallback, queryParameters: {'error': error}).toString();
          },
        ),
        GoRoute(
          path: AppRoutes.oauthLanding,
          redirect: (context, state) =>
              Uri(path: AppRoutes.googleCallback, queryParameters: state.uri.queryParameters).toString(),
        ),
        for (final (legacy, current) in LegacyRoutes.mapping)
          GoRoute(path: legacy, redirect: (context, state) => current),
      ];

  List<RouteBase> get _publicPages => [
        GoRoute(
          path: AppRoutes.landing,
          builder: (context, state) => _gate(LandingPage(
            onLogin: () => context.push(AppRoutes.login),
            onRegister: () => context.push(AppRoutes.register),
          )),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => _gate(LoginPage(
            auth: _auth,
            onRegister: () => context.push(AppRoutes.register),
            onForgotPassword: () {
              _deps.passwordReset.restart();
              context.push(AppRoutes.forgotPassword);
            },
            onBack: () => AppRoutes.backOrGo(context, AppRoutes.landing),
          )),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => _gate(RegisterPage(
            auth: _auth,
            onLogin: () => context.push(AppRoutes.login),
            onBack: () => AppRoutes.backOrGo(context, AppRoutes.landing),
          )),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (context, state) => _gate(ForgotPasswordPage(
            reset: _deps.passwordReset,
            onSent: () => context.push(AppRoutes.resetPassword),
            onBack: () => AppRoutes.backOrGo(context, AppRoutes.login),
          )),
        ),
        GoRoute(
          path: AppRoutes.resetPassword,
          builder: (context, state) => _gate(ResetPasswordPage(
            reset: _deps.passwordReset,
            onLogin: () {
              _deps.passwordReset.restart();
              context.go(AppRoutes.login);
            },
            onBack: () => AppRoutes.backOrGo(context, AppRoutes.forgotPassword),
          )),
        ),
        GoRoute(
          path: AppRoutes.verifyEmail,
          builder: (context, state) => _gate(VerifyEmailPage(
            auth: _auth,
            onBack: () {
              _auth.cancelVerification();
              context.go(AppRoutes.login);
            },
          )),
        ),
        GoRoute(
          path: AppRoutes.googleCallback,
          builder: (context, state) =>
              GoogleAuthCallbackPage(auth: _auth, errorCode: state.uri.queryParameters['error']),
        ),
      ];

  List<RouteBase> get _privatePages => [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => _gate(HomePage(
            auth: _auth,
            notifications: _deps.notifications,
            onAnalyze: () => context.push(AppRoutes.uploadPrescription),
            onNotifications: () => context.push(AppRoutes.notifications),
            onAccount: () => context.push(AppRoutes.account),
          )),
        ),
        GoRoute(
          path: AppRoutes.uploadPrescription,
          builder: (context, state) => _gate(UploadPage(
            onBack: () => AppRoutes.backOrGo(context, AppRoutes.home),
            onAnalyze: (image) => context.push(AppRoutes.analyzingPrescription, extra: image),
          )),
        ),
        GoRoute(
          path: AppRoutes.analyzingPrescription,
          builder: (context, state) {
            final image = state.extra;
            if (image is! XFile) {
              return _gate(MissingAnalysisStepPage(onBack: () => context.go(AppRoutes.uploadPrescription)));
            }
            return _gate(AnalysisPage(
              controller: _deps.prescriptions,
              image: image,
              onBack: () => AppRoutes.backOrGo(context, AppRoutes.uploadPrescription),
              onComplete: () {
                final result = _deps.prescriptions.result;
                if (result != null) {
                  _deps.notifications.addAnalysisCompleted(medicationCount: result.medications.length);
                }
                context.go(AppRoutes.prescriptionResult);
              },
            ));
          },
        ),
        GoRoute(
          path: AppRoutes.prescriptionResult,
          builder: (context, state) {
            final result = _deps.prescriptions.result;
            if (result == null) {
              return _gate(MissingAnalysisStepPage(onBack: () => context.go(AppRoutes.uploadPrescription)));
            }
            return _gate(ResultPage(
              result: result,
              onHome: () => context.go(AppRoutes.home),
              onAnalyzeAnother: () {
                _deps.prescriptions.reset();
                context.go(AppRoutes.uploadPrescription);
              },
            ));
          },
        ),
        GoRoute(
          path: AppRoutes.notifications,
          builder: (context, state) => _gate(NotificationsPage(
            notifications: _deps.notifications,
            onBack: () => AppRoutes.backOrGo(context, AppRoutes.home),
          )),
        ),
        GoRoute(
          path: AppRoutes.account,
          builder: (context, state) => _gate(AccountPage(
            auth: _auth,
            onBack: () => AppRoutes.backOrGo(context, AppRoutes.home),
          )),
        ),
      ];

  void dispose() => router.dispose();
}
