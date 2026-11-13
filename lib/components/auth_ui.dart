import 'farmago/code_input.dart';
import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../utils/validators.dart';
import '../app/theme/farmago_tokens.dart';
import 'farmago/estampado.dart';
import 'farmago/wordmark.dart';

/// Marca de las pantallas de acceso: el símbolo de la app y el nombre (ver [FgMarca]).
class FarmaGoMark extends StatelessWidget {
  const FarmaGoMark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => FgMarca(compacta: compact);
}

/// Layout shared by every public authentication screen.

/// Layout compartido por las pantallas públicas de autenticación.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
    this.showOfficialLogo = false,
  });

  final String title, subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final bool showOfficialLogo;

  /// §23: todas las pantallas de acceso (recuperar y restablecer contraseña, verificar correo,
  /// completar perfil) usan el mismo marco que el inicio de sesión y el registro (consistencia).
  @override
  Widget build(BuildContext context) => LoginLayout(title: title, subtitle: subtitle, onBack: onBack, child: child);
}

/// Primary action with an in-progress state that prevents double submission.
class BusyButton extends StatelessWidget {
  const BusyButton(
      {super.key,
      required this.label,
      required this.busy,
      required this.onPressed,
      this.busyLabel});

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
                    child: CircularProgressIndicator(
                        color: context.colors.onPrimary, strokeWidth: 2),
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
        autofillHints: [
          widget.isNew ? AutofillHints.newPassword : AutofillHints.password
        ],
        validator: widget.validator,
        decoration: InputDecoration(
          labelText: widget.label,
          helperText: widget.helperText,
          suffixIcon: IconButton(
            tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(_obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined),
          ),
        ),
      );
}

/// Six-digit code input with label, digits-only keyboard and one-time-code autofill.
class CodeField extends StatelessWidget {
  const CodeField(
      {super.key,
      required this.controller,
      required this.label,
      this.onChanged,
      this.onSubmitted});

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => FgCodeInput(
        controller: controller,
        label: label,
        ayuda: 'Escribe los 6 dígitos que te enviamos. También puedes pegarlos.',
        autofocus: true,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
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
            text:
                'Al menos ${Validators.minPasswordLength} caracteres (obligatorio)',
          ),
          _Requirement(
              met: RegExp(r'[A-ZÁÉÍÓÚÑ]').hasMatch(password),
              text: 'Una letra mayúscula (recomendado)'),
          _Requirement(
              met: RegExp(r'[^A-Za-z0-9\s]').hasMatch(password),
              text: 'Un símbolo (recomendado)'),
        ]),
      );
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.met, required this.text});

  final bool met;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color =
        met ? context.status.onSuccessContainer : context.status.mutedText;
    return Semantics(
      label: '$text: ${met ? 'cumplido' : 'pendiente'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Row(children: [
          Icon(met ? Icons.check_circle : Icons.circle_outlined,
              size: 18, color: color),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              text,
              style: context.text.bodySmall?.copyWith(
                  color: color, fontWeight: met ? FontWeight.w700 : null),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Botón "Continuar con Google" con el estilo de la guía de marca de Google: fondo blanco, borde
/// gris, texto oscuro y su logo a la izquierda.
///
/// El logo es de Google y no se dibuja aquí: se carga de `assets/images/google_g.png` (descárgalo
/// de la guía oficial "Sign in with Google"). Si el archivo no está, se muestra una "G" neutra.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed, this.label = 'Continuar con Google'});

  static const logoAsset = 'assets/images/google_g.png';
  static const _texto = Color(0xFF1F1F1F);
  static const _borde = Color(0xFF747775);

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _texto,
          disabledBackgroundColor: Colors.white,
          side: const BorderSide(color: _borde),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FgRadius.md)),
          textStyle: FgText.boton(16),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          ExcludeSemantics(
            child: Image.asset(
              logoAsset,
              width: 20,
              height: 20,
              errorBuilder: (context, _, __) => const SizedBox(
                width: 20,
                height: 20,
                child: Center(child: Text('G', style: TextStyle(fontWeight: FontWeight.w700, color: _texto))),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ]),
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

/// Diseño responsive exclusivo de la pantalla de inicio de sesión.
class LoginLayout extends StatelessWidget {
  const LoginLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FgColors.fondo,
      body: FgFondo(child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= FgBreakpoint.desktop;

            final form = _buildForm(context);

            if (!isDesktop) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: FgSize.dialogSm,
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      FgBreakpoint.margenLateral(
                        constraints.maxWidth,
                      ),
                    ),
                    child: form,
                  ),
                ),
              );
            }

            return Row(
              children: [
                // Columna izquierda: información de FarmaGo, sobre el fondo con estampado de marca.
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(FgSpace.sp8),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: FgSize.dialogSm,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'De la farmacia a tu puerta.',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    color: FgColors.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: FgSpace.sp5),
                            Text(
                              'Consulta tus medicamentos y haz '
                              'seguimiento a tus entregas '
                              'desde un solo lugar.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: FgColors.inkSoft,
                                  ),
                            ),
                            const SizedBox(height: FgSpace.sp7),
                            _buildInfoRow(
                              context,
                              Icons.visibility_outlined,
                              'Consulta el estado de tus entregas',
                            ),
                            const SizedBox(height: FgSpace.sp5),
                            _buildInfoRow(
                              context,
                              Icons.route_outlined,
                              'Sigue el recorrido de tus pedidos',
                            ),
                            const SizedBox(height: FgSpace.sp5),
                            _buildInfoRow(
                              context,
                              Icons.medication_outlined,
                              'Accede a la información de tus medicamentos',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Columna derecha: logo y formulario.
                Expanded(
                  child: Container(
                    color: FgColors.superficie,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: FgSize.dialogSm,
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(FgSpace.sp6),
                          child: form,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      )),
    );
  }

  Widget _buildForm(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < FgBreakpoint.tablet;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onBack != null)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Volver',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
          ),

        // Logo oficial de FarmaGo.
        Center(
          child: Image.asset(
            'assets/images/logo_farmago.png',
            width: isMobile ? 200 : 240,
            fit: BoxFit.contain,
            semanticLabel: 'FarmaGo, de la farmacia a tu puerta',
          ),
        ),

        const SizedBox(height: FgSpace.sp6),

        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: FgColors.ink,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),

        const SizedBox(height: FgSpace.sp3),

        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: FgColors.inkSoft),
        ),

        const SizedBox(height: FgSpace.sp6),

        // Formulario original, sin modificar autenticación.
        child,
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: FgColors.azul600,
          size: FgSize.iconoLg,
        ),
        const SizedBox(width: FgSpace.sp4),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: FgColors.ink),
          ),
        ),
      ],
    );
  }
}
