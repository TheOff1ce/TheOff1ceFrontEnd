import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../components/ui.dart';
import '../hooks/prescription_hook.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({
    super.key,
    required this.controller,
    required this.onHome,
    required this.onAnalyzeAnother,
  });
  final PrescriptionController controller;
  final VoidCallback onHome;
  final VoidCallback onAnalyzeAnother;
  @override
  Widget build(BuildContext c) {
    final r = controller.result!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado del análisis'),
        leading: IconButton(
          tooltip: 'Volver al inicio',
          onPressed: onHome,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  const Text('Resultado del análisis', style: AppText.heading),
                  const SizedBox(height: 7),
                  Text(
                    'Encontramos ${r.medications.length} ${r.medications.length == 1 ? 'medicamento' : 'medicamentos'}',
                    style: AppText.body,
                  ),
                  if (r.requiresHumanReview || r.warnings.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    AppCard(
                      color: AppColors.warning,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.warning_amber,
                                color: AppColors.warningText,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Revisión necesaria',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.warningText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Verifica la información antes de utilizarla.',
                            style: AppText.body,
                          ),
                          ...r.warnings.map(
                            (w) => Text('• $w', style: AppText.body),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (r.medications.isEmpty) ...[
                    const SizedBox(height: 18),
                    const AppCard(
                      child: Column(
                        children: [
                          Icon(Icons.search_off_outlined,
                              size: 42, color: AppColors.blue),
                          SizedBox(height: 12),
                          Text('No identificamos medicamentos',
                              style: AppText.title,
                              textAlign: TextAlign.center),
                          SizedBox(height: 6),
                          Text(
                              'Prueba con una imagen más clara, completa y bien iluminada.',
                              style: AppText.body,
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ],
                  ...r.medications.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: MedicationCard(m: m),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'La información extraída no reemplaza la indicación de un profesional de salud.',
                    style: AppText.label,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Volver al inicio',
              icon: Icons.home_outlined,
              outlined: true,
              onPressed: onHome,
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Analizar otra fórmula',
              icon: Icons.add_a_photo,
              onPressed: onAnalyzeAnother,
            ),
          ],
        ),
      ),
    );
  }
}
