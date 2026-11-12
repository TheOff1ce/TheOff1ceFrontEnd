import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';
import 'focus_ring.dart';

/// `secondary`: tonal (§23), fondo azul 100 sin borde. `marca`: contorno de 1 px en `--verde-700`
/// (manual §3.1).
enum FgButtonVariant { primary, secondary, ghost, danger, marca }

enum FgButtonSize { lg, md, sm }

/// Botón del manual (§8.1). Un solo primario por pantalla o ventana.
///
/// - `lg` 56 · `md` 48 · `sm` 40 (solo desktop denso).
/// - Cargando: texto en gerundio, spinner de rueda y no admite clics; el ancho no cambia.
class FgButton extends StatefulWidget {
  const FgButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = FgButtonVariant.primary,
    this.size = FgButtonSize.md,
    this.icon,
    this.loading = false,
    this.loadingLabel,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final FgButtonVariant variant;
  final FgButtonSize size;
  final IconData? icon;
  final bool loading;

  /// Texto mientras carga, en gerundio ("Guardando…").
  final String? loadingLabel;

  /// Ancho completo (móvil: el primario `lg` ocupa el 100 %).
  final bool expand;

  @override
  State<FgButton> createState() => _FgButtonState();
}

class _FgButtonState extends State<FgButton> {
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// Respuesta al presionar: escala de 0.98 en 150 ms (§23), interrumpible y sin movimiento si se reduce.
  bool _presionado = false;

  double get _alto => switch (widget.size) {
        FgButtonSize.lg => FgSize.ctrlLg,
        FgButtonSize.md => FgSize.ctrlMd,
        FgButtonSize.sm => FgSize.ctrlSm,
      };

  double get _tamanoTexto => switch (widget.size) {
        FgButtonSize.lg => 20,
        FgButtonSize.md => 18,
        FgButtonSize.sm => 16,
      };

  double get _paddingX => switch (widget.size) {
        FgButtonSize.lg => FgSpace.sp6,
        FgButtonSize.md => FgSpace.sp5,
        FgButtonSize.sm => FgSpace.sp4,
      };

  Color _fondo(Set<WidgetState> estados) {
    final deshabilitado = estados.contains(WidgetState.disabled);
    final presionado = estados.contains(WidgetState.pressed);
    final encima = estados.contains(WidgetState.hovered);
    switch (widget.variant) {
      case FgButtonVariant.primary:
        if (deshabilitado) return FgColors.deshabilitadoBg;
        if (presionado) return FgColors.azul800;
        return encima ? FgColors.azul700 : FgColors.azul600;
      case FgButtonVariant.danger:
        if (deshabilitado) return FgColors.deshabilitadoBg;
        if (presionado) return FgColors.peligroPressed;
        return encima ? FgColors.peligroHover : FgColors.peligro;
      case FgButtonVariant.secondary:
        // Tonal (§23): fondo azul 100 sin borde. Se distingue del primario sin competir con él.
        if (deshabilitado) return FgColors.deshabilitadoBg;
        return presionado || encima ? FgColors.azul200 : FgColors.azul100;
      case FgButtonVariant.marca:
        // Con borde, el fondo es opaco: nada del fondo de la pantalla se ve a través del botón.
        if (deshabilitado) return FgColors.deshabilitadoBg;
        if (presionado) return FgColors.azul200;
        return encima ? FgColors.azul100 : FgColors.superficie;
      case FgButtonVariant.ghost:
        if (deshabilitado) return FgColors.deshabilitadoBg;
        if (presionado) return FgColors.azul200;
        return encima ? FgColors.azul100 : Colors.transparent;
    }
  }

  Color _texto(Set<WidgetState> estados) {
    if (estados.contains(WidgetState.disabled)) return FgColors.deshabilitadoFg;
    return switch (widget.variant) {
      FgButtonVariant.primary || FgButtonVariant.danger => FgColors.blanco,
      FgButtonVariant.secondary || FgButtonVariant.ghost => FgColors.azul800,
      FgButtonVariant.marca => FgColors.verde700,
    };
  }

  ButtonStyle _estilo() {
    final conBorde = widget.variant == FgButtonVariant.marca;
    const colorBorde = FgColors.verde700;
    return ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(widget.expand ? 0 : 120, _alto)),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: _paddingX)),
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(FgRadius.md))),
      side: WidgetStateProperty.resolveWith(
        (estados) => conBorde && !estados.contains(WidgetState.disabled)
            ? const BorderSide(color: colorBorde, width: FgBorder.control)
            : BorderSide.none,
      ),
      backgroundColor: WidgetStateProperty.resolveWith(_fondo),
      foregroundColor: WidgetStateProperty.resolveWith(_texto),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      textStyle: WidgetStatePropertyAll(FgText.boton(_tamanoTexto)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _texto(widget.onPressed == null && !widget.loading ? {WidgetState.disabled} : <WidgetState>{});
    final etiqueta = widget.loading ? (widget.loadingLabel ?? widget.label) : widget.label;
    final contenido = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading) ...[
          FgSpinner(color: color),
          const SizedBox(width: FgSpace.sp2),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: FgSize.iconoMd),
          const SizedBox(width: FgSpace.sp2),
        ],
        // En pantallas angostas la etiqueta pasa a dos líneas en vez de desbordar el botón.
        Flexible(child: Text(etiqueta, textAlign: TextAlign.center)),
      ],
    );
    // Cargando no se muestra como deshabilitado, pero tampoco admite clics.
    final VoidCallback? accion = widget.loading ? () {} : widget.onPressed;
    final Widget boton = switch (widget.variant) {
      FgButtonVariant.secondary || FgButtonVariant.marca =>
        OutlinedButton(onPressed: accion, focusNode: _focus, style: _estilo(), child: contenido),
      FgButtonVariant.ghost => TextButton(onPressed: accion, focusNode: _focus, style: _estilo(), child: contenido),
      _ => FilledButton(onPressed: accion, focusNode: _focus, style: _estilo(), child: contenido),
    };
    final activo = widget.onPressed != null && !widget.loading;
    final conPresion = Listener(
      onPointerDown: activo ? (_) => setState(() => _presionado = true) : null,
      onPointerUp: (_) => setState(() => _presionado = false),
      onPointerCancel: (_) => setState(() => _presionado = false),
      child: AnimatedScale(
        scale: _presionado && activo ? FgMotion.escalaPresion : 1,
        duration: FgMotion.reducir(context, FgMotion.micro),
        curve: FgMotion.ease,
        child: boton,
      ),
    );
    final conAnillo = FgFocusRing(focusNode: _focus, child: conPresion);
    return widget.expand ? SizedBox(width: double.infinity, child: conAnillo) : conAnillo;
  }
}

