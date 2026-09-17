import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../components/ui.dart';
import '../hooks/prescription_hook.dart';
import '../services/image_service.dart';
import 'preview_page.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key, required this.controller});
  final PrescriptionController controller;
  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final images = ImageService();
  Future<void> pick(bool camera) async {
    final image = camera ? await images.camera() : await images.gallery();
    if (!mounted || image == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PreviewPage(controller: widget.controller, image: image),
      ),
    );
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Cargar fórmula')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Carga tu fórmula médica', style: AppText.heading),
              const SizedBox(height: 8),
              const Text(
                'Elige una foto clara y legible para obtener mejores resultados.',
                style: AppText.body,
              ),
              const Spacer(),
              _Choice(
                icon: Icons.camera_alt,
                title: 'Tomar una foto',
                detail: 'Usa la cámara de tu dispositivo',
                tap: () => pick(true),
              ),
              const Padding(
                padding: EdgeInsets.all(14),
                child: Center(child: Text('o', style: AppText.label)),
              ),
              _Choice(
                icon: Icons.photo_library,
                title: 'Elegir de galería',
                detail: 'Selecciona una imagen guardada',
                tap: () => pick(false),
              ),
              const Spacer(),
            ],
          ),
        ),
      );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.title,
    required this.detail,
    required this.tap,
  });
  final IconData icon;
  final String title, detail;
  final VoidCallback tap;
  @override
  Widget build(BuildContext c) => InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(24),
        child: AppCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: AppColors.light,
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.title),
                    Text(detail, style: AppText.body),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      );
}
