import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../types/medication.dart';
import 'ui.dart';

class MedicationCard extends StatelessWidget {
  const MedicationCard({super.key, required this.medication});

  final Medication medication;

  static const unnamedTitle = 'Nombre no identificado';

  @override
  Widget build(BuildContext context) {
    final m = medication;
    final summary = [m.concentration, m.pharmaceuticalForm].whereType<String>().join(' · ');
    final details = {
      'Principio activo': m.activeIngredient,
      'Presentación': m.presentation,
      'Dosis': m.dose,
      'Frecuencia': m.frequency,
      'Duración': m.duration,
      'Cantidad': m.quantity,
      'Instrucciones': m.instructions,
    }.entries.where((entry) => entry.value != null);
    return AppCard(
      bordered: m.requiresReview,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Header(medication: m),
        if (summary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.m),
          Text(summary, style: context.text.bodyLarge),
        ],
        for (final entry in details)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.m),
            child: MergeSemantics(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.key, style: context.text.labelMedium),
                Text(entry.value!, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.l), child: Divider()),
        ConfidenceIndicator(confidence: m.confidence, requiresReview: m.requiresReview),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.medication});

  final Medication medication;

  @override
  Widget build(BuildContext context) {
    final named = medication.hasName;
    return Row(children: [
      CircleAvatar(
        backgroundColor: named ? context.status.brandSurface : context.status.warningContainer,
        child: Icon(
          named ? Icons.medication : Icons.help_outline,
          color: named ? context.colors.secondary : context.status.onWarningContainer,
        ),
      ),
      const SizedBox(width: AppSpacing.m),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(
            header: true,
            child: Text(medication.name ?? MedicationCard.unnamedTitle, style: context.text.titleMedium),
          ),
          if (!named)
            Text('Compáralo con tu fórmula antes de usar esta información.', style: context.text.bodySmall),
        ]),
      ),
    ]);
  }
}

/// Confidence of the text extraction. Color is never the only signal: the
/// review state is also written out (FE-007 / FE-017).
class ConfidenceIndicator extends StatelessWidget {
  const ConfidenceIndicator({super.key, required this.confidence, required this.requiresReview});

  final double? confidence;
  final bool requiresReview;

  @override
  Widget build(BuildContext context) {
    final status = context.status;
    final foreground = requiresReview ? status.onWarningContainer : status.onSuccessContainer;
    final background = requiresReview ? status.warningContainer : status.successContainer;
    final percent = confidence == null ? null : (confidence! * 100).round();
    final headline = percent == null ? 'Confianza de extracción no disponible' : 'Confianza de extracción: $percent %';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadii.s)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(requiresReview ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: foreground, size: 20),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              requiresReview ? '$headline · Revísalo' : headline,
              style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: foreground),
            ),
          ),
        ]),
        if (confidence != null) ...[
          const SizedBox(height: AppSpacing.s),
          ExcludeSemantics(
            child: LinearProgressIndicator(value: confidence, color: foreground, backgroundColor: Colors.white),
          ),
        ],
        if (requiresReview)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s),
            child: Text(
              'La confianza refleja la lectura del texto, no una certeza médica.',
              style: context.text.bodySmall?.copyWith(color: foreground),
            ),
          ),
      ]),
    );
  }
}
