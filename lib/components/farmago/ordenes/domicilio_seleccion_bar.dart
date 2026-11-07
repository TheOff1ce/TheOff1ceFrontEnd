import 'package:flutter/material.dart';

import '../../../app/theme/farmago_tokens.dart';
import '../buttons.dart';
import 'ordenes_textos.dart';

/// Barra de pedido: aparece solo con una selección, pegada abajo (§3.1 del handoff).
///
/// Va dentro de la barra de acción fija de `FgScreen`, que ya trae la superficie, la sombra
/// `e-arriba` y la entrada desde abajo. Aquí solo está el contenido: contador (con anuncio para
/// lectores de pantalla), «Quitar selección» y el único botón primario de la pantalla.
class DomicilioSeleccionBar extends StatelessWidget {
  const DomicilioSeleccionBar({
    super.key,
    required this.cantidad,
    required this.nombres,
    required this.onQuitar,
    required this.onPedir,
    this.avisoUnaOrden = false,
  });

  final int cantidad;

  /// Nombres de los medicamentos elegidos: lo que el paciente reconoce (el id de la orden no le dice nada).
  final List<String> nombres;
  final VoidCallback onQuitar;
  final VoidCallback onPedir;

  /// La selección acaba de pasar a otra orden: la barra recuerda que un pedido es de una sola orden.
  final bool avisoUnaOrden;

  @override
  Widget build(BuildContext context) {
    final compacto = FgBreakpoint.esCompacto(MediaQuery.sizeOf(context).width);
    final detalle = avisoUnaOrden ? OrdenesTextos.avisoOtraOrden : nombres.join(', ');
    final texto = Semantics(
      liveRegion: true,
      container: true,
      label: '${OrdenesTextos.elegidos(cantidad)}. $detalle',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: FgMotion.reducir(context, FgMotion.media),
              switchInCurve: FgMotion.ease,
              transitionBuilder: (hijo, animacion) => FadeTransition(
                opacity: animacion,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, .3), end: Offset.zero).animate(animacion),
                  child: hijo,
                ),
              ),
              layoutBuilder: (actual, anteriores) => Stack(
                alignment: Alignment.centerLeft,
                children: [...anteriores, if (actual != null) actual],
              ),
              child: Text(
                OrdenesTextos.elegidos(cantidad),
                key: ValueKey(cantidad),
                style: FgText.num(FgText.label.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
            if (detalle.isNotEmpty)
              Text(detalle, style: FgText.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
    final quitar = FgLinkButton(label: OrdenesTextos.quitarSeleccion, onPressed: onQuitar);
    final pedir = FgButton(
      label: OrdenesTextos.pedirADomicilio,
      size: FgButtonSize.lg,
      icon: Icons.local_shipping_outlined,
      onPressed: onPedir,
      expand: compacto,
    );
    if (compacto) {
      // El texto ocupa todo el ancho y «Quitar selección» va a la izquierda, sobre el botón.
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          texto,
          Align(alignment: Alignment.centerLeft, child: Transform.translate(offset: const Offset(-FgSpace.sp2, 0), child: quitar)),
          pedir,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: texto),
        quitar,
        const SizedBox(width: FgSpace.sp4),
        pedir,
      ],
    );
  }
}
