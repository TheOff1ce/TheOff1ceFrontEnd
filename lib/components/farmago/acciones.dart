import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';
import 'focus_ring.dart';

/// Acción rápida (§23): toda la tarjeta es el botón. Icono, nombre de la acción, qué hace y chevron.
///
/// - Mismo tamaño para todas las acciones del grupo (Gestalt similitud; antes eran botones de
///   contorno de anchos distintos).
/// - Área de toque grande, de ancho completo en móvil (ley de Fitts).
/// - La descripción corta dice qué pasa al tocarla (reconocer antes que recordar).
class FgAccionTarjeta extends StatefulWidget {
  const FgAccionTarjeta({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback? onTap;

  @override
  State<FgAccionTarjeta> createState() => _FgAccionTarjetaState();
}

class _FgAccionTarjetaState extends State<FgAccionTarjeta> {
  final _focus = FocusNode();
  bool _encima = false;
  bool _presionado = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forma = FgDecor.formaTarjeta();
    final duracion = FgMotion.reducir(context, FgMotion.micro);
    return Semantics(
      button: true,
      label: '${widget.titulo}. ${widget.descripcion}',
      excludeSemantics: true,
      onTap: widget.onTap,
      child: FgFocusRing(
        focusNode: _focus,
        child: AnimatedScale(
          scale: _presionado ? FgMotion.escalaPresion : 1,
          duration: duracion,
          curve: FgMotion.ease,
          child: AnimatedContainer(
            duration: duracion,
            curve: FgMotion.ease,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FgRadius.md),
              boxShadow: _encima ? FgShadow.tarjetaHover : FgShadow.tarjeta,
            ),
            child: Material(
              color: FgColors.superficie,
              shape: forma,
              child: InkWell(
                focusNode: _focus,
                customBorder: forma,
                onTap: widget.onTap,
                onHover: (v) => setState(() => _encima = v),
                onHighlightChanged: (v) => setState(() => _presionado = v),
                hoverColor: FgColors.azul50,
                highlightColor: FgColors.azul50,
                splashColor: Colors.transparent,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: FgSize.tarjetaInteractivaMin),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: FgSpace.sp4h, vertical: FgSpace.sp4),
                    child: Row(children: [
                      Icon(widget.icono, size: FgSize.iconoLg, color: FgColors.azul600),
                      const SizedBox(width: FgSpace.sp4),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.titulo, style: FgText.label),
                            const SizedBox(height: FgSpace.sp1),
                            Text(widget.descripcion, style: FgText.caption),
                          ],
                        ),
                      ),
                      const SizedBox(width: FgSpace.sp2),
                      const Icon(Icons.chevron_right, size: FgSize.iconoMd, color: FgColors.inkSoft),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grupo de acciones rápidas: una columna en móvil y en columnas estrechas; dos columnas cuando
/// cada tarjeta tiene al menos 320 px. Todas del mismo ancho.
class FgAcciones extends StatelessWidget {
  const FgAcciones({super.key, required this.acciones, this.titulo});

  final List<FgAccionTarjeta> acciones;

  /// Título del grupo (opcional), como encabezado para lectores de pantalla.
  final String? titulo;

  static const _anchoMinimo = 320.0;

  @override
  Widget build(BuildContext context) {
    if (acciones.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (titulo != null) ...[
        Semantics(header: true, child: Text(titulo!, style: FgText.h3)),
        const SizedBox(height: FgSpace.sp3),
      ],
      LayoutBuilder(builder: (context, constraints) {
        const gap = FgSpace.sp4;
        final columnas = constraints.maxWidth >= _anchoMinimo * 2 + gap ? 2 : 1;
        final ancho = (constraints.maxWidth - gap * (columnas - 1)) / columnas;
        return Wrap(
          spacing: gap,
          runSpacing: FgSpace.sp3,
          children: [for (final accion in acciones) SizedBox(width: ancho, child: accion)],
        );
      }),
    ]);
  }
}
