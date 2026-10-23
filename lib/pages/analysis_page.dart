import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/theme/app_theme.dart';
import '../components/analysis_widgets.dart';
import '../components/feedback.dart';
import '../components/ui.dart';
import '../errors/app_error.dart';
import '../hooks/prescription_hook.dart';
import '../utils/constants.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({
    super.key,
    required this.controller,
    required this.image,
    required this.onBack,
    required this.onComplete,
    this.slowHintAfter = NetworkTimeouts.slowAnalysisHint,
  });

  final PrescriptionController controller;
  final XFile image;

  /// Back to the photo step (also used to choose another image).
  final VoidCallback onBack;
  final VoidCallback onComplete;
  final Duration slowHintAfter;

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  bool _completionHandled = false;
  bool _slow = false;
  Timer? _slowTimer;

  PrescriptionController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
    _start();
  }

  void _start() {
    _slowTimer?.cancel();
    _slow = false;
    _slowTimer = Timer(widget.slowHintAfter, () {
      if (mounted) setState(() => _slow = true);
    });
    _controller.analyze(widget.image);
  }

  void _changed() {
    if (!mounted) return;
    final state = _controller.state;
    if (state is! AnalysisRunning) _slowTimer?.cancel();
    if (state is AnalysisSucceeded && !_completionHandled) {
      _completionHandled = true;
      widget.onComplete();
      return;
    }
    setState(() {});
  }

  void _cancel() {
    _controller.cancel();
    widget.onBack();
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _controller.removeListener(_changed);
    if (_controller.state is AnalysisRunning) _controller.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analizar fórmula'),
        leading: IconButton(tooltip: 'Volver a la foto', onPressed: _cancel, icon: const Icon(Icons.arrow_back)),
      ),
      body: SafeArea(
        child: switch (state) {
          AnalysisFailed(:final error) => _failure(error),
          _ => _AnalysisInProgress(image: widget.image, slow: _slow, onCancel: _cancel),
        },
      ),
    );
  }

  /// FE-005: the recovery action depends on whether retrying can help.
  Widget _failure(AppError error) {
    if (!error.retryable) {
      return ErrorStateView(
        title: 'No pudimos analizar esta imagen',
        error: error,
        primaryLabel: 'Elegir otra imagen',
        primaryIcon: Icons.photo_library_outlined,
        onPrimary: widget.onBack,
      );
    }
    final unreadable = error.kind == AppErrorKind.unreadableAnalysis;
    return ErrorStateView(
      title: 'No pudimos analizar la fórmula',
      error: error,
      primaryLabel: 'Reintentar',
      onPrimary: _start,
      secondaryLabel: unreadable ? 'Tomar otra foto' : 'Volver a la foto',
      onSecondary: widget.onBack,
    );
  }
}

class _AnalysisInProgress extends StatelessWidget {
  const _AnalysisInProgress({required this.image, required this.slow, required this.onCancel});

  final XFile image;
  final bool slow;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const StepIndicator(activeStep: 2),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s + 2),
                decoration: BoxDecoration(
                  color: context.status.brandSurface,
                  borderRadius: BorderRadius.circular(AppRadii.l),
                ),
                child: PrescriptionImagePreview(image: image, maxHeight: 130),
              ),
              const SizedBox(height: AppSpacing.xxl - 4),
              const DelayedSpinner(size: 44, label: 'Analizando tu fórmula'),
              const SizedBox(height: AppSpacing.l + 4),
              Semantics(
                liveRegion: true,
                child: Column(children: [
                  Text('Analizando tu fórmula…', style: context.text.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    slow
                        ? 'Esto está tardando más de lo normal. Puedes seguir esperando o cancelar y volver a intentarlo.'
                        : 'Estamos identificando los medicamentos y organizando la información.',
                    style: context.text.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextButton(onPressed: onCancel, child: const Text('Cancelar análisis')),
            ]),
          ),
        ),
      );
}
