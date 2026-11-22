import 'package:flutter/material.dart';

import '../../app/apariencia.dart';
import '../../app/theme/farmago_tokens.dart';

/// Elige la apariencia de la app: automática (como el dispositivo), clara u oscura.
///
/// Tres opciones del mismo ancho sobre un riel hundido; la elegida se levanta como una tarjeta. El
/// cambio se ve al instante en toda la app, así que no hace falta un botón de guardar.
class FgSelectorApariencia extends StatelessWidget {
  const FgSelectorApariencia({super.key, this.controller});

  /// Inyectable en pruebas; por defecto, el de la app.
  final AparienciaController? controller;

  static const _iconos = {
    Apariencia.automatica: Icons.brightness_auto_outlined,
    Apariencia.clara: Icons.light_mode_outlined,
    Apariencia.oscura: Icons.dark_mode_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final c = controller ?? AparienciaController.instancia;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => Semantics(
        label: 'Apariencia',
        container: true,
        child: Container(
          padding: const EdgeInsets.all(FgSpace.sp1),
          decoration: BoxDecoration(
            color: FgColors.fondoHundido,
            borderRadius: BorderRadius.circular(FgRadius.md),
          ),
          child: Row(children: [
            for (final opcion in Apariencia.values)
              Expanded(
                child: _Opcion(
                  etiqueta: opcion.etiqueta,
                  icono: _iconos[opcion]!,
                  elegida: c.valor == opcion,
                  onTap: () => c.elegir(opcion),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({required this.etiqueta, required this.icono, required this.elegida, required this.onTap});

  final String etiqueta;
  final IconData icono;
  final bool elegida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = elegida ? FgColors.azulTexto : FgColors.inkSoft;
    final radio = BorderRadius.circular(FgRadius.md - FgSpace.sp1);
    return Semantics(
      button: true,
      selected: elegida,
      inMutuallyExclusiveGroup: true,
      label: etiqueta,
      onTap: onTap,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: FgMotion.reducir(context, FgMotion.rapida),
        curve: FgMotion.ease,
        decoration: BoxDecoration(
          color: elegida ? FgColors.superficie : FgColors.fondoHundido,
          borderRadius: radio,
          border: Border.all(color: elegida ? FgColors.lineaSuave : FgColors.fondoHundido, width: FgBorder.w1),
          boxShadow: elegida ? FgShadow.tarjeta : FgShadow.e0,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radio,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: FgSize.tapMin),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: FgSpace.sp2, horizontal: FgSpace.sp1),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icono, size: FgSize.iconoMd, color: color),
                  const SizedBox(height: FgSpace.sp1),
                  Text(
                    etiqueta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FgText.caption.copyWith(
                      color: color,
                      fontWeight: elegida ? FgWeight.bold : FgWeight.medio,
                      height: 1.2,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
