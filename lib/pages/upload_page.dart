import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/theme/app_theme.dart';
import '../components/analysis_widgets.dart';
import '../components/camera_capture_page.dart';
import '../components/feedback.dart';
import '../components/ui.dart';
import '../errors/app_error.dart';
import '../services/image_service.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key, required this.onBack, required this.onAnalyze, this.images, this.takePhoto});

  final VoidCallback onBack;
  final ValueChanged<XFile> onAnalyze;
  final ImageService? images;

  /// In-app camera. On the web it defaults to [showCameraCapture], because the browser
  /// file input that `image_picker` uses opens the file explorer on desktop.
  final Future<XFile?> Function(BuildContext context)? takePhoto;

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  late final ImageService _images = widget.images ?? ImageService();
  XFile? _image;
  bool _selecting = false;

  Future<void> _pick({required bool camera}) async {
    if (_selecting) return;
    setState(() => _selecting = true);
    try {
      final image = camera ? await _takePhoto() : await _images.gallery();
      if (mounted && image != null) setState(() => _image = image);
    } on AppError catch (error) {
      ErrorReporter.report(error);
      if (mounted) showAppSnackBar(context, error.userMessage);
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  Future<XFile?> _takePhoto() {
    final takePhoto = widget.takePhoto ?? (kIsWeb ? showCameraCapture : null);
    return takePhoto != null ? takePhoto(context) : _images.camera();
  }

  /// "Quitar imagen" is reversible with "Deshacer" (frontend-guardian §2.6).
  void _remove() {
    final removed = _image;
    setState(() => _image = null);
    if (removed == null) return;
    showAppSnackBar(
      context,
      'Quitamos la imagen.',
      action: SnackBarAction(label: 'Deshacer', onPressed: () {
        if (mounted) setState(() => _image = removed);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analizar fórmula'),
        leading: IconButton(tooltip: 'Volver al inicio', onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.s, AppSpacing.xl, AppSpacing.xxl),
              children: [
                const StepIndicator(activeStep: 1),
                const SizedBox(height: AppSpacing.xl),
                Semantics(
                  header: true,
                  child: Text(
                    image == null ? 'Analiza tu fórmula médica.' : 'Imagen seleccionada.',
                    style: context.text.headlineSmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  image == null
                      ? 'Sube una foto clara y te ayudaremos a identificar los medicamentos indicados.'
                      : 'Revisa que el texto esté completo y sea legible antes de iniciar el análisis.',
                  style: context.text.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: image == null ? const _EmptyUpload() : _SelectedUpload(image: image),
                ),
                const SizedBox(height: AppSpacing.xl - 2),
                if (image == null) ...[
                  _UploadChoice(
                    icon: Icons.camera_alt_outlined,
                    title: 'Tomar foto',
                    detail: 'Usa la cámara de tu dispositivo',
                    loading: _selecting,
                    onTap: () => _pick(camera: true),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  _UploadChoice(
                    icon: Icons.photo_library_outlined,
                    title: 'Elegir de galería',
                    detail: 'Selecciona una imagen guardada',
                    loading: _selecting,
                    onTap: () => _pick(camera: false),
                  ),
                ] else ...[
                  FilledButton.icon(
                    onPressed: _selecting ? null : () => widget.onAnalyze(image),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Analizar fórmula'),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  OutlinedButton.icon(
                    onPressed: _selecting ? null : _showImageOptions,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Cambiar imagen'),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                const PhotoTips(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImageOptions() => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.xl),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Cambiar imagen', style: sheetContext.text.headlineSmall),
              const SizedBox(height: AppSpacing.l),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _pick(camera: true);
                },
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Tomar otra foto'),
              ),
              const SizedBox(height: AppSpacing.s),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _pick(camera: false);
                },
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Elegir otra de la galería'),
              ),
              const SizedBox(height: AppSpacing.s),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: sheetContext.colors.error),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _remove();
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Quitar imagen'),
              ),
              TextButton(onPressed: () => Navigator.pop(sheetContext), child: const Text('Cancelar')),
            ]),
          ),
        ),
      );
}

class _EmptyUpload extends StatelessWidget {
  const _EmptyUpload();

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('empty-upload'),
        constraints: const BoxConstraints(minHeight: 190),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: context.status.brandSurface,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          border: Border.all(color: context.status.decorative),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ExcludeSemantics(child: Icon(Icons.add_a_photo_outlined, size: 46, color: context.colors.primary)),
          const SizedBox(height: AppSpacing.m),
          Text('Aún no has elegido una fórmula', style: context.text.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Toma una foto o elige una imagen desde tu galería.',
            style: context.text.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ]),
      );
}

class _SelectedUpload extends StatelessWidget {
  const _SelectedUpload({required this.image});

  final XFile image;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('selected-upload'),
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          border: Border.all(color: context.status.decorative),
        ),
        child: PrescriptionImagePreview(image: image, maxHeight: 240),
      );
}

class _UploadChoice extends StatelessWidget {
  const _UploadChoice({
    required this.icon,
    required this.title,
    required this.detail,
    required this.loading,
    required this.onTap,
  });

  final IconData icon;
  final String title, detail;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: !loading,
        child: Material(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.l),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.l),
            onTap: loading ? null : onTap,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.l),
                border: Border.all(color: context.colors.outline),
              ),
              child: Row(children: [
                CircleAvatar(
                  backgroundColor: context.status.brandSurface,
                  child: loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : ExcludeSemantics(child: Icon(icon, color: context.colors.primary)),
                ),
                const SizedBox(width: AppSpacing.m + 2),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: context.text.titleMedium),
                    const SizedBox(height: 2),
                    Text(detail, style: context.text.bodySmall),
                  ]),
                ),
                ExcludeSemantics(child: Icon(Icons.chevron_right_rounded, color: context.colors.secondary)),
              ]),
            ),
          ),
        ),
      );
}
