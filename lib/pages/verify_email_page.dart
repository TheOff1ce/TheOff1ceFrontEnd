import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../components/auth_ui.dart';
import '../components/feedback.dart';
import '../errors/app_error.dart';
import '../utils/validators.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key, required this.auth, required this.onBack});

  final AuthController auth;
  final VoidCallback onBack;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _code = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  AppError? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  bool get _complete => Validators.isCode(_code.text);

  Future<void> _verify() async {
    if (!_complete || _verifying) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    final error = await widget.auth.verify(_code.text);
    if (!mounted) return;
    setState(() {
      _verifying = false;
      _error = error;
    });
  }

  /// FE-014: success is only confirmed when the request really succeeded.
  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
    });
    final error = await widget.auth.resend();
    if (!mounted) return;
    setState(() {
      _resending = false;
      _error = error;
    });
    if (error == null) {
      _code.clear();
      showAppSnackBar(context, 'Si tu inicio de sesión sigue pendiente, te enviamos un código nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _verifying || _resending;
    return AuthShell(
      onBack: widget.onBack,
      title: 'Confirma tu correo.',
      subtitle: 'Escribe el código de seis dígitos que enviamos a ${maskEmail(widget.auth.pendingEmail)}. '
          'Vence en 5 minutos.',
      child: AutofillGroup(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ErrorBanner(error: _error),
          CodeField(
            controller: _code,
            label: 'Código de verificación',
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _verify(),
          ),
          const SizedBox(height: AppSpacing.l),
          BusyButton(
            label: 'Verificar código',
            busyLabel: 'Verificando código',
            busy: _verifying,
            onPressed: _complete && !_resending ? _verify : null,
          ),
          const SizedBox(height: AppSpacing.m),
          TextButton(
            onPressed: busy ? null : _resend,
            child: Text(_resending ? 'Enviando código…' : 'Reenviar código'),
          ),
        ]),
      ),
    );
  }
}
