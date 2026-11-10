import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';

/// Representación tipográfica de la marca FarmaGo para encabezados de la app.
///
/// Va sola o junto al símbolo de la app en [FgMarca]. Escribe el nombre con los colores del logo: "Farma" en azul de marca
/// (`azul600`, el tono más cercano al azul del logo) y "Go" en el verde oscuro del logo
/// (`verde700`). El verde más claro del degradado no alcanza el contraste para texto.
class FgWordmark extends StatelessWidget {
  const FgWordmark({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'FarmaGo',
        child: const ExcludeSemantics(
          child: Text.rich(
            TextSpan(
              style: FgText.h3,
              children: [
                TextSpan(text: 'Farma', style: TextStyle(color: FgColors.azul600)),
                TextSpan(text: 'Go', style: TextStyle(color: FgColors.verde700)),
              ],
            ),
          ),
        ),
      );
}

/// Símbolo de la app: la rueda con la F y las estelas del logo, sin el nombre ni el lema.
/// Es el mismo dibujo del ícono de la app; se usa en cabeceras, donde el logo completo no cabe.
class FgLogoSimbolo extends StatelessWidget {
  const FgLogoSimbolo({super.key, this.lado = FgSize.tapMin});

  final double lado;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Image.asset(
          'assets/images/logo_simbolo.png',
          width: lado,
          height: lado,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      );
}

/// Marca de cabecera: el símbolo de la app y el nombre con los colores del logo.
class FgMarca extends StatelessWidget {
  const FgMarca({super.key, this.compacta = false});

  /// Cabeceras móviles: símbolo de 40 px en lugar de 48.
  final bool compacta;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'FarmaGo',
        header: true,
        child: ExcludeSemantics(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            FgLogoSimbolo(lado: compacta ? FgSize.ctrlSm : FgSize.tapMin),
            const SizedBox(width: FgSpace.sp2),
            const Flexible(child: FgWordmark()),
          ]),
        ),
      );
}
