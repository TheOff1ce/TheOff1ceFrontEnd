import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/theme/app_theme.dart';
import '../app/theme/farmago_tokens.dart';
import 'farmago/feedback.dart';

/// Prescription photo preview decoded at display size, not at camera size (FE-018).
class PrescriptionImagePreview extends StatelessWidget {
  const PrescriptionImagePreview({super.key, required this.image, this.maxHeight = 240});

  final XFile image;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheHeight = (maxHeight * pixelRatio).round();
    final imageWidget = kIsWeb
        ? Image.network(image.path, fit: BoxFit.contain, cacheHeight: cacheHeight, errorBuilder: _imageError)
        : Image.file(File(image.path), fit: BoxFit.contain, cacheHeight: cacheHeight, errorBuilder: _imageError);
    return Semantics(
      image: true,
      label: 'Vista previa de la fórmula seleccionada',
      child: SizedBox(
        height: maxHeight,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(FgRadius.md),
          child: ColoredBox(color: FgColors.fondoHundido, child: ExcludeSemantics(child: imageWidget)),
        ),
      ),
    );
  }

  Widget _imageError(BuildContext context, Object error, StackTrace? stackTrace) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.broken_image_outlined, size: 44),
          const SizedBox(height: AppSpacing.s),
          Text('No pudimos mostrar la vista previa.', style: context.text.bodySmall),
        ]),
      );
}

/// Visible notice while the session cannot be refreshed (FE-003 / FE-004).
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key, required this.visible, this.onRetry});

  final bool visible;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: FgSpace.sp4),
      child: FgBanner(
        kind: FgBannerKind.aviso,
        message: 'Sin conexión con el servicio. Seguiremos intentando; puedes seguir usando la app.',
        actionLabel: onRetry == null ? null : 'Reintentar',
        onAction: onRetry,
      ),
    );
  }
}
