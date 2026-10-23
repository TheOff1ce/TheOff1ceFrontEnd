import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../components/auth_ui.dart';
import '../components/feedback.dart';
import '../errors/app_error.dart';
import '../utils/validators.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.auth, required this.onLogin, required this.onBack});

  final AuthController auth;
  final VoidCallback onLogin, onBack;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmationFocus = FocusNode();
  bool _submitting = false;
  AppError? _error;

  @override
  void dispose() {
    for (final controller in [_name, _email, _password, _confirmation]) {
      controller.dispose();
    }
    for (final node in [_nameFocus, _emailFocus, _passwordFocus, _confirmationFocus]) {
      node.dispose();
    }
    super.dispose();
  }

  String? _confirmationError(String? value) => Validators.confirmation(() => _password.text)(value);

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_form.currentState!.validate()) {
      focusFirstInvalid([
        (_nameFocus, () => Validators.name(_name.text)),
        (_emailFocus, () => Validators.email(_email.text)),
        (_passwordFocus, () => Validators.password(_password.text)),
        (_confirmationFocus, () => _confirmationError(_confirmation.text)),
      ]);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await widget.auth.signUp(
      name: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = error;
    });
    if (error?.kind == AppErrorKind.conflict) _emailFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) => AuthShell(
        onBack: widget.onBack,
        title: 'Crea tu espacio de salud.',
        subtitle: 'Te enviaremos un código al correo para proteger tu cuenta. Todos los campos son obligatorios.',
        child: AutofillGroup(
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ErrorBanner(error: _error),
              TextFormField(
                controller: _name,
                focusNode: _nameFocus,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUnfocus,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                validator: Validators.name,
              ),
              const SizedBox(height: AppSpacing.m + 2),
              TextFormField(
                controller: _email,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUnfocus,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
                validator: Validators.email,
              ),
              const SizedBox(height: AppSpacing.m + 2),
              PasswordField(
                controller: _password,
                focusNode: _passwordFocus,
                label: 'Contraseña',
                isNew: true,
                validator: Validators.password,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.s + 2),
              PasswordChecklist(password: _password.text),
              const SizedBox(height: AppSpacing.m + 2),
              PasswordField(
                controller: _confirmation,
                focusNode: _confirmationFocus,
                label: 'Confirma tu contraseña',
                isNew: true,
                validator: _confirmationError,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xl - 2),
              BusyButton(label: 'Crear cuenta', busyLabel: 'Creando tu cuenta', busy: _submitting, onPressed: _submit),
              const SizedBox(height: AppSpacing.l),
              TextButton(onPressed: _submitting ? null : widget.onLogin, child: const Text('Ya tengo una cuenta')),
            ]),
          ),
        ),
      );
}
