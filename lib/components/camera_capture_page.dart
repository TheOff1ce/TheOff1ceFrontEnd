import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';

/// Opens the in-app camera and returns the photo, or `null` if the user closes it.
///
/// Used on the web: there `image_picker` can only open a file input, and desktop browsers
/// ignore its `capture` hint, so "Tomar foto" would open the file explorer instead of the
/// camera. This screen uses the browser camera (getUserMedia) on desktop and mobile alike.
Future<XFile?> showCameraCapture(BuildContext context) => Navigator.of(context).push<XFile>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const CameraCapturePage()),
    );

/// Why the camera cannot be shown; each case explains what the user can do.
enum CameraIssue {
  notFound('No encontramos una cámara en este dispositivo. Puedes elegir una foto de la galería.'),
  denied('El navegador no tiene permiso para usar la cámara. Actívalo en el candado de la barra de '
      'direcciones y vuelve a intentarlo, o elige una foto de la galería.'),
  busy('La cámara está siendo usada por otra aplicación. Ciérrala y vuelve a intentarlo.'),
  failed('No pudimos abrir la cámara. Vuelve a intentarlo o elige una foto de la galería.');

  const CameraIssue(this.message);

  final String message;

  static CameraIssue fromCode(String code) {
    final c = code.toLowerCase();
    if (c.contains('notfound') || c.contains('missing') || c.contains('nocamera')) return notFound;
    if (c.contains('denied') || c.contains('permission') || c.contains('notallowed')) return denied;
    if (c.contains('notreadable') || c.contains('inuse') || c.contains('abort')) return busy;
    return failed;
  }
}

class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key, this.loadCameras = availableCameras});

  /// Injected in tests.
  final Future<List<CameraDescription>> Function() loadCameras;

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  List<CameraDescription> _cameras = const [];
  int _index = 0;
  CameraController? _controller;
  CameraIssue? _issue;
  bool _starting = true;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _issue = null;
    });
    try {
      if (_cameras.isEmpty) {
        _cameras = await widget.loadCameras();
        // A prescription is photographed with the back camera when there is one.
        final back = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
        _index = back >= 0 ? back : 0;
      }
      if (_cameras.isEmpty) return _fail(CameraIssue.notFound);
      await _open(_cameras[_index]);
    } on CameraException catch (error) {
      _fail(CameraIssue.fromCode(error.code));
    } catch (_) {
      _fail(CameraIssue.failed);
    }
  }

  Future<void> _open(CameraDescription camera) async {
    final previous = _controller;
    setState(() => _controller = null);
    await previous?.dispose();
    final controller = CameraController(camera, ResolutionPreset.veryHigh, enableAudio: false);
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _starting = false;
    });
  }

  void _fail(CameraIssue issue) {
    if (!mounted) return;
    setState(() {
      _issue = issue;
      _starting = false;
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _capturing) return;
    _index = (_index + 1) % _cameras.length;
    try {
      setState(() => _starting = true);
      await _open(_cameras[_index]);
    } on CameraException catch (error) {
      _fail(CameraIssue.fromCode(error.code));
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) return;
    setState(() => _capturing = true);
    try {
      final shot = await controller.takePicture();
      // On the web the capture is a nameless blob URL; give it a name and type so the
      // upload to the AI service is a normal JPEG file, like one picked from the gallery.
      final photo = XFile.fromData(
        await shot.readAsBytes(),
        name: 'formula-${DateTime.now().millisecondsSinceEpoch}.jpg',
        mimeType: 'image/jpeg',
      );
      if (mounted) Navigator.of(context).pop(photo);
    } on CameraException catch (error) {
      _fail(CameraIssue.fromCode(error.code));
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final issue = _issue;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        titleTextStyle: context.text.titleLarge?.copyWith(color: Colors.white),
        leading: IconButton(
          tooltip: 'Cerrar cámara',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Tomar foto'),
        actions: [
          if (_cameras.length > 1 && issue == null)
            IconButton(
              tooltip: 'Cambiar de cámara',
              icon: const Icon(Icons.cameraswitch_outlined),
              onPressed: _starting || _capturing ? null : _switchCamera,
            ),
        ],
      ),
      body: SafeArea(
        child: issue != null
            ? _CameraMessage(issue: issue, onRetry: _start)
            : Column(children: [
                Expanded(
                  child: Center(
                    child: controller != null && controller.value.isInitialized
                        ? Semantics(
                            label: 'Vista previa de la cámara',
                            child: AspectRatio(
                              aspectRatio: controller.value.aspectRatio,
                              child: CameraPreview(controller),
                            ),
                          )
                        : const CircularProgressIndicator(color: Colors.white, semanticsLabel: 'Abriendo la cámara'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Column(children: [
                    const Text(
                      'Encuadra toda la fórmula, con buena luz y sin reflejos.',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Semantics(
                      button: true,
                      label: 'Tomar la foto',
                      child: InkResponse(
                        onTap: controller == null || _capturing ? null : _capture,
                        radius: 44,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          padding: const EdgeInsets.all(5),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: controller == null || _capturing ? Colors.white38 : Colors.white,
                            ),
                            child: _capturing
                                ? const Padding(
                                    padding: EdgeInsets.all(18),
                                    child: CircularProgressIndicator(strokeWidth: 3),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ]),
      ),
    );
  }
}

class _CameraMessage extends StatelessWidget {
  const _CameraMessage({required this.issue, required this.onRetry});

  final CameraIssue issue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white, size: 48),
            const SizedBox(height: AppSpacing.m),
            Semantics(
              liveRegion: true,
              child: Text(issue.message, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
            ),
            const SizedBox(height: AppSpacing.l),
            Wrap(spacing: AppSpacing.s, alignment: WrapAlignment.center, children: [
              if (issue != CameraIssue.notFound) FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver'),
              ),
            ]),
          ]),
        ),
      );
}
