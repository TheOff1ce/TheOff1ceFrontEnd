import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';
import '../../types/pendiente.dart';
import 'deadline_ring.dart';

/// Sello de estado (§8.8): anillo en miniatura + palabra. Nunca solo color.
///
/// - Sello (por defecto): 32 px de alto, sin fondo ni borde. Para tablas, listas y resúmenes.
/// - Sello destacado: 40 px, pastilla `--ink`. Solo uno por pantalla.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.estado, this.destacado = false, this.fraccion = .6});

  final CumplimientoPlazo estado;
  final bool destacado;

  /// Forma del arco del estado vigente en la miniatura (decorativa).
  final double fraccion;

  @override
  Widget build(BuildContext context) {
    final palabra = estado.etiqueta;
    if (destacado) {
      return Semantics(
        label: 'Estado: $palabra',
        excludeSemantics: true,
        child: Container(
          height: 40,
          padding: const EdgeInsets.only(left: FgSpace.sp2, right: FgSpace.sp4),
          decoration: BoxDecoration(color: FgColors.ink, borderRadius: BorderRadius.circular(FgRadius.pill)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: estado.solido, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(estado.simbolo, size: 14, color: FgColors.blanco),
              ),
              const SizedBox(width: FgSpace.sp2),
              Flexible(
                child: Text(
                  palabra,
                  style: FgText.caption.copyWith(color: FgColors.blanco, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Semantics(
      label: 'Estado: $palabra',
      excludeSemantics: true,
      child: SizedBox(
        height: 32,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EstadoAnillo(estado: estado, diametro: 24, trazo: 3, fraccion: fraccion, tamanoSimbolo: 12),
            const SizedBox(width: FgSpace.sp2),
            Flexible(
              child: Text(
                palabra,
                style: FgText.caption.copyWith(color: estado.texto, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
