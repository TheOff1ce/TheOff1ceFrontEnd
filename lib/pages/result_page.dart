import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../components/analysis_widgets.dart';
import '../components/medication_card.dart';
import '../components/ui.dart';
import '../types/analysis_response.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({super.key, required this.result, required this.onHome, required this.onAnalyzeAnother});

  final AnalysisResponse result;
  final VoidCallback onHome;
  final VoidCallback onAnalyzeAnother;

  @override
  Widget build(BuildContext context) {
    final count = result.medications.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado del análisis'),
        leading: IconButton(tooltip: 'Volver al inicio', onPressed: onHome, icon: const Icon(Icons.arrow_back)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.l + 4, AppSpacing.s, AppSpacing.l + 4, AppSpacing.l + 4),
              child: Column(children: [
                Expanded(
                  child: ListView(children: [
                    const StepIndicator(activeStep: 3),
                    const SizedBox(height: AppSpacing.l),
                    Semantics(
                      header: true,
                      child: Text(
                        count == 0
                            ? 'No identificamos medicamentos'
                            : 'Encontramos $count ${count == 1 ? 'medicamento' : 'medicamentos'}',
                        style: context.text.headlineSmall,
                      ),
                    ),
                    if (result.requiresHumanReview || result.warnings.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.l),
                      _ReviewNotice(warnings: result.warnings),
                    ],
                    if (result.isEmpty) ...[
                      const SizedBox(height: AppSpacing.l),
                      const _EmptyResult(),
                    ],
                    for (final medication in result.medications)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.l),
                        child: MedicationCard(medication: medication),
                      ),
                    const SizedBox(height: AppSpacing.l),
                    Text(
                      'La información extraída no reemplaza la indicación de un profesional de salud.',
                      style: context.text.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ]),
                ),
                const SizedBox(height: AppSpacing.m),
                AppButton(label: 'Analizar otra fórmula', icon: Icons.add_a_photo_outlined, onPressed: onAnalyzeAnother),
                const SizedBox(height: AppSpacing.s + 2),
                AppButton(label: 'Volver al inicio', icon: Icons.home_outlined, outlined: true, onPressed: onHome),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewNotice extends StatelessWidget {
  const _ReviewNotice({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    final status = context.status;
    return AppCard(
      color: status.warningContainer,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.warning_amber_rounded, color: status.onWarningContainer),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              'Revisión necesaria',
              style: context.text.titleMedium?.copyWith(color: status.onWarningContainer),
            ),
          ),
        ]),
        const SizedBox(height: AppSpacing.s),
        Text('Compara esta información con tu fórmula antes de utilizarla.', style: context.text.bodyMedium),
        for (final warning in warnings)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text('• $warning', style: context.text.bodyMedium),
          ),
      ]),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult();

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(children: [
          ExcludeSemantics(child: Icon(Icons.search_off_outlined, size: 42, color: context.colors.secondary)),
          const SizedBox(height: AppSpacing.m),
          Text(
            'Prueba con una imagen más clara, completa y bien iluminada.',
            style: context.text.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ]),
      );
}
