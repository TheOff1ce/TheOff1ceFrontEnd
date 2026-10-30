import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/farmago_tokens.dart';
import 'buttons.dart';

/// Abre un panel lateral (§7.4): detalle de un registro sin salir de la lista (tablet y desktop).
///
/// Desliza desde la derecha en 320 ms, con esquinas izquierdas de 24 px, sombra `--e4` y el fondo
/// `--scrim-suave`. Un clic en el fondo o `Esc` lo cierran (si [PopScope] no lo impide). En móvil
/// no se usa: el detalle es una pantalla completa.
Future<T?> showFgSidePanel<T>(
  BuildContext context, {
  required String etiquetaSemantica,
  required WidgetBuilder builder,
  double ancho = FgSize.panel,
}) {
  final duracion = FgMotion.reducir(context, FgMotion.lenta);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar panel',
    barrierColor: FgColors.scrimSuave,
    transitionDuration: duracion,
    // La ruta del panel no hereda el tema de la pantalla que la abre: se aplica aquí.
    pageBuilder: (contexto, _, __) => FarmaGoThemed(
      child: _MarcoPanel(ancho: ancho, etiqueta: etiquetaSemantica, child: builder(contexto)),
    ),
    transitionBuilder: (contexto, animacion, _, hijo) => SlideTransition(
      position: animacion.drive(
        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: FgMotion.ease)),
      ),
      child: hijo,
    ),
  );
}

class _MarcoPanel extends StatelessWidget {
  const _MarcoPanel({required this.ancho, required this.etiqueta, required this.child});

  final double ancho;
  final String etiqueta;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final disponible = MediaQuery.sizeOf(context).width * .9;
    const esquinas = BorderRadius.horizontal(left: Radius.circular(FgRadius.lg));
    return Align(
      alignment: Alignment.centerRight,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).maybePop(),
        },
        child: Focus(
          autofocus: true,
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: etiqueta,
            child: SizedBox(
              width: math.min(ancho, disponible),
              height: double.infinity,
              child: DecoratedBox(
                decoration: const BoxDecoration(color: FgColors.superficie, borderRadius: esquinas, boxShadow: FgShadow.e4),
                child: ClipRRect(
                  borderRadius: esquinas,
                  child: Material(color: FgColors.superficie, child: SafeArea(child: child)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Estructura del panel (§7.4): encabezado fijo (título `.t-h2` + cerrar 48×48), cuerpo con scroll
/// y pie fijo opcional.
class FgPanelScaffold extends StatelessWidget {
  const FgPanelScaffold({
    super.key,
    required this.titulo,
    required this.cuerpo,
    required this.onCerrar,
    this.pie,
    this.iconoCerrar = Icons.close_rounded,
    this.tooltipCerrar = 'Cerrar',
  });

  final String titulo;
  final Widget cuerpo;
  final VoidCallback onCerrar;
  final Widget? pie;
  final IconData iconoCerrar;
  final String tooltipCerrar;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(FgSpace.sp6, FgSpace.sp5, FgSpace.sp5, FgSpace.sp5),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(titulo, style: FgText.h2, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: FgSpace.sp2),
                FgIconButton(icon: iconoCerrar, tooltip: tooltipCerrar, onPressed: onCerrar),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(FgSpace.sp6, 0, FgSpace.sp6, FgSpace.sp6),
              child: Align(alignment: Alignment.topLeft, child: SizedBox(width: double.infinity, child: cuerpo)),
            ),
          ),
          if (pie != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: FgSpace.sp6, vertical: FgSpace.sp5),
              decoration: const BoxDecoration(
                color: FgColors.superficie,
                border: Border(top: BorderSide(color: FgColors.linea, width: FgBorder.w1)),
              ),
              child: pie,
            ),
        ],
      );
}
