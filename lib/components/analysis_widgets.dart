import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../app/theme/farmago_tokens.dart';
import '../types/analysis_response.dart';
import '../utils/pendiente_format.dart';
import 'farmago/card.dart';
import 'farmago/feedback.dart';

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
          color: reached ? FgColors.azulTexto : FgColors.inkSoft,
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

/// Dato que le falta a la fórmula, dicho al paciente (`missing_fields` del servicio).
String missingPrescriptionField(String field) => switch (field) {
      'patient.name' => 'El nombre del paciente',
      'patient.document_number' => 'El número de documento del paciente',
      'prescription.issue_date' => 'La fecha en que se hizo la fórmula',
      'medications' => 'Los medicamentos recetados',
      _ => 'Otro dato obligatorio de la fórmula',
    };

/// Aviso de la validación de la fórmula (vigente, incompleta o vencida), con qué hacer.
/// Sin estado reconocible no muestra nada.
class PrescriptionValidationNotice extends StatelessWidget {
  const PrescriptionValidationNotice({super.key, required this.validation});

  final PrescriptionValidation validation;

  @override
  Widget build(BuildContext context) {
    final vence = validation.expiresOn;
    switch (validation.status) {
      case PrescriptionValidationStatus.valid:
        return FgBanner(
          kind: FgBannerKind.exito,
          title: 'Fórmula vigente',
          message: vence == null
              ? 'Tiene los datos necesarios para reclamar tus medicamentos.'
              : 'Puedes usarla hasta el ${PendienteFormat.fechaDia(vence)}.',
        );
      case PrescriptionValidationStatus.incomplete:
        final faltan = {for (final campo in validation.missingFields) missingPrescriptionField(campo)}.toList();
        final lista = faltan.isEmpty ? '' : '\n${faltan.map((f) => '• $f').join('\n')}';
        return FgBanner(
          kind: FgBannerKind.aviso,
          title: 'A la fórmula le faltan datos',
          message: 'No encontramos estos datos en la foto:$lista\n'
              'Revisa que se vean completos y toma otra foto. Si no están en la fórmula, pide a tu médico que la complete.',
        );
      case PrescriptionValidationStatus.expired:
        return FgBanner(
          kind: FgBannerKind.error,
          title: 'La fórmula está vencida',
          message: vence == null
              ? 'Ya pasó el plazo para usarla. Pide una fórmula nueva a tu médico para reclamar tus medicamentos.'
              : 'Venció el ${PendienteFormat.fechaDia(vence)}. Pide una fórmula nueva a tu médico para reclamar tus medicamentos.',
        );
      case PrescriptionValidationStatus.unknown:
        return const SizedBox.shrink();
    }
  }
}

/// Datos impresos en la fórmula que el servicio logró leer (solo los que existen).
class PrescriptionInfoCard extends StatelessWidget {
  const PrescriptionInfoCard({super.key, required this.info});

  final PrescriptionInfo info;

  /// La fecha llega en ISO si el servicio la reconoció; si no, tal como se leyó.
  static String _fecha(String valor) {
    final dia = DateTime.tryParse(valor);
    return dia == null ? valor : PendienteFormat.fechaDia(dia);
  }

  @override
  Widget build(BuildContext context) {
    final medico = [
      if (info.prescriberName != null) info.prescriberName!,
      if (info.prescriberLicense != null) 'Registro ${info.prescriberLicense}',
    ].join(' · ');
    final datos = [
      if (info.issueDate != null) ('Fecha de la fórmula', _fecha(info.issueDate!)),
      if (info.authorizationNumber != null) ('Número de autorización', info.authorizationNumber!),
      if (medico.isNotEmpty) ('Médico', medico),
      if (info.epsName != null) ('EPS', info.epsName!),
    ];
    if (datos.isEmpty) return const SizedBox.shrink();
    return FgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text('Datos de la fórmula', style: FgText.h3)),
          for (final (etiqueta, valor) in datos)
            Padding(
              padding: const EdgeInsets.only(top: FgSpace.sp3),
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(etiqueta, style: FgText.caption),
                    Text(valor, style: FgText.body),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
