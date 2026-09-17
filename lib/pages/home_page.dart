import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../components/ui.dart';
import '../hooks/prescription_hook.dart';
import 'upload_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller});

  final PrescriptionController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.local_pharmacy, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Farma Go',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.light,
                  ),
                  child: const Icon(
                    Icons.document_scanner,
                    color: AppColors.primary,
                    size: 90,
                  ),
                ),
              ),
              const SizedBox(height: 42),
              const Text(
                'Tu fórmula médica, más fácil de entender y gestionar.',
                style: AppText.display,
              ),
              const SizedBox(height: 14),
              const Text(
                'Sube una foto de tu fórmula médica y Farma Go identificará los medicamentos indicados.',
                style: AppText.body,
              ),
              const Spacer(),
              AppButton(
                label: 'Analizar fórmula',
                icon: Icons.document_scanner,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UploadPage(controller: controller),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
