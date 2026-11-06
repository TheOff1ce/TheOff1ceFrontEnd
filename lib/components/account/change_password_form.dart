import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';
import '../../auth/auth_controller.dart';
import '../../errors/app_error.dart';
import '../../utils/validators.dart';
import '../farmago/buttons.dart';
import '../farmago/feedback.dart';
import '../farmago/inputs.dart';

/// HU-005 / HU-039: cambio de contraseña dentro de "Mi cuenta".
///
/// Pide la contraseña actual y la nueva dos veces. Valida antes de llamar al servicio y, si la
/// actual no coincide, marca ese campo (no un aviso genérico).
class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({super.key, required this.auth, required this.onDone, required this.onCancel});

  final AuthController auth;
  final VoidCallback onDone;
  final VoidCallback onCancel;

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  static const maxLength = 128;

  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _currentFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmationFocus = FocusNode();

  String? _currentError, _passwordError, _confirmationError;
  AppError? _serviceError;
  bool _busy = false;

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

  bool _validate() {
    final current = _current.text;
    final next = _password.text;
    setState(() {
      _currentError = current.isEmpty ? 'Escribe tu contraseña actual.' : null;
      _passwordError = Validators.password(next) ??
          (next.length > maxLength
              ? 'La contraseña puede tener máximo $maxLength caracteres.'
              : next == current && current.isNotEmpty
                  ? 'La contraseña nueva debe ser distinta de la actual.'
                  : null);
      _confirmationError = Validators.confirmation(() => next)(_confirmation.text);
    });
    final firstInvalid = _currentError != null
        ? _currentFocus
        : _passwordError != null
            ? _passwordFocus
            : _confirmationError != null
                ? _confirmationFocus
                : null;
    firstInvalid?.requestFocus();
    return firstInvalid == null;
  }

  Future<void> _submit() async {
    if (_busy || !_validate()) return;
    setState(() {
      _busy = true;
      _serviceError = null;
    });
    final error = await widget.auth.changePassword(currentPassword: _current.text, newPassword: _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      widget.onDone();
      return;
    }
    if (error.code == 'CURRENT_PASSWORD_INVALID') {
      setState(() => _currentError = error.userMessage);
      _current.clear();
      _currentFocus.requestFocus();
    } else if (error.code == 'PASSWORD_UNCHANGED') {
      setState(() => _passwordError = error.userMessage);
      _passwordFocus.requestFocus();
    } else {
      setState(() => _serviceError = error);
    }
  }

  @override
  Widget build(BuildContext context) => AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_serviceError != null) ...[
              FgBanner(
                kind: FgBannerKind.error,
                message: _serviceError!.userMessage,
                referencia: _serviceError!.referenceId,
              ),
              const SizedBox(height: FgSpace.sp4),
            ],
            FgTextField(
              label: 'Contraseña actual',
              controller: _current,
              focusNode: _currentFocus,
              contrasena: true,
              error: _currentError,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: FgSpace.sp4),
            FgTextField(
              label: 'Contraseña nueva',
              controller: _password,
              focusNode: _passwordFocus,
              contrasena: true,
              error: _passwordError,
              ayuda: 'Mínimo ${Validators.minPasswordLength} caracteres.',
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _confirmationFocus.requestFocus(),
            ),
            const SizedBox(height: FgSpace.sp4),
            FgTextField(
              label: 'Repite la contraseña nueva',
              controller: _confirmation,
              focusNode: _confirmationFocus,
              contrasena: true,
              error: _confirmationError,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: FgSpace.sp5),
            Wrap(
              spacing: FgSpace.sp3,
              runSpacing: FgSpace.sp3,
              children: [
                FgButton(
                  label: 'Guardar contraseña',
                  loadingLabel: 'Guardando…',
                  loading: _busy,
                  onPressed: _submit,
                ),
                FgButton(
                  label: 'Cancelar',
                  variant: FgButtonVariant.ghost,
                  onPressed: _busy ? null : widget.onCancel,
                ),
              ],
            ),
          ],
        ),
      );
}
