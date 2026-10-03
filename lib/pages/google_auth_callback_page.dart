import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_routes.dart';
import '../app/theme/app_theme.dart';
import '../auth/auth_controller.dart';

/// Receives the OAuth redirect once and removes its technical URL afterwards.
class GoogleAuthCallbackPage extends StatefulWidget {
  const GoogleAuthCallbackPage({
    super.key,
    required this.auth,
    this.errorCode,
  });

  final AuthController auth;
  final String? errorCode;

  @override
  State<GoogleAuthCallbackPage> createState() => _GoogleAuthCallbackPageState();
}

class _GoogleAuthCallbackPageState extends State<GoogleAuthCallbackPage> {
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_continueFlow);
    WidgetsBinding.instance.addPostFrameCallback((_) => _continueFlow());
  }

  @override
  void dispose() {
    widget.auth.removeListener(_continueFlow);
    super.dispose();
  }

  void _continueFlow() {
    if (!mounted || _redirecting || widget.auth.status == AuthStatus.checking) {
      return;
    }
    if (widget.auth.status == AuthStatus.authenticated) return;

    _redirecting = true;
    widget.auth.showPublicError(_messageFor(widget.errorCode));
    context.go(AppRoutes.login);
  }

  String _messageFor(String? errorCode) {
    switch (errorCode) {
      case 'google_account_conflict':
        return 'Ya existe una cuenta con este correo. Inicia sesión con tu contraseña.';
      case 'oauth_state_invalid':
        return 'No pudimos validar el inicio con Google. Inténtalo de nuevo.';
      case 'google_auth_failed':
        return 'No pudimos validar tu cuenta de Google. Revisa la configuración e inténtalo de nuevo.';
      default:
        return 'No pudimos completar el inicio con Google. Inténtalo de nuevo.';
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 42, height: 42, child: CircularProgressIndicator()),
            SizedBox(height: 18),
            Text('Comprobando tu acceso...', style: AppText.heading),
          ]),
        ),
      );
}
