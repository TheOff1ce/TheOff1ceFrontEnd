import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';

/// Progress through the three analysis steps.
class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.activeStep});

  final int activeStep;
  static const _labels = ['Foto', 'Análisis', 'Resultado'];

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Paso $activeStep de ${_labels.length}: ${_labels[activeStep - 1]}',
        excludeSemantics: true,
        child: Row(children: [
          for (var i = 0; i < _labels.length; i++) ...[
            if (i > 0) Expanded(child: Divider(color: context.status.decorative)),
            _step(context, i + 1, _labels[i], activeStep >= i + 1),
          ],
        ]),
      );

  Widget _step(BuildContext context, int number, String label, bool active) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: active ? context.colors.primary : context.status.brandSurface,
          child: Text(
            '$number',
            style: context.text.labelSmall?.copyWith(color: active ? context.colors.onPrimary : context.colors.primary),
          ),
        ),
        const SizedBox(width: AppSpacing.xs + 1),
        Text(
          label,
          style: context.text.labelMedium?.copyWith(color: active ? context.colors.primary : null),
        ),
      ]);
}

/// Advice for a readable photo.
class PhotoTips extends StatelessWidget {
  const PhotoTips({super.key});

  static const _tips = [
    'Usa buena iluminación',
    'Incluye todo el texto de la fórmula',
    'Evita fotos borrosas o con reflejos',
  ];

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: context.status.brandSurface,
          borderRadius: BorderRadius.circular(AppRadii.l),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Para una mejor lectura', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          for (final tip in _tips)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s - 2),
              child: Row(children: [
                ExcludeSemantics(
                  child: Icon(Icons.check_circle_outline, size: 18, color: context.status.onSuccessContainer),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(child: Text(tip, style: context.text.bodyLarge)),
              ]),
            ),
        ]),
      );
}
