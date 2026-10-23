import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_routes.dart';
import '../app/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../errors/app_error.dart';
import '../errors/error_mapper.dart';

/// Receives the OAuth redirect once and replaces its technical URL afterwards.
class GoogleAuthCallbackPage extends StatefulWidget {
  const GoogleAuthCallbackPage({super.key, required this.auth, this.errorCode});

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
    final status = widget.auth.status;
    if (!mounted || _redirecting || status == AuthStatus.checking || status == AuthStatus.unreachable) return;
    if (status == AuthStatus.authenticated && widget.errorCode == null) return; // the router takes over
    _redirecting = true;
    widget.auth.showNotice(AppError(
      kind: AppErrorKind.unauthorized,
      userMessage: ErrorMapper.googleRedirectMessage(widget.errorCode),
      retryable: true,
      code: widget.errorCode ?? 'google_session_missing',
    ));
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Semantics(
            liveRegion: true,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(semanticsLabel: 'Comprobando tu acceso'),
              ),
              const SizedBox(height: AppSpacing.l),
              Text('Comprobando tu acceso…', style: context.text.headlineSmall),
            ]),
          ),
        ),
      );
}
