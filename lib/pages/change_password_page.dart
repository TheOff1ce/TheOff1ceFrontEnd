import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../app/theme/app_theme.dart';
import '../components/auth_ui.dart';
import '../components/feedback.dart';
import '../errors/app_error.dart';
import '../utils/validators.dart';

/// HU-039: change the password while signed in (current password + new one twice).
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, required this.auth, required this.onBack, required this.onDone});

  final AuthController auth;
  final VoidCallback onBack;
  final VoidCallback onDone;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _currentFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmationFocus = FocusNode();
  bool _busy = false;
  AppError? _error;

  @override
  void dispose() {
    for (final c in [_current, _password, _confirmation]) {
      c.dispose();
    }
    for (final f in [_currentFocus, _passwordFocus, _confirmationFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  static String? currentValidator(String? value) =>
      value == null || value.isEmpty ? 'Escribe tu contraseña actual.' : null;

  String? _newValidator(String? value) {
    final basic = Validators.password(value);
    if (basic != null) return basic;
    if (value!.length > 128) return 'La contraseña puede tener máximo 128 caracteres.';
    if (value == _current.text) return 'La contraseña nueva debe ser distinta de la actual.';
    return null;
  }

  String? _confirmationValidator(String? value) => Validators.confirmation(() => _password.text)(value);

  Future<void> _submit() async {
    if (_busy) return;
    if (!_form.currentState!.validate()) {
      focusFirstInvalid([
        (_currentFocus, () => currentValidator(_current.text)),
        (_passwordFocus, () => _newValidator(_password.text)),
        (_confirmationFocus, () => _confirmationValidator(_confirmation.text)),
      ]);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.auth.changePassword(currentPassword: _current.text, newPassword: _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) {
      showAppSnackBar(context, 'Contraseña actualizada. Cerramos tu sesión en los demás dispositivos.');
      widget.onDone();
    } else if (error.code == 'CURRENT_PASSWORD_INVALID') {
      _current.clear();
      _currentFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) => AuthShell(
        onBack: widget.onBack,
        title: 'Cambia tu contraseña.',
        subtitle: 'Escribe tu contraseña actual y elige una nueva. Se cerrará tu sesión en los demás dispositivos.',
        child: AutofillGroup(
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ErrorBanner(error: _error),
              PasswordField(
                controller: _current,
                focusNode: _currentFocus,
                label: 'Contraseña actual',
                validator: currentValidator,
              ),
              const SizedBox(height: AppSpacing.m),
              PasswordField(
                controller: _password,
                focusNode: _passwordFocus,
                label: 'Contraseña nueva',
                helperText: 'Mínimo ${Validators.minPasswordLength} caracteres.',
                isNew: true,
                validator: _newValidator,
              ),
              const SizedBox(height: AppSpacing.m),
              PasswordField(
                controller: _confirmation,
                focusNode: _confirmationFocus,
                label: 'Confirma la contraseña nueva',
                isNew: true,
                validator: _confirmationValidator,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xl),
              BusyButton(label: 'Cambiar contraseña', busyLabel: 'Cambiando contraseña', busy: _busy, onPressed: _submit),
            ]),
          ),
        ),
      );
}
