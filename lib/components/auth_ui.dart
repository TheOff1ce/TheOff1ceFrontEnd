import 'package:flutter/material.dart';
import '../app/theme/app_theme.dart';

class FarmaGoMark extends StatelessWidget {
  const FarmaGoMark({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: compact ? 38 : 48,
            height: compact ? 38 : 48,
            decoration: BoxDecoration(
                color: AppColors.navy, borderRadius: BorderRadius.circular(15)),
            child:
                const Icon(Icons.local_pharmacy_rounded, color: Colors.white)),
        const SizedBox(width: 10),
        Text('FARMA GO',
            style: TextStyle(
                fontSize: compact ? 17 : 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -.7,
                color: AppColors.navy)),
      ]);
}

class AuthShell extends StatelessWidget {
  const AuthShell(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.child,
      this.onBack});
  final String title, subtitle;
  final Widget child;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                      children: [
                        if (onBack != null)
                          Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                  onPressed: onBack,
                                  icon: const Icon(Icons.arrow_back))),
                        const FarmaGoMark(),
                        const SizedBox(height: 42),
                        Text(title, style: AppText.display),
                        const SizedBox(height: 10),
                        Text(subtitle, style: AppText.body),
                        const SizedBox(height: 30),
                        child,
                      ])))));
}

class FormError extends StatelessWidget {
  const FormError({super.key, this.message});
  final String? message;
  @override
  Widget build(BuildContext context) => message == null
      ? const SizedBox.shrink()
      : Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
              color: const Color(0xFFFFE9E7),
              borderRadius: BorderRadius.circular(12)),
          child: Text(message!,
              style: const TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.w600)));
}

class BusyButton extends StatelessWidget {
  const BusyButton(
      {super.key,
      required this.label,
      required this.busy,
      required this.onPressed});
  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : Text(label));
}

class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({super.key, required this.password});
  final String password;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tu contraseña', style: AppText.label),
            const SizedBox(height: 8),
            _Requirement(
                met: password.length >= 8, text: 'Al menos 8 caracteres'),
            _Requirement(
                met: RegExp(r'[A-ZÁÉÍÓÚÑ]').hasMatch(password),
                text: 'Una letra mayúscula recomendada'),
            _Requirement(
                met: RegExp(r'[^A-Za-z0-9\s]').hasMatch(password),
                text: 'Un símbolo recomendado'),
          ],
        ),
      );
}

class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: const Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.met, required this.text});
  final bool met;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Row(children: [
          Icon(met ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 18, color: met ? AppColors.success : AppColors.secondary),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: met ? FontWeight.w700 : FontWeight.w500,
                  color: met ? AppColors.success : AppColors.secondary)),
        ]),
      );
}
