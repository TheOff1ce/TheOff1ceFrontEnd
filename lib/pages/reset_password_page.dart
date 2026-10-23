import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../auth/password_reset_controller.dart';
import '../components/auth_ui.dart';
import '../components/feedback.dart';
import '../errors/app_error.dart';
import '../utils/validators.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.reset, required this.onLogin, required this.onBack});

  final PasswordResetController reset;
  final VoidCallback onLogin;
  final VoidCallback onBack;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmationFocus = FocusNode();
  bool _busy = false;
  AppError? _error;

  PasswordResetController get _reset => widget.reset;

  @override
  void dispose() {
    for (final controller in [_code, _password, _confirmation]) {
      controller.dispose();
    }
    _passwordFocus.dispose();
    _confirmationFocus.dispose();
    super.dispose();
  }

  Future<void> _guard(Future<AppError?> Function() action, {VoidCallback? onSuccess}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) onSuccess?.call();
  }

  void _verifyCode() {
    if (!Validators.isCode(_code.text)) return;
    _guard(() => _reset.verifyCode(_code.text));
  }

  void _resendCode() => _guard(_reset.resendCode, onSuccess: () {
        _code.clear();
        showAppSnackBar(context, 'Te enviamos un código nuevo. Revisa tu correo.');
      });

  String? _confirmationError(String? value) => Validators.confirmation(() => _password.text)(value);

  void _submitPassword() {
    if (!_form.currentState!.validate()) {
      focusFirstInvalid([
        (_passwordFocus, () => Validators.password(_password.text)),
        (_confirmationFocus, () => _confirmationError(_confirmation.text)),
      ]);
      return;
    }
    _guard(() => _reset.resetPassword(_password.text), onSuccess: () {
      _password.clear();
      _confirmation.clear();
    }).then((_) {
      // FE-016: an expired code returns to the code step with a clean field.
      if (mounted && _reset.step == ResetStep.enterCode) _code.clear();
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _reset,
        builder: (context, _) {
          final (title, subtitle) = switch (_reset.step) {
            ResetStep.done => ('Contraseña actualizada.', 'Tus sesiones anteriores se cerraron. Inicia sesión con tu nueva contraseña.'),
            ResetStep.choosePassword => ('Elige una contraseña nueva.', 'Crea una contraseña segura para volver a ingresar.'),
            _ => ('Confirma tu código.', 'Escribe el código de seis dígitos que enviamos a ${maskEmail(_reset.email)}. Vence en 5 minutos.'),
          };
          return AuthShell(
            onBack: widget.onBack,
            title: title,
            subtitle: subtitle,
            child: switch (_reset.step) {
              ResetStep.done => FilledButton(onPressed: widget.onLogin, child: const Text('Ir a iniciar sesión')),
              ResetStep.choosePassword => _passwordStep(),
              _ => _codeStep(),
            },
          );
        },
      );

  Widget _codeStep() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ErrorBanner(error: _error),
        CodeField(
          controller: _code,
          label: 'Código de recuperación',
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _verifyCode(),
        ),
        const SizedBox(height: AppSpacing.l),
        BusyButton(
          label: 'Verificar código',
          busyLabel: 'Verificando código',
          busy: _busy,
          onPressed: Validators.isCode(_code.text) ? _verifyCode : null,
        ),
        const SizedBox(height: AppSpacing.s),
        TextButton(onPressed: _busy ? null : _resendCode, child: const Text('Reenviar código')),
      ]);

  Widget _passwordStep() => AutofillGroup(
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ErrorBanner(error: _error),
            PasswordField(
              controller: _password,
              focusNode: _passwordFocus,
              label: 'Nueva contraseña',
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
              label: 'Confirma la contraseña',
              isNew: true,
              validator: _confirmationError,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitPassword(),
            ),
            const SizedBox(height: AppSpacing.xl - 2),
            BusyButton(
              label: 'Restablecer contraseña',
              busyLabel: 'Guardando contraseña',
              busy: _busy,
              onPressed: _submitPassword,
            ),
            const SizedBox(height: AppSpacing.s),
            TextButton(
              onPressed: _busy ? null : _reset.backToCode,
              child: const Text('Usar otro código'),
            ),
          ]),
        ),
      );
}
