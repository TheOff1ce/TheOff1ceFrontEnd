import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';

/// Tarjeta del manual (§8.9, §23): [FgDecor.tarjeta] y padding de 20 en móvil / 24 en pantallas
/// anchas. Única tarjeta de la app (reemplaza a `AppCard`).
class FgCard extends StatelessWidget {
  const FgCard({super.key, required this.child, this.destacada = false, this.aviso = false, this.color});

  final Widget child;

  /// Borde azul de 2 px para lo que pide atención ahora (una sola por pantalla).
  final bool destacada;

  /// Borde de 2 px en tono de aviso cuando algo pide revisión.
  final bool aviso;

  /// Fondo distinto de la superficie (por ejemplo `azul100`).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final compacto = FgBreakpoint.esCompacto(MediaQuery.sizeOf(context).width);
    final base = FgDecor.tarjeta(destacada: destacada, color: color ?? FgColors.superficie);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compacto ? FgSpace.sp4h : FgSpace.sp5),
      decoration: aviso ? base.copyWith(border: Border.all(color: FgColors.riesgoSolid, width: FgBorder.w2)) : base,
      child: child,
    );
  }
}
