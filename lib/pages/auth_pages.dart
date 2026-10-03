import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../components/auth_ui.dart';
import '../utils/constants.dart';

class LandingPage extends StatelessWidget {
  const LandingPage(
      {super.key, required this.onLogin, required this.onRegister});
  final VoidCallback onLogin, onRegister;
  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(padding: const EdgeInsets.all(24), children: [
                    const FarmaGoMark(),
                    const SizedBox(height: 22),
                    const _NetworkVisual(),
                    const SizedBox(height: 22),
                    const Text('Medicamentos a tiempo,\ncon trazabilidad.',
                        style: AppText.display),
                    const SizedBox(height: 14),
                    const Text(
                        'FARMA GO conecta EPS, gestores farmacéuticos, droguerías, repartidores y pacientes para coordinar la entrega oportuna de medicamentos.',
                        style: AppText.body),
                    const SizedBox(height: 26),
                    FilledButton(
                        onPressed: onLogin,
                        child: const Text('Iniciar sesión')),
                    const SizedBox(height: 12),
                    OutlinedButton(
                        onPressed: onRegister,
                        child: const Text('Crear cuenta')),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.light,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Una misma red para cada solicitud',
                              style: AppText.title),
                          SizedBox(height: 7),
                          Text(
                              'Las fórmulas y solicitudes se canalizan por la misma operación logística para dar visibilidad del proceso de dispensación y entrega.',
                              style: AppText.body),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Wrap(spacing: 10, runSpacing: 10, children: [
                      _Benefit(
                          icon: Icons.route_outlined,
                          text: 'Seguimiento del proceso'),
                      _Benefit(
                          icon: Icons.storefront_outlined,
                          text: 'Red de dispensación'),
                      _Benefit(
                          icon: Icons.local_shipping_outlined,
                          text: 'Entrega coordinada')
                    ]),
                  ])))));
}

class _NetworkVisual extends StatelessWidget {
  const _NetworkVisual();
  @override
  Widget build(BuildContext context) => Container(
      height: 150,
      decoration: const BoxDecoration(
          color: AppColors.sky,
          borderRadius: BorderRadius.all(Radius.circular(32))),
      child: const Stack(alignment: Alignment.center, children: [
          Positioned(
            left: 38,
            top: 46,
            child: _NetworkNode(
                icon: Icons.account_balance_outlined, label: 'EPS')),
          Positioned(
            right: 38,
            top: 46,
            child: _NetworkNode(
                icon: Icons.local_pharmacy_outlined, label: 'Dispensación')),
          Positioned(
            bottom: 12,
            child: _NetworkNode(
                icon: Icons.person_outline_rounded, label: 'Paciente')),
          Positioned(
            top: 73,
            child: SizedBox(
                width: 160, child: Divider(color: Colors.white, thickness: 2))),
          Positioned(
            bottom: 47,
            left: 124,
            child: Icon(Icons.local_shipping_outlined,
                color: AppColors.navy, size: 27)),
      ]));
}

class _NetworkNode extends StatelessWidget {
  const _NetworkNode({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(
            radius: 21,
            backgroundColor: Colors.white,
            child: Icon(icon, color: AppColors.navy, size: 21)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.navy)),
      ]);
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.sky)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: AppColors.navy),
        const SizedBox(width: 7),
        Text(text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))
      ]));
}

