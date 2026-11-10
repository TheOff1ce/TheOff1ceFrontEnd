import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';
import 'buttons.dart';

/// Confirmación antes de una acción que no se deshace (prevención de errores).
///
/// - El título es la pregunta; el mensaje dice la consecuencia.
/// - Los botones llevan el verbo de la acción, nunca "Sí / No": se entienden sin leer el título.
/// - La salida segura va primero y es la que responde a Escape o a tocar fuera.
///
/// Devuelve `true` solo si la persona eligió confirmar.
Future<bool> showFgConfirm(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required String confirmar,
  String cancelar = 'Volver',
  bool peligro = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: FgColors.superficie,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FgRadius.lg)),
      insetPadding: const EdgeInsets.all(FgSpace.sp4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: FgSize.dialogSm),
        child: Padding(
          padding: const EdgeInsets.all(FgSpace.sp5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, namesRoute: true, child: Text(titulo, style: FgText.h3)),
              const SizedBox(height: FgSpace.sp2),
              Text(mensaje, style: FgText.body.copyWith(color: FgColors.inkSoft)),
              const SizedBox(height: FgSpace.sp5),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: FgSpace.sp3,
                runSpacing: FgSpace.sp3,
                children: [
                  FgButton(
                    label: cancelar,
                    variant: FgButtonVariant.secondary,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  FgButton(
                    label: confirmar,
                    variant: peligro ? FgButtonVariant.danger : FgButtonVariant.primary,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}
