import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../auth/password_reset_controller.dart';
import '../components/auth_ui.dart';
import '../components/feedback.dart';
import '../errors/app_error.dart';
import '../utils/validators.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.reset, required this.onSent, required this.onBack});

  final PasswordResetController reset;
  final VoidCallback onSent;
  final VoidCallback onBack;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _emailFocus = FocusNode();
  bool _submitting = false;
  AppError? _error;

  @override
  void initState() {
    super.initState();
    _email.text = widget.reset.email ?? '';
  }

  @override
  void dispose() {
    _email.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_form.currentState!.validate()) {
      _emailFocus.requestFocus();
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await widget.reset.requestCode(_email.text.trim());
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = error;
    });
    if (error == null) widget.onSent();
  }

  @override
  Widget build(BuildContext context) => AuthShell(
        onBack: widget.onBack,
        title: 'Recupera tu acceso.',
        subtitle: 'Te enviaremos un código al correo si corresponde a una cuenta con contraseña.',
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ErrorBanner(error: _error),
            TextFormField(
              controller: _email,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autovalidateMode: AutovalidateMode.onUnfocus,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Correo electrónico'),
              validator: Validators.email,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xl - 2),
            BusyButton(label: 'Enviar código', busyLabel: 'Enviando código', busy: _submitting, onPressed: _submit),
          ]),
        ),
      );
}
