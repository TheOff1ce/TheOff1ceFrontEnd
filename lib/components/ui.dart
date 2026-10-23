import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.color, this.bordered = false});

  final Widget child;
  final Color? color;
  final bool bordered;

  @override
  Widget build(BuildContext context) => Card(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          side: bordered ? BorderSide(color: context.colors.outline) : BorderSide.none,
        ),
        child: Padding(padding: const EdgeInsets.all(AppSpacing.l + 4), child: child),
      );
}

class AppButton extends StatelessWidget {
  const AppButton({super.key, required this.label, required this.onPressed, this.icon, this.outlined = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final iconWidget = icon == null ? null : Icon(icon);
    final text = Text(label, textAlign: TextAlign.center);
    final Widget button = outlined
        ? (iconWidget == null
            ? OutlinedButton(onPressed: onPressed, child: text)
            : OutlinedButton.icon(onPressed: onPressed, icon: iconWidget, label: text))
        : (iconWidget == null
            ? FilledButton(onPressed: onPressed, child: text)
            : FilledButton.icon(onPressed: onPressed, icon: iconWidget, label: text));
    return SizedBox(width: double.infinity, child: button);
  }
}

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
          borderRadius: BorderRadius.circular(AppRadii.m),
          child: ColoredBox(color: context.status.brandSurface, child: ExcludeSemantics(child: imageWidget)),
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
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppSpacing.l),
        padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.s, AppSpacing.s),
        decoration: BoxDecoration(
          color: context.status.warningContainer,
          borderRadius: BorderRadius.circular(AppRadii.s),
        ),
        child: Row(children: [
          Icon(Icons.wifi_off_rounded, color: context.status.onWarningContainer),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              'Sin conexión con el servicio. Seguiremos intentando; puedes seguir usando la app.',
              style: context.text.bodySmall?.copyWith(color: context.status.onWarningContainer),
            ),
          ),
          if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ]),
      ),
    );
  }
}
