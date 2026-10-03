import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../components/auth_ui.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
    super.key,
    required this.auth,
    required this.onSent,
    required this.onBack,
  });
  final AuthController auth;
  final VoidCallback onSent;
  final VoidCallback onBack;
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final sent = await widget.auth.requestPasswordReset(_email.text.trim());
    if (sent && mounted) widget.onSent();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.auth,
        builder: (_, __) => AuthShell(
          onBack: widget.onBack,
          title: 'Recupera tu acceso.',
          subtitle:
              'Te enviaremos un código al correo si corresponde a una cuenta local.',
          child: Form(
            key: _form,
            child: Column(
              children: [
                FormError(message: widget.auth.error),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration:
                      const InputDecoration(labelText: 'Correo electrónico'),
                  validator: _emailValidator,
                ),
                const SizedBox(height: 22),
                BusyButton(
                    label: 'Enviar código',
                    busy: widget.auth.loading,
                    onPressed: _submit),
              ],
            ),
          ),
        ),
      );
}

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({
    super.key,
    required this.auth,
    required this.onLogin,
    required this.onBack,
  });
  final AuthController auth;
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
  bool _obscure = true;
  bool _completed = false;
  bool _codeVerified = false;
  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final success =
        await widget.auth.resetPassword(newPassword: _password.text);
    if (success && mounted) setState(() => _completed = true);
  }

  Future<void> _verifyCode() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text)) {
      setState(() {});
      return;
    }
    final verified = await widget.auth.verifyPasswordResetCode(_code.text);
    if (verified && mounted) setState(() => _codeVerified = true);
  }

  Future<void> _resendCode() async {
    final email = widget.auth.resetEmail;
    if (email == null) return;
    final sent = await widget.auth.requestPasswordReset(email);
    if (sent && mounted) {
      _code.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enviamos un código nuevo a tu correo.')),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.auth,
        builder: (_, __) => AuthShell(
          onBack: widget.onBack,
          title: _completed
              ? 'Contraseña actualizada.'
              : _codeVerified
                  ? 'Elige una contraseña nueva.'
                  : 'Confirma tu código.',
          subtitle: _completed
              ? 'Tus sesiones anteriores se cerraron. Inicia sesión nuevamente.'
              : _codeVerified
                  ? 'Crea una contraseña segura para volver a ingresar.'
                  : 'Escribe el código de seis dígitos que enviamos a tu correo.',
          child: _completed
              ? BusyButton(
                  label: 'Ir a iniciar sesión',
                  busy: false,
                  onPressed: widget.onLogin)
              : _codeVerified
                  ? Form(
                      key: _form,
                      child: Column(
                        children: [
                          FormError(message: widget.auth.error),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            onChanged: (_) => setState(() {}),
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: 'Nueva contraseña',
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(_obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                              ),
                            ),
                            validator: _passwordValidator,
                          ),
                          const SizedBox(height: 10),
                          PasswordChecklist(password: _password.text),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmation,
                            obscureText: _obscure,
                            decoration: const InputDecoration(
                                labelText: 'Confirma la contraseña'),
                            validator: (value) => value != _password.text
                                ? 'Las contraseñas no coinciden.'
                                : null,
                          ),
                          const SizedBox(height: 22),
                          BusyButton(
                              label: 'Restablecer contraseña',
                              busy: widget.auth.loading,
                              onPressed: _submit),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FormError(message: widget.auth.error),
                        TextField(
                          controller: _code,
                          maxLength: 6,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 10,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Código de recuperación',
                            counterText: '',
                            hintText: '000000',
                          ),
                        ),
                        const SizedBox(height: 22),
                        BusyButton(
                          label: 'Verificar código',
                          busy: widget.auth.loading,
                          onPressed:
                              _code.text.length == 6 ? _verifyCode : null,
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: widget.auth.loading ? null : _resendCode,
                          child: const Text('Reenviar código'),
                        ),
                      ],
                    ),
        ),
      );
}

String? _emailValidator(String? value) => value == null ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())
    ? 'Ingresa un correo válido.'
    : null;

String? _passwordValidator(String? value) =>
    value == null || value.length < 8 ? 'Usa al menos 8 caracteres.' : null;
