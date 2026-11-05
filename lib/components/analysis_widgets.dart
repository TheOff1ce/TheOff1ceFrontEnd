import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../app/theme/farmago_tokens.dart';

/// Progress through the three analysis steps. Each step is a numbered node with its word
/// underneath; the steps share the width evenly, so long words never overflow on small screens.
class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.activeStep});

  final int activeStep;
  static const _labels = ['Foto', 'Análisis', 'Resultado'];
  static const _node = FgSize.simboloS;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Paso $activeStep de ${_labels.length}: ${_labels[activeStep - 1]}',
        excludeSemantics: true,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < _labels.length; i++) Expanded(child: _step(i)),
        ]),
      );

  Widget _step(int index) {
    final number = index + 1;
    final reached = activeStep >= number;
    final current = activeStep == number;
    Widget connector(bool visible, bool done) => Expanded(
          child: Container(
            height: FgBorder.w2,
            color: visible ? (done ? FgColors.azul600 : FgColors.linea) : Colors.transparent,
          ),
        );
    return Column(children: [
      Row(children: [
        connector(index > 0, reached),
        Container(
          width: _node,
          height: _node,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached ? FgColors.azul600 : FgColors.superficie,
            border: Border.all(color: reached ? FgColors.azul600 : FgColors.lineaControl, width: FgBorder.w2),
          ),
          child: Text(
            '$number',
            style: FgText.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: reached ? Colors.white : FgColors.inkSoft,
              height: 1,
            ),
          ),
        ),
        connector(index < _labels.length - 1, activeStep > number),
      ]),
      const SizedBox(height: FgSpace.sp1),
      Text(
        _labels[index],
        textAlign: TextAlign.center,
        style: FgText.caption.copyWith(
          fontWeight: current ? FontWeight.w700 : FontWeight.w400,
          color: reached ? FgColors.azul800 : FgColors.inkSoft,
        ),
      ),
    ]);
  }
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
