import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';

/// Representación tipográfica de la marca FarmaGo para encabezados de la app.
///
/// No es el logo: el logo (rueda, estelas y lema) no tiene versión válida por debajo de 160 px
/// (manual §2). Esta forma escribe el nombre con los colores del logo: "Farma" en azul de marca
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
