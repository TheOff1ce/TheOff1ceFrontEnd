import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/theme/app_theme.dart';
import '../types/api_error.dart';
import '../types/medication.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.color});
  final Widget child;
  final Color? color;
  @override
  Widget build(BuildContext c) => Card(
        color: color ?? Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      );
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  @override
  Widget build(BuildContext c) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon), const SizedBox(width: 9)],
        Text(label),
      ],
    );
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(56)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(onPressed: onPressed, style: style, child: child)
          : FilledButton(onPressed: onPressed, style: style, child: child),
    );
  }
}

class PrescriptionImagePreview extends StatelessWidget {
  const PrescriptionImagePreview({super.key, required this.image});
  final XFile image;
  @override
  Widget build(BuildContext context) {
    final imageWidget = kIsWeb
        ? Image.network(
            image.path,
            fit: BoxFit.contain,
            errorBuilder: _imageError,
          )
        : Image.file(
            File(image.path),
            fit: BoxFit.contain,
            errorBuilder: _imageError,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(aspectRatio: .78, child: imageWidget),
    );
  }

  Widget _imageError(
      BuildContext context, Object error, StackTrace? stackTrace) {
    return const Center(child: Icon(Icons.broken_image, size: 50));
  }
}

class AppLoading extends StatelessWidget {
  const AppLoading({super.key});
  @override
  Widget build(BuildContext c) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(strokeWidth: 5),
            ),
            SizedBox(height: 25),
            Text('Analizando tu fórmula...', style: AppText.heading),
            SizedBox(height: 10),
            Text(
              'Estamos identificando los medicamentos y organizando la información.',
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

class AppError extends StatelessWidget {
  const AppError({super.key, required this.error, required this.retry});
  final ApiError error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext c) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 54),
              const SizedBox(height: 16),
              const Text(
                'No pudimos analizar la fórmula',
                style: AppText.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(error.message,
                  style: AppText.body, textAlign: TextAlign.center),
              const SizedBox(height: 22),
              AppButton(
                  label: 'Reintentar', icon: Icons.refresh, onPressed: retry),
            ],
          ),
        ),
      );
}

class MedicationCard extends StatelessWidget {
  const MedicationCard({super.key, required this.m});
  final Medication m;
  @override
  Widget build(BuildContext c) {
    final top = [
      m.concentration,
      m.pharmaceuticalForm,
    ].whereType<String>().join(' · ');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.light,
                child: Icon(Icons.medication, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(m.name, style: AppText.title)),
            ],
          ),
          if (top.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(top, style: AppText.body),
          ],
          ...{
            'Principio activo': m.activeIngredient,
            'Presentación': m.presentation,
            'Dosis': m.dose,
            'Frecuencia': m.frequency,
            'Duración': m.duration,
            'Cantidad': m.quantity,
            'Instrucciones': m.instructions,
          }.entries.where((e) => e.value != null).map(
                (e) => Padding(
                  padding: const EdgeInsets.only(top: 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.key, style: AppText.label),
                      Text(
                        e.value!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
          if (m.confidence != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            ConfidenceIndicator(value: m.confidence!),
          ],
        ],
      ),
    );
  }
}

class ConfidenceIndicator extends StatelessWidget {
  const ConfidenceIndicator({super.key, required this.value});
  final double value;
  @override
  Widget build(BuildContext c) {
    final v = value <= 1 ? value : value / 100;
    final low = v < .7;
    final color = low ? AppColors.warningText : Colors.green;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: low ? AppColors.warning : const Color(0xFFE1F5EC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confianza de extracción: ${(v * 100).round()}%',
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: v.clamp(0, 1).toDouble(),
            color: color,
            backgroundColor: Colors.white,
          ),
          if (low)
            const Padding(
              padding: EdgeInsets.only(top: 7),
              child: Text(
                'La confianza refleja la extracción del texto, no una certeza médica.',
                style: TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
