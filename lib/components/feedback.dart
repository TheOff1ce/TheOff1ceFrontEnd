import 'dart:async';

import 'package:flutter/material.dart';

import '../app/theme/farmago_tokens.dart';
import 'farmago/buttons.dart';
import 'farmago/feedback.dart';
import '../errors/app_error.dart';

/// Inline error for forms and sections; announced by screen readers (FE-008).
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.error});

  final AppError? error;

  @override
  Widget build(BuildContext context) {
    final current = error;
    if (current == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: FgSpace.sp4),
      child: FgBanner(
        kind: FgBannerKind.error,
        message: current.userMessage,
        referencia: current.showsReference ? current.referenceId : null,
      ),
    );
  }
}

/// Discreet support reference, shown in addition to (never instead of) the message.
class ReferenceText extends StatelessWidget {
  const ReferenceText({super.key, required this.error});

  final AppError error;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: FgSpace.sp1),
        child: SelectableText('Código de referencia: ${error.referenceId}', style: FgText.caption),
      );
}

/// Full-screen or section error with a recovery action (frontend-guardian §4).
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.title,
    required this.error,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryIcon = Icons.refresh,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final AppError error;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FgSpace.sp5),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: FgSize.dialogSm),
            child: Semantics(
              liveRegion: true,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const FgGlifo(color: FgColors.peligro, simbolo: Icons.close, diametro: 56, tamanoSimbolo: 32),
                const SizedBox(height: FgSpace.sp5),
                Semantics(
                  header: true,
                  child: Text(title, style: FgText.h2, textAlign: TextAlign.center),
                ),
                const SizedBox(height: FgSpace.sp2),
                Text(error.userMessage, style: FgText.body.copyWith(color: FgColors.inkSoft), textAlign: TextAlign.center),
                if (error.showsReference) ReferenceText(error: error),
                const SizedBox(height: FgSpace.sp6),
                FgButton(
                  label: primaryLabel,
                  icon: primaryIcon,
                  expand: true,
                  onPressed: onPrimary,
                ),
                if (secondaryLabel != null && onSecondary != null) ...[
                  const SizedBox(height: FgSpace.sp3),
                  FgButton(
                    label: secondaryLabel!,
                    variant: FgButtonVariant.secondary,
                    expand: true,
                    onPressed: onSecondary,
                  ),
                ],
              ]),
            ),
          ),
        ),
      );
}

/// Spinner that only appears after a short delay, avoiding flicker (frontend-guardian §3).
class DelayedSpinner extends StatefulWidget {
  const DelayedSpinner({super.key, this.size = 40, this.label = 'Cargando'});

  final double size;
  final String label;

  @override
  State<DelayedSpinner> createState() => _DelayedSpinnerState();
}

class _DelayedSpinnerState extends State<DelayedSpinner> {
  static const _delay = Duration(milliseconds: 300);
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: _visible
            ? Semantics(label: widget.label, child: Center(child: FgSpinner(size: widget.size)))
            : null,
      );
}

/// Aviso breve de algo que ya ocurrió. Sin acción usa el toast del manual, para que los avisos de
/// la app se vean y se comporten igual (los errores no se cierran solos). Con acción (por ejemplo
/// "Deshacer") usa la barra inferior, que es la que admite un botón.
void showAppSnackBar(BuildContext context, String message, {SnackBarAction? action, bool error = false}) {
  if (action == null) {
    showFgToast(context, message, kind: error ? FgToastKind.error : FgToastKind.exito);
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 6), action: action));
}
