import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../components/feedback.dart';
import '../errors/app_error.dart';
import '../errors/error_messages.dart';

class SessionLoadingPage extends StatelessWidget {
  const SessionLoadingPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: DelayedSpinner(size: 38, label: 'Comprobando tu sesión')),
      );
}

/// Shown when the auth service cannot be reached at start-up (no blank screen).
class SessionUnavailablePage extends StatelessWidget {
  const SessionUnavailablePage({super.key, required this.error, required this.onRetry, required this.onContinue});

  final AppError? error;
  final VoidCallback onRetry;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ErrorStateView(
            title: 'No pudimos comprobar tu sesión',
            error: error ??
                AppError(kind: AppErrorKind.network, userMessage: ErrorMessages.sessionUnverified, retryable: true),
            primaryLabel: 'Reintentar',
            onPrimary: onRetry,
            secondaryLabel: 'Ir a iniciar sesión',
            onSecondary: onContinue,
          ),
        ),
      );
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  final IconData icon;
  final String title, message, actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 52, color: context.colors.secondary),
              const SizedBox(height: AppSpacing.l),
              Text(title, style: context.text.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.s),
              Text(message, style: context.text.bodyLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(onPressed: onAction, icon: Icon(actionIcon), label: Text(actionLabel)),
            ]),
          ),
        ),
      );
}

class MissingAnalysisStepPage extends StatelessWidget {
  const MissingAnalysisStepPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Analizar fórmula'),
          leading: IconButton(tooltip: 'Volver a seleccionar la fórmula', onPressed: onBack, icon: const Icon(Icons.arrow_back)),
        ),
        body: _CenteredMessage(
          icon: Icons.photo_library_outlined,
          title: 'Primero selecciona una fórmula',
          message: 'Este paso necesita una imagen para continuar con el análisis.',
          actionLabel: 'Seleccionar una fórmula',
          actionIcon: Icons.arrow_back,
          onAction: onBack,
        ),
      );
}

class UnknownRoutePage extends StatelessWidget {
  const UnknownRoutePage({super.key, required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Página no encontrada')),
        body: _CenteredMessage(
          icon: Icons.explore_off_outlined,
          title: 'No encontramos esta pantalla',
          message: 'Puede que el enlace haya cambiado. Vuelve al inicio para continuar.',
          actionLabel: 'Ir al inicio',
          actionIcon: Icons.home_outlined,
          onAction: onHome,
        ),
      );
}

/// Fallback for build errors (FE-006): never a grey or red screen.
class AppCrashView extends StatelessWidget {
  const AppCrashView({super.key});

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: _content(context),
      );

  Widget _content(BuildContext context) => Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.sentiment_dissatisfied_outlined, size: 44, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: AppSpacing.m),
              Text(
                'Esta sección no se pudo mostrar. Vuelve atrás o recarga la aplicación; si sigue pasando, escríbenos.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ]),
          ),
        ),
      );
}
