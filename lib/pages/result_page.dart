import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../components/farmago/estampado.dart';
import '../components/analysis_widgets.dart';
import '../components/medication_card.dart';
import '../types/analysis_response.dart';
import '../components/farmago/card.dart';
import '../components/farmago/buttons.dart';
import '../types/order.dart';
import '../utils/pedido_desde_formula.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({
    super.key,
    required this.result,
    required this.onHome,
    required this.onAnalyzeAnother,
    this.onRequestDelivery,
  });

  final AnalysisResponse result;
  final VoidCallback onHome;
  final VoidCallback onAnalyzeAnother;

  /// Lleva a «Pedir a casa» con los medicamentos leídos. Solo para pacientes (null = no se muestra).
  final ValueChanged<List<OrderItem>>? onRequestDelivery;

  @override
  Widget build(BuildContext context) {
    final count = result.medications.length;
    final pedido = onRequestDelivery == null ? const <OrderItem>[] : pedidoDesdeFormula(result);
    final puedePedir = pedido.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado del análisis'),
        leading: IconButton(tooltip: 'Volver al inicio', onPressed: onHome, icon: const Icon(Icons.arrow_back)),
      ),
      body: FgFondo(child: SafeArea(
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
                    if (result.patient != null) ...[
                      const SizedBox(height: AppSpacing.l),
                      _PatientCard(patient: result.patient!),
                    ],
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
                    if (result.documentStored) ...[
                      const SizedBox(height: AppSpacing.l),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.cloud_done_outlined, size: 18, color: context.status.mutedText),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text('Guardamos una copia privada de tu fórmula.', style: context.text.bodySmall),
                        ),
                      ]),
                    ],
                    const SizedBox(height: AppSpacing.l),
                    Text(
                      'La información extraída no reemplaza la indicación de un profesional de salud.',
                      style: context.text.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ]),
                ),
                const SizedBox(height: AppSpacing.m),
                // Siguiente paso natural para el paciente: pedirlos a casa (acción principal).
                if (puedePedir) ...[
                  FgButton(
                    label: pedido.length == 1 ? 'Pedir este medicamento a casa' : 'Pedir estos medicamentos a casa',
                    icon: Icons.delivery_dining,
                    size: FgButtonSize.lg,
                    expand: true,
                    onPressed: () => onRequestDelivery!(pedido),
                  ),
                  const SizedBox(height: AppSpacing.s + 2),
                ],
                FgButton(
                  label: 'Analizar otra fórmula',
                  icon: Icons.add_a_photo_outlined,
                  size: puedePedir ? FgButtonSize.md : FgButtonSize.lg,
                  variant: puedePedir ? FgButtonVariant.secondary : FgButtonVariant.primary,
                  expand: true,
                  onPressed: onAnalyzeAnother,
                ),
                const SizedBox(height: AppSpacing.s + 2),
                FgButton(
                  label: 'Volver al inicio',
                  icon: Icons.home_outlined,
                  variant: puedePedir ? FgButtonVariant.ghost : FgButtonVariant.secondary,
                  expand: true,
                  onPressed: onHome,
                ),
              ]),
            ),
          ),
        ),
      )),
    );
  }
}

class _ReviewNotice extends StatelessWidget {
  const _ReviewNotice({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    final status = context.status;
    return FgCard(
      color: status.warningContainer,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.warning_amber, color: status.onWarningContainer),
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
  Widget build(BuildContext context) => FgCard(
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

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient});

  final PrescriptionPatient patient;

  @override
  Widget build(BuildContext context) => FgCard(
        aviso: true,
        child: Row(children: [
          Icon(Icons.person_outline, color: context.colors.primary),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Paciente', style: context.text.labelLarge),
              Text(patient.name ?? 'Nombre no legible', style: context.text.titleMedium),
              if (patient.document != null) Text(patient.document!, style: context.text.bodySmall),
            ]),
          ),
        ]),
      );
}
