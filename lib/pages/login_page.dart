import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../auth/google_mobile_sign_in.dart';
import '../components/auth_ui.dart';
import '../components/farmago/feedback.dart';
import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../components/farmago/buttons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.auth,
    required this.onRegister,
    required this.onForgotPassword,
    required this.onBack,
    this.googleEnabled = true,
    this.googleMobile,
  });

  final AuthController auth;
  final VoidCallback onRegister, onForgotPassword, onBack;

  /// Google sign-in: on the web through the Auth redirect; on Android/iOS through an in-app browser
  /// tab that returns to the app deep link (FE-013).
  final bool googleEnabled;

  /// Test seam for the mobile flow; defaults to [GoogleMobileSignIn.authenticate].
  final Future<GoogleCallback?> Function()? googleMobile;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _submitting = false;
  AppError? _error;

  @override
  void initState() {
    super.initState();
    // e.g. "Tu sesión terminó" or a Google redirect error.
    _error = widget.auth.sessionNotice;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_form.currentState!.validate()) {
      focusFirstInvalid([
        (_emailFocus, () => Validators.email(_email.text)),
        (_passwordFocus, () => Validators.password(_password.text)),
      ]);
      return;
    }
    widget.auth.clearNotice();
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await widget.auth.login(email: _email.text.trim(), password: _password.text);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = error;
    });
    if (error?.kind == AppErrorKind.invalidCredentials) _passwordFocus.requestFocus();
  }

  Future<void> _google() async {
    if (!kIsWeb) return _googleMobile();
    final opened = await launchUrl(
      Uri.parse('${AppConfig.authBaseUrl}/auth/google'),
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_self',
    );
    if (!opened && mounted) setState(() => _error = ErrorMapper.network('launchUrl failed'));
  }

  Future<void> _googleMobile() async {
    widget.auth.clearNotice();
    setState(() {
      _submitting = true;
      _error = null;
    });
    AppError? error;
    try {
      final callback = await (widget.googleMobile ?? () => GoogleMobileSignIn.authenticate(AppConfig.authBaseUrl))();
      if (callback == null) {
        // La persona cerró la pestaña de Google: no es un error.
      } else if (callback.code != null) {
        error = await widget.auth.signInWithGoogleCode(callback.code!);
      } else {
        error = AppError(
          kind: AppErrorKind.unauthorized,
          userMessage: ErrorMapper.googleRedirectMessage(callback.error),
          retryable: true,
          code: callback.error,
        );
      }
    } catch (e) {
      error = ErrorMapper.network('google sign-in failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) => LoginLayout(
        onBack: widget.onBack,
        title: 'Qué bueno verte.',
        subtitle: 'Ingresa para continuar con tus fórmulas y medicamentos.',
        child: AutofillGroup(
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ErrorBanner(error: _error),
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
                validator: Validators.password,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FgButton(
                    label: '¿Olvidaste tu contraseña?',
                    variant: FgButtonVariant.ghost,
                    onPressed: _submitting ? null : widget.onForgotPassword),
              ),
              const SizedBox(height: AppSpacing.l),
              BusyButton(label: 'Iniciar sesión', busyLabel: 'Iniciando sesión', busy: _submitting, onPressed: _submit),
              const SizedBox(height: AppSpacing.l),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                  child: Text('o', style: context.text.labelMedium),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: AppSpacing.l),
              if (widget.googleEnabled)
                GoogleSignInButton(onPressed: _submitting ? null : _google)
              else
                Text(
                  'El acceso con Google está disponible en la versión web. Aquí puedes entrar con tu correo y contraseña.',
                  style: context.text.bodySmall,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: AppSpacing.l),
              FgButton(
                  label: '¿No tienes una cuenta? Crear cuenta',
                  variant: FgButtonVariant.ghost,
                  onPressed: _submitting ? null : widget.onRegister),
            ]),
          ),
        ),
      );
}
