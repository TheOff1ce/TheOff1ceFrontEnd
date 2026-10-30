import 'dart:async';

import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../errors/app_error.dart';

/// Inline error for forms and sections; announced by screen readers (FE-008).
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.error});

  final AppError? error;

  @override
  Widget build(BuildContext context) {
    final current = error;
    if (current == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppSpacing.l),
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: context.colors.errorContainer,
          borderRadius: BorderRadius.circular(AppRadii.s),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.error_outline, color: context.colors.onErrorContainer, semanticLabel: 'Error'),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(current.userMessage,
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  )),
              if (current.showsReference) ReferenceText(error: current),
            ]),
          ),
        ]),
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
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: SelectableText('Código de referencia: ${error.referenceId}', style: context.text.bodySmall),
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
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Semantics(
              liveRegion: true,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.error_outline, color: context.colors.error, size: 52),
                const SizedBox(height: AppSpacing.l),
                Text(title, style: context.text.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.s),
                Text(error.userMessage, style: context.text.bodyLarge, textAlign: TextAlign.center),
                if (error.showsReference) ReferenceText(error: error),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(onPressed: onPrimary, icon: Icon(primaryIcon), label: Text(primaryLabel)),
                ),
                if (secondaryLabel != null && onSecondary != null) ...[
                  const SizedBox(height: AppSpacing.s),
                  TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
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
        child: _visible ? CircularProgressIndicator(semanticsLabel: widget.label) : null,
      );
}

/// Shows a snackbar that stays at least 6 seconds and can be dismissed.
void showAppSnackBar(BuildContext context, String message, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 6),
      showCloseIcon: action == null,
      closeIconColor: Colors.white,
      action: action,
    ));
}
