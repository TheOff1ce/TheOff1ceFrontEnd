import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';

/// Anillo de foco del manual (§14): 3 px `--azul-800` con separación de 2 px.
///
/// Se dibuja fuera del control (o dentro, con [inset], para filas de tabla que recortan su
/// contenido). Con el puntero solo aparece en campos de texto; con teclado, en todos los controles.
class FgFocusRing extends StatefulWidget {
  const FgFocusRing({
    super.key,
    required this.focusNode,
    required this.child,
    this.radius = FgRadius.md,
    this.alwaysVisible = false,
    this.inset = false,
  });

  final FocusNode focusNode;
  final Widget child;
  final double radius;

  /// Mostrarlo también cuando el foco viene del puntero (campos de texto).
  final bool alwaysVisible;

  /// Dibujarlo dentro de los límites del hijo.
  final bool inset;

  /// Separación entre el control y el anillo.
  static const separacion = 2.0;

  @override
  State<FgFocusRing> createState() => _FgFocusRingState();
}

class _FgFocusRingState extends State<FgFocusRing> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_changed);
  }

  @override
  void didUpdateWidget(FgFocusRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_changed);
      widget.focusNode.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  bool get _visible =>
      widget.focusNode.hasFocus &&
      (widget.alwaysVisible || FocusManager.instance.highlightMode == FocusHighlightMode.traditional);

  @override
  Widget build(BuildContext context) {
    final fuera = widget.inset ? 0.0 : FgBorder.foco + FgFocusRing.separacion;
    return Stack(
      clipBehavior: Clip.none,
      // Conserva las restricciones del padre: un botón de ancho completo debe seguir estirándose.
      fit: StackFit.passthrough,
      children: [
        widget.child,
        if (_visible)
          Positioned(
            left: -fuera,
            top: -fuera,
            right: -fuera,
            bottom: -fuera,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.radius + fuera),
                  border: Border.all(color: FgColors.azul800, width: FgBorder.foco),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
