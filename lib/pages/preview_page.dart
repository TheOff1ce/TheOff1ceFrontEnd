import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/theme/app_theme.dart';
import '../components/ui.dart';
import '../hooks/prescription_hook.dart';
import 'analysis_page.dart';

class PreviewPage extends StatelessWidget {
  const PreviewPage({super.key, required this.controller, required this.image});
  final PrescriptionController controller;
  final XFile image;
  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Vista previa')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PrescriptionImagePreview(image: image),
                      const SizedBox(height: 22),
                      const Text(
                        '¿Esta imagen se ve bien?',
                        style: AppText.heading,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Asegúrate de que el texto sea legible antes de analizarla.',
                        style: AppText.body,
                      ),
                    ],
                  ),
                ),
              ),
              AppButton(
                label: 'Cambiar imagen',
                icon: Icons.refresh,
                outlined: true,
                onPressed: () => Navigator.pop(c),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Analizar fórmula',
                icon: Icons.auto_awesome,
                onPressed: () => Navigator.push(
                  c,
                  MaterialPageRoute(
                    builder: (_) =>
                        AnalysisPage(controller: controller, image: image),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
