import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/theme/app_theme.dart';
import '../components/ui.dart';
import '../hooks/prescription_hook.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({
    super.key,
    required this.controller,
    required this.image,
    required this.onBack,
    required this.onComplete,
  });
  final PrescriptionController controller;
  final XFile image;
  final VoidCallback onBack;
  final VoidCallback onComplete;
  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(changed);
    widget.controller.analyze(widget.image);
  }

  void changed() {
    if (!mounted) return;
    if (widget.controller.status == PrescriptionStatus.success) {
      widget.onComplete();
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(
          title: const Text('Analizar fórmula'),
          leading: IconButton(
            tooltip: 'Volver a la foto',
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          child: widget.controller.status == PrescriptionStatus.failure
              ? AppError(
                  error: widget.controller.error!,
                  retry: () => widget.controller.analyze(widget.image),
                  onBack: widget.onBack,
                  backLabel: 'Volver a la foto',
                )
              : _AnalysisInProgress(image: widget.image),
        ),
      );
}

class _AnalysisInProgress extends StatelessWidget {
  const _AnalysisInProgress({required this.image});
  final XFile image;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(20)),
                child: PrescriptionImagePreview(image: image, maxHeight: 130),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(strokeWidth: 4)),
              const SizedBox(height: 20),
              const Text('Analizando tu fórmula...', style: AppText.heading),
              const SizedBox(height: 8),
              const Text(
                  'Estamos identificando los medicamentos y organizando la información.',
                  style: AppText.body,
                  textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
}
