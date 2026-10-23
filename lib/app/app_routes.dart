import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Centralized, human-readable locations used by the application.
///
/// Keeping these paths in one place prevents links from drifting away from the
/// screens they describe and makes browser navigation predictable on web.
abstract final class AppRoutes {
  static const landing = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const verifyEmail = '/verify-email';
  static const googleCallback = '/auth/google/callback';

  /// Where TheOff1ceAuth redirects after Google sign-in (`FRONTEND_URL/auth/callback`).
  static const oauthLanding = '/auth/callback';

  static const home = '/home';
  static const uploadPrescription = '/analyze-prescription';
  static const analyzingPrescription = '/analyze-prescription/processing';
  static const prescriptionResult = '/analyze-prescription/result';
  static const notifications = '/notifications';
  static const account = '/account';

  static void backOrGo(BuildContext context, String fallback) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(fallback);
    }
  }
}

/// Previous public URLs are redirected so saved links continue to work.
abstract final class LegacyRoutes {
  static const login = '/acceso';
  static const register = '/registro';
  static const forgotPassword = '/recuperar-contrasena';
  static const resetPassword = '/restablecer-contrasena';
  static const verifyEmail = '/verificar-correo';
  static const home = '/inicio';
  static const uploadPrescription = '/analizar-formula';
  static const analyzingPrescription = '/analizar-formula/procesando';
  static const prescriptionResult = '/analizar-formula/resultado';
  static const notifications = '/notificaciones';
  static const account = '/cuenta';

  /// Legacy path → current path (the login redirect is special: it keeps `?error`).
  static const mapping = [
    (register, AppRoutes.register),
    (forgotPassword, AppRoutes.forgotPassword),
    (resetPassword, AppRoutes.resetPassword),
    (verifyEmail, AppRoutes.verifyEmail),
    (home, AppRoutes.home),
    (uploadPrescription, AppRoutes.uploadPrescription),
    (analyzingPrescription, AppRoutes.analyzingPrescription),
    (prescriptionResult, AppRoutes.prescriptionResult),
    (account, AppRoutes.account),
    (notifications, AppRoutes.notifications),
  ];
}
