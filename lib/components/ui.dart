import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/theme/app_theme.dart';
import '../app/theme/farmago_tokens.dart';
import 'farmago/feedback.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.color, this.bordered = false});

  final Widget child;
  final Color? color;
  final bool bordered;

  /// Tarjeta del manual (§8.9, §23): [FgDecor.tarjeta], padding 20/24.
  /// [bordered] la resalta (borde de 2 px en tono de aviso) cuando algo pide revisión.
  @override
  Widget build(BuildContext context) {
    final compacto = FgBreakpoint.esCompacto(MediaQuery.sizeOf(context).width);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compacto ? FgSpace.sp4h : FgSpace.sp5),
      decoration: FgDecor.tarjeta(color: color ?? FgColors.superficie).copyWith(
        border: bordered ? Border.all(color: FgColors.riesgoSolid, width: FgBorder.w2) : null,
      ),
      child: child,
    );
  }
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