class LoginPage extends StatefulWidget {
  const LoginPage(
      {super.key,
      required this.auth,
      required this.onRegister,
      required this.onForgotPassword,
      required this.onBack});
  final AuthController auth;
  final VoidCallback onRegister, onForgotPassword, onBack;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(), password = TextEditingController();
  bool obscure = true;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    await widget.auth.login(email: email.text.trim(), password: password.text);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.auth,
      builder: (_, __) => AuthShell(
          onBack: widget.onBack,
          title: 'Qué bueno verte.',
          subtitle: 'Ingresa para continuar con tus fórmulas y medicamentos.',
          child: Form(
              key: form,
              child: Column(children: [
                FormError(message: widget.auth.error),
                TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration:
                        const InputDecoration(labelText: 'Correo electrónico'),
                    validator: _emailValidator),
                const SizedBox(height: 14),
                TextFormField(
                    controller: password,
                    obscureText: obscure,
                    onChanged: (_) => setState(() {}),
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                        labelText: 'Contraseña',
                        suffixIcon: IconButton(
                            onPressed: () => setState(() => obscure = !obscure),
                            icon: Icon(obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined))),
                    validator: _passwordValidator),
                Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        onPressed: widget.onForgotPassword,
                        child: const Text('¿Olvidaste tu contraseña?'))),
                const SizedBox(height: 22),
                BusyButton(
                    label: 'Iniciar sesión',
                    busy: widget.auth.loading,
                    onPressed: submit),
                const SizedBox(height: 20),
                const Row(children: [
                  Expanded(child: Divider()),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text('o', style: AppText.label)),
                  Expanded(child: Divider())
                ]),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                    onPressed: widget.auth.loading ? null : _google,
                    icon: const GoogleMark(),
                    label: const Text('Continuar con Google')),
                const SizedBox(height: 19),
                TextButton(
                    onPressed: widget.onRegister,
                    child: const Text('¿No tienes una cuenta? Crear cuenta')),
              ]))));
  Future<void> _google() async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Google OAuth requiere el callback web que define el backend actual.')));
      return;
    }
    await launchUrl(Uri.parse('${AppConfig.authBaseUrl}/auth/google'),
        mode: LaunchMode.platformDefault);
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage(
      {super.key,
      required this.auth,
      required this.onLogin,
      required this.onBack});
  final AuthController auth;
  final VoidCallback onLogin, onBack;
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      confirmation = TextEditingController();
  bool obscure = true;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    await widget.auth.signUp(
        name: name.text.trim(),
        email: email.text.trim(),
        password: password.text);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.auth,
      builder: (_, __) => AuthShell(
          onBack: widget.onBack,
          title: 'Crea tu espacio de salud.',
          subtitle:
              'Te enviaremos un código al correo para proteger tu cuenta.',
          child: Form(
              key: form,
              child: Column(children: [
                FormError(message: widget.auth.error),
                TextFormField(
                    controller: name,
                    textCapitalization: TextCapitalization.words,
                    decoration:
                        const InputDecoration(labelText: 'Nombre completo'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ingresa tu nombre.'
                        : null),
                const SizedBox(height: 14),
                TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(labelText: 'Correo electrónico'),
                    validator: _emailValidator),
                const SizedBox(height: 14),
                TextFormField(
                    controller: password,
                    obscureText: obscure,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                        labelText: 'Contraseña',
                        helperText: 'Mínimo 8 caracteres.',
                        suffixIcon: IconButton(
                            onPressed: () => setState(() => obscure = !obscure),
                            icon: Icon(obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined))),
                    validator: _passwordValidator),
                const SizedBox(height: 10),
                PasswordChecklist(password: password.text),
                const SizedBox(height: 14),
                TextFormField(
                    controller: confirmation,
                    obscureText: obscure,
                    decoration: const InputDecoration(
                        labelText: 'Confirma tu contraseña'),
                    validator: (value) => value != password.text
                        ? 'Las contraseñas no coinciden.'
                        : null),
                const SizedBox(height: 22),
                BusyButton(
                    label: 'Crear cuenta',
                    busy: widget.auth.loading,
                    onPressed: submit),
                const SizedBox(height: 17),
                TextButton(
                    onPressed: widget.onLogin,
                    child: const Text('Ya tengo una cuenta')),
              ]))));
}

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key, required this.auth, required this.onBack});
  final AuthController auth;
  final VoidCallback onBack;
  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final code = TextEditingController();
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.auth.pendingEmail ?? '';
    final concealed =
        email.replaceRange(2, email.indexOf('@').clamp(2, email.length), '•••');
    return AnimatedBuilder(
        animation: widget.auth,
        builder: (_, __) => AuthShell(
            onBack: widget.onBack,
            title: 'Confirma tu correo.',
            subtitle:
                'Escribe el código de seis dígitos que enviamos a $concealed.',
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FormError(message: widget.auth.error),
                  TextField(
                      controller: code,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 10),
                      decoration: const InputDecoration(
                          counterText: '', hintText: '000000')),
                  const SizedBox(height: 22),
                  BusyButton(
                      label: 'Verificar código',
                      busy: widget.auth.loading,
                      onPressed: code.text.length == 6
                          ? () => widget.auth.verify(code.text)
                          : null),
                  const SizedBox(height: 12),
                  TextButton(
                      onPressed: widget.auth.loading
                          ? null
                          : () async {
                              await widget.auth.resend();
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Solicitamos un código nuevo.')));
                              }
                            },
                      child: const Text('Reenviar código')),
                ])));
  }
}

String? _emailValidator(String? value) => value == null ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())
    ? 'Ingresa un correo válido.'
    : null;
String? _passwordValidator(String? value) =>
    value == null || value.length < 8 ? 'Usa al menos 8 caracteres.' : null;