/// Botón de icono (§8.1): 48×48, `aria-label` obligatorio (aquí, [tooltip]).
class FgIconButton extends StatefulWidget {
  const FgIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  State<FgIconButton> createState() => _FgIconButtonState();
}

class _FgIconButtonState extends State<FgIconButton> {
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FgFocusRing(
        focusNode: _focus,
        child: IconButton(
          focusNode: _focus,
          tooltip: widget.tooltip,
          onPressed: widget.onPressed,
          icon: Icon(widget.icon, size: FgSize.iconoMd),
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size(FgSize.tapMin, FgSize.tapMin)),
            fixedSize: const WidgetStatePropertyAll(Size(FgSize.tapMin, FgSize.tapMin)),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(FgRadius.md))),
            foregroundColor: const WidgetStatePropertyAll(FgColors.ink),
            overlayColor: WidgetStateProperty.resolveWith(
              (estados) => estados.contains(WidgetState.pressed)
                  ? FgColors.azul200
                  : estados.contains(WidgetState.hovered)
                      ? FgColors.azul100
                      : Colors.transparent,
            ),
          ),
        ),
      );
}

/// Enlace de acción (§8.2): `--azul-800`, subrayado, objetivo táctil de 48 px.
class FgLinkButton extends StatelessWidget {
  const FgLinkButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: FgColors.azul800,
          minimumSize: const Size(FgSize.tapMin, FgSize.tapMin),
          padding: const EdgeInsets.symmetric(horizontal: FgSpace.sp2),
          textStyle: FgText.boton(18).copyWith(
            decoration: TextDecoration.underline,
            decorationThickness: 2,
          ),
        ),
        child: Text(label),
      );
}

/// Chip de filtro (§8.6): 48 móvil / 40 desktop. Seleccionado: borde azul y check, sin relleno.
class FgChip extends StatefulWidget {
  const FgChip({super.key, required this.label, required this.selected, required this.onPressed, this.compacto = false});

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  /// 40 px (desktop) en lugar de 48.
  final bool compacto;

  @override
  State<FgChip> createState() => _FgChipState();
}

class _FgChipState extends State<FgChip> {
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seleccionado = widget.selected;
    final forma = StadiumBorder(
      side: BorderSide(
        color: seleccionado ? FgColors.azul600 : FgColors.lineaControl,
        width: seleccionado ? FgBorder.controlActivo : FgBorder.control,
      ),
    );
    return Semantics(
      button: true,
      selected: seleccionado,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: FgFocusRing(
        focusNode: _focus,
        radius: FgRadius.pill,
        child: Material(
          color: FgColors.superficie,
          shape: forma,
          child: InkWell(
            focusNode: _focus,
            customBorder: forma,
            onTap: widget.onPressed,
            hoverColor: FgColors.fondo,
            highlightColor: FgColors.azul100,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: widget.compacto ? FgSize.ctrlSm : FgSize.ctrlMd),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: FgSpace.sp4, vertical: FgSpace.sp1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (seleccionado) ...[
                      const Icon(Icons.check, size: FgSize.iconoSm, color: FgColors.azul800),
                      const SizedBox(width: FgSpace.sp2),
                    ],
                    // En pantallas angostas o con texto grande la etiqueta baja de línea, no se corta.
                    Flexible(
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: FgText.caption.copyWith(
                          color: seleccionado ? FgColors.azul800 : FgColors.ink,
                          fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Spinner de rueda (§8.1): arco de 270°, trazo 3, gira en 800 ms. Con movimiento reducido no gira.
class FgSpinner extends StatefulWidget {
  const FgSpinner({super.key, this.size = FgSize.iconoSm, this.color = FgColors.azul600});

  final double size;
  final Color color;

  @override
  State<FgSpinner> createState() => _FgSpinnerState();
}

class _FgSpinnerState extends State<FgSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _giro = AnimationController(vsync: this, duration: FgMotion.giroSpinner);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _giro.stop();
    } else if (!_giro.isAnimating) {
      _giro.repeat();
    }
  }

  @override
  void dispose() {
    _giro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: RotationTransition(
          turns: _giro,
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _SpinnerPainter(widget.color),
          ),
        ),
      );
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const trazo = 3.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = trazo
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(trazo / 2, trazo / 2, size.width - trazo, size.height - trazo);
    canvas.drawArc(rect, 0, math.pi * 1.5, false, paint);
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) => oldDelegate.color != color;
}
