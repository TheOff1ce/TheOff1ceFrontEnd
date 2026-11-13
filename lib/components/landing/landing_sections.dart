import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';
import '../farmago/buttons.dart';

part 'landing_trayecto.dart';
part 'landing_caminos.dart';
part 'landing_roles.dart';

/// Ancho desde el que la landing usa dos columnas (manual §10).
bool landingAncha(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= FgBreakpoint.tablet;

/// Escritorio: el hero pone el logo al lado del texto y el recorrido va en fila.
bool landingEscritorio(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= FgBreakpoint.desktop;

/// Titular de sección: sin kicker ni numeración, el texto carga el peso.
class _Titular extends StatelessWidget {
  const _Titular(this.texto, {this.color = FgColors.ink});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(texto, style: FgText.h2.copyWith(color: color)),
      );
}

/// Logo oficial de FarmaGo (docs/logo/logo.png, con fondo transparente; copia de 640 px en assets).
/// Sin recortes ni recoloreo (manual §2).
class LogoOficial extends StatelessWidget {
  const LogoOficial({super.key, this.ancho = 200});

  final double ancho;

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: 'Logo de FarmaGo, de la farmacia a tu puerta',
        child: Image.asset(
          'assets/images/logo_farmago.png',
          width: ancho,
          fit: BoxFit.contain,
        ),
      );
}

/// Mide un bloque de texto a la medida de lectura del manual (720 px, manual §5.3).
class _Medida extends StatelessWidget {
  const _Medida({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: FgSize.lectura),
          child: child,
        ),
      );
}

/// Hero: el texto y, en escritorio, el logo oficial a la derecha (es el único logo de la página en
/// escritorio: no hay cabecera). En tablet y móvil solo el texto: la marca va en la cabecera.
class LandingHero extends StatelessWidget {
  const LandingHero(
      {super.key, required this.onLogin, required this.onRegister});

  final VoidCallback onLogin, onRegister;

  @override
  Widget build(BuildContext context) {
    final escritorio = landingEscritorio(context);
    final ancha = landingAncha(context);
    final texto =
        _HeroTexto(onLogin: onLogin, onRegister: onRegister, ancha: ancha);
    if (!escritorio) return _Medida(child: texto);
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: FgSize.lectura),
            child: texto,
          ),
        ),
      ),
      const SizedBox(width: FgSpace.sp8),
      const LogoOficial(ancho: 360),
    ]);
  }
}

class _HeroTexto extends StatelessWidget {
  const _HeroTexto(
      {required this.onLogin, required this.onRegister, required this.ancha});

  final VoidCallback onLogin, onRegister;
  final bool ancha;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final iniciar = FgButton(
        label: 'Iniciar sesión',
        size: FgButtonSize.lg,
        expand: !ancha,
        onPressed: onLogin);
    final crear = FgButton(
      label: 'Crear cuenta',
      variant: FgButtonVariant.secondary,
      size: FgButtonSize.lg,
      expand: !ancha,
      onPressed: onRegister,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Tu medicamento, de la farmacia a tu puerta.',
            style: (ancha ? FgText.display : FgText.h1(ancho))
                .copyWith(color: FgColors.azul800),
          ),
        ),
        const SizedBox(height: FgSpace.sp5),
        const Text(
          'FarmaGo conecta a tu EPS, tu farmacia y tu repartidor, y te muestra en qué va cada entrega, desde que sale de la farmacia hasta que la recibes.',
          style: FgText.bodyLg,
        ),
        const SizedBox(height: FgSpace.sp7),
        if (ancha)
          Wrap(
              spacing: FgSpace.sp4,
              runSpacing: FgSpace.sp4,
              children: [iniciar, crear])
        else
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            iniciar,
            const SizedBox(height: FgSpace.sp4),
            crear,
          ]),
      ],
    );
  }
}
