import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme/app_theme.dart';
import '../utils/validators.dart';

class FarmaGoMark extends StatelessWidget {
  const FarmaGoMark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'FARMA GO',
        header: true,
        child: ExcludeSemantics(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: compact ? 38 : 48,
              height: compact ? 38 : 48,
              decoration: BoxDecoration(
                color: context.colors.primary,
                borderRadius: BorderRadius.circular(AppRadii.s),
              ),
              child: Icon(Icons.local_pharmacy_rounded, color: context.colors.onPrimary),
            ),
            const SizedBox(width: AppSpacing.s + 2),
            Text(
              'FARMA GO',
              style: (compact ? context.text.titleMedium : context.text.titleLarge)
                  ?.copyWith(fontWeight: FontWeight.w800, color: context.colors.primary, letterSpacing: -0.5),
            ),
          ]),
        ),
      );
}

/// Layout shared by every public authentication screen.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.title, required this.subtitle, required this.child, this.onBack});

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
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.l, AppSpacing.xl, AppSpacing.xxl),
                children: [
                  if (onBack != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(tooltip: 'Volver', onPressed: onBack, icon: const Icon(Icons.arrow_back)),
                    ),
                  const FarmaGoMark(),
                  const SizedBox(height: AppSpacing.xxl),
                  Semantics(header: true, child: Text(title, style: context.text.displaySmall)),
                  const SizedBox(height: AppSpacing.s),
                  Text(subtitle, style: context.text.bodyLarge),
                  const SizedBox(height: AppSpacing.xxl - 2),
                  child,
                ],
              ),
            ),
          ),
        ),
      );
}

/// Primary action with an in-progress state that prevents double submission.
class BusyButton extends StatelessWidget {
  const BusyButton({super.key, required this.label, required this.busy, required this.onPressed, this.busyLabel});

  final String label;
  final String? busyLabel;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: busy ? null : onPressed,
          child: busy
              ? Semantics(
                  label: busyLabel ?? 'Procesando',
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: context.colors.onPrimary, strokeWidth: 2),
                  ),
                )
              : Text(label),
        ),
      );
}

/// Password input with an accessible show/hide toggle (FE-008).
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.focusNode,
    this.validator,
    this.helperText,
    this.isNew = false,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  final String? helperText;
  final bool isNew;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: _obscure,
        enableSuggestions: false,
        autocorrect: false,
        autovalidateMode: AutovalidateMode.onUnfocus,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        autofillHints: [widget.isNew ? AutofillHints.newPassword : AutofillHints.password],
        validator: widget.validator,
        decoration: InputDecoration(
          labelText: widget.label,
          helperText: widget.helperText,
          suffixIcon: IconButton(
            tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          ),
        ),
      );
}

/// Six-digit code input with label, digits-only keyboard and one-time-code autofill.
class CodeField extends StatelessWidget {
  const CodeField({super.key, required this.controller, required this.label, this.onChanged, this.onSubmitted});

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLength: 6,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: context.text.headlineSmall?.copyWith(letterSpacing: 10, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          labelText: label,
          hintText: '000000',
          helperText: 'Escribe los 6 dígitos que te enviamos para continuar.',
          counterText: '',
        ),
      );
}

class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.m + 2),
        decoration: BoxDecoration(
          color: context.status.brandSurface,
          borderRadius: BorderRadius.circular(AppRadii.s),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tu contraseña', style: context.text.labelMedium),
          const SizedBox(height: AppSpacing.s),
          _Requirement(
            met: password.length >= Validators.minPasswordLength,
            text: 'Al menos ${Validators.minPasswordLength} caracteres (obligatorio)',
          ),
          _Requirement(met: RegExp(r'[A-ZÁÉÍÓÚÑ]').hasMatch(password), text: 'Una letra mayúscula (recomendado)'),
          _Requirement(met: RegExp(r'[^A-Za-z0-9\s]').hasMatch(password), text: 'Un símbolo (recomendado)'),
        ]),
      );
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.met, required this.text});

  final bool met;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = met ? context.status.onSuccessContainer : context.status.mutedText;
    return Semantics(
      label: '$text: ${met ? 'cumplido' : 'pendiente'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Row(children: [
          Icon(met ? Icons.check_circle_rounded : Icons.circle_outlined, size: 18, color: color),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              text,
              style: context.text.bodySmall?.copyWith(color: color, fontWeight: met ? FontWeight.w700 : null),
            ),
          ),
        ]),
      ),
    );
  }
}

class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Text('G', style: context.text.titleMedium?.copyWith(color: context.colors.secondary)),
        ),
      );
}

/// Moves focus to the first invalid field after a failed submit (FE-008).
void focusFirstInvalid(List<(FocusNode, String? Function())> fields) {
  for (final (node, validate) in fields) {
    if (validate() != null) {
      node.requestFocus();
      return;
    }
  }
}
