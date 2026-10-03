import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/theme/app_theme.dart';
import '../components/ui.dart';
import '../services/image_service.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({
    super.key,
    required this.onBack,
    required this.onAnalyze,
  });
  final VoidCallback onBack;
  final ValueChanged<XFile> onAnalyze;
  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final _images = ImageService();
  XFile? _image;
  bool _selecting = false;

  Future<void> _pick(bool camera) async {
    if (_selecting) return;
    setState(() => _selecting = true);
    try {
      final image = camera ? await _images.camera() : await _images.gallery();
      if (mounted && image != null) {
        setState(() => _image = image);
      }
    } on ImagePickFailure {
      if (mounted) {
        _message(
            'No pudimos seleccionar la imagen. Revisa los permisos e inténtalo otra vez.');
      }
    } finally {
      if (mounted) {
        setState(() => _selecting = false);
      }
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Analizar fórmula'),
          leading: IconButton(
            tooltip: 'Volver al inicio',
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
                children: [
                  const _StepIndicator(activeStep: 1),
                  const SizedBox(height: 24),
                  Text(
                      _image == null
                          ? 'Analiza tu fórmula médica.'
                          : 'Imagen seleccionada.',
                      style: AppText.heading),
                  const SizedBox(height: 8),
                  Text(
                    _image == null
                        ? 'Sube una foto clara y te ayudaremos a identificar los medicamentos indicados.'
                        : 'Revisa que el texto esté completo y sea legible antes de iniciar el análisis.',
                    style: AppText.body,
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _image == null
                        ? _emptyUpload()
                        : _selectedUpload(_image!),
                  ),
                  const SizedBox(height: 22),
                  if (_image == null) ...[
                    _UploadChoice(
                        icon: Icons.camera_alt_outlined,
                        title: 'Tomar foto',
                        detail: 'Usa la cámara de tu dispositivo',
                        loading: _selecting,
                        onTap: () => _pick(true)),
                    const SizedBox(height: 12),
                    _UploadChoice(
                        icon: Icons.photo_library_outlined,
                        title: 'Elegir de galería',
                        detail: 'Selecciona una imagen guardada',
                        loading: _selecting,
                        onTap: () => _pick(false)),
                  ] else ...[
                    OutlinedButton.icon(
                        onPressed:
                            _selecting ? null : () => _showImageOptions(),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Cambiar imagen')),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => widget.onAnalyze(_image!),
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: const Text('Analizar fórmula'),
                    ),
                  ],
                  const SizedBox(height: 26),
                  const _PhotoTips(),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _emptyUpload() => Container(
        key: const ValueKey('empty-upload'),
        height: 190,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: AppColors.light,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.sky)),
        child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 46, color: AppColors.navy),
              SizedBox(height: 12),
              Text('Sube tu fórmula médica', style: AppText.title),
              SizedBox(height: 5),
              Text('Toma una foto o elige una imagen desde tu galería.',
                  style: AppText.body, textAlign: TextAlign.center),
            ]),
      );

  Widget _selectedUpload(XFile image) => Container(
        key: const ValueKey('selected-upload'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.sky)),
        child: PrescriptionImagePreview(image: image, maxHeight: 240),
      );

  void _showImageOptions() => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Cambiar imagen', style: AppText.heading),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _pick(true);
                    },
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Tomar foto')),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _pick(false);
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Elegir de galería')),
                const SizedBox(height: 10),
                TextButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      setState(() => _image = null);
                    },
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                    label: const Text('Quitar imagen',
                        style: TextStyle(color: AppColors.error))),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Cancelar'),
                ),
              ]),
        )),
      );
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.activeStep});
  final int activeStep;
  @override
  Widget build(BuildContext context) => Row(children: [
        _step('1', 'Foto', activeStep >= 1),
        const Expanded(child: Divider(color: AppColors.sky)),
        _step('2', 'Revisar', activeStep >= 2),
        const Expanded(child: Divider(color: AppColors.sky)),
        _step('3', 'Resultado', activeStep >= 3),
      ]);
  Widget _step(String number, String label, bool active) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(
            radius: 12,
            backgroundColor: active ? AppColors.navy : AppColors.sky,
            child: Text(number,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: active ? Colors.white : AppColors.navy))),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.navy : AppColors.secondary)),
      ]);
}

class _UploadChoice extends StatelessWidget {
  const _UploadChoice(
      {required this.icon,
      required this.title,
      required this.detail,
      required this.loading,
      required this.onTap});
  final IconData icon;
  final String title, detail;
  final bool loading;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: loading ? null : onTap,
            child: Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.sky)),
              child: Row(children: [
                CircleAvatar(
                    backgroundColor: AppColors.light,
                    child: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(icon, color: AppColors.navy)),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title, style: AppText.title),
                      const SizedBox(height: 3),
                      Text(detail, style: AppText.body)
                    ])),
                const Icon(Icons.chevron_right_rounded, color: AppColors.blue),
              ]),
            )),
      );
}

class _PhotoTips extends StatelessWidget {
  const _PhotoTips();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFFF1F8FD),
            borderRadius: BorderRadius.circular(18)),
        child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Para una mejor lectura', style: AppText.title),
              SizedBox(height: 9),
              _Tip('Usa buena iluminación'),
              _Tip('Incluye todo el texto de la fórmula'),
              _Tip('Evita fotos borrosas o con reflejos'),
            ]),
      );
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(children: [
        const Icon(Icons.check_circle_outline,
            size: 17, color: AppColors.success),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppText.body))
      ]));
}
