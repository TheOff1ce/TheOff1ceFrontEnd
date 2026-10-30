import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../app/theme/farmago_tokens.dart';
import '../components/landing/landing_sections.dart';

/// Landing pública de FarmaGo. Presenta el módulo de pendientes con el reloj de 48 h como gesto principal.
///
/// Las secciones se reparten en bandas de color alternadas (fondo, superficie, fondo hundido) en
/// lugar de tarjetas: el ritmo lo marca el cambio de superficie.
class LandingPage extends StatefulWidget {
  const LandingPage(
      {super.key, required this.onLogin, required this.onRegister});

  final VoidCallback onLogin, onRegister;

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // Flutter web no crea el árbol de accesibilidad hasta que alguien lo activa ("Enable accessibility").
  // Mientras la landing esté visible lo mantenemos activo, para que el texto llegue a los lectores de
  // pantalla y el teclado no tropiece con ese botón al inicio. Se libera al salir de la pantalla.
  SemanticsHandle? _semantica;

  @override
  void initState() {
    super.initState();
    _semantica = SemanticsBinding.instance.ensureSemantics();
  }

  @override
  void dispose() {
    _semantica?.dispose();
    super.dispose();
  }

  VoidCallback get onLogin => widget.onLogin;
  VoidCallback get onRegister => widget.onRegister;

  @override
  Widget build(BuildContext context) {
    final ancha = landingAncha(context);
    final margen = ancha ? FgSpace.sp6 : FgSpace.sp4;
    final aire = ancha ? FgSpace.sp9 : FgSpace.sp7;
    return Scaffold(
      backgroundColor: FgColors.fondo,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Franja decorativa de marca: 8 px, permitida en cabeceras (manual §3.4).
              const DecoratedBox(
                decoration: BoxDecoration(gradient: FgGradients.marca),
                child:
                    SizedBox(height: FgBorder.w4 * 2, width: double.infinity),
              ),
              _Banda(
                margen: margen,
                aire: aire,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Cabecera(),
                      SizedBox(height: ancha ? FgSpace.sp8 : FgSpace.sp6),
                      LandingHero(onLogin: onLogin, onRegister: onRegister),
                    ]),
              ),
              _Banda(
                margen: margen,
                aire: aire,
                color: FgColors.superficie,
                child: const LandingCaminos(),
              ),
              _Banda(
                  margen: margen, aire: aire, child: const LandingTrayecto()),
              _Banda(
                  margen: margen,
                  aire: aire,
                  color: FgColors.superficie,
                  child: const LandingRoles()),
              _Banda(
                  margen: margen,
                  aire: aire,
                  child: LandingCierre(onRegister: onRegister)),
              _Banda(
                  margen: margen,
                  aire: aire,
                  color: FgColors.fondoHundido,
                  child: const LandingNoHace()),
              _Banda(
                  margen: margen,
                  aire: FgSpace.sp7,
                  color: FgColors.superficie,
                  child: const _Pie()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banda de página: su color de fondo ocupa todo el ancho y el contenido se centra con el
/// ancho máximo del manual (1280 px).
class _Banda extends StatelessWidget {
  const _Banda(
      {required this.margen,
      required this.aire,
      required this.child,
      this.color = FgColors.fondo});

  final double margen, aire;
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: color,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: FgSize.contenido),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: margen, vertical: aire),
              child: child,
            ),
          ),
        ),
      );
}

/// Cabecera: solo la marca. El inicio de sesión ya tiene su acción principal en el hero; repetirlo
/// en la cabecera duplicaba la misma acción en tablet y escritorio.
class _Cabecera extends StatelessWidget {
  const _Cabecera();

  @override
  Widget build(BuildContext context) => const Row(children: [_Marca()]);
}

/// Marca tipográfica con el mismo símbolo de la app (manual §2): sin lema, sin recoloreo.
class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'FARMA GO',
        header: true,
        child: ExcludeSemantics(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: FgSize.tapMin,
              height: FgSize.tapMin,
              decoration: BoxDecoration(
                color: FgColors.azul600,
                borderRadius: BorderRadius.circular(FgRadius.sm),
              ),
              child: const Icon(Icons.local_pharmacy_rounded,
                  color: FgColors.blanco),
            ),
            const SizedBox(width: FgSpace.sp3),
            Flexible(
              child: Text(
                'FARMA GO',
                overflow: TextOverflow.ellipsis,
                style: FgText.label.copyWith(
                    color: FgColors.azul800, fontWeight: FontWeight.w800),
              ),
            ),
          ]),
        ),
      );
}

/// Pie de cierre centrado: una línea divisoria, el logo oficial (su lema va dentro del arte) y el
/// aviso de alcance debajo, en el mismo eje.
class _Pie extends StatelessWidget {
  const _Pie();

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(height: 1, color: FgColors.linea),
          SizedBox(height: FgSpace.sp6),
          Column(
            children: [
              // Centrado por el eje de la rueda, igual que en el hero.
              LogoOficial(ancho: 200),
              SizedBox(height: FgSpace.sp4),
              Text(
                'Esta información no reemplaza a tu médico ni a tu EPS.',
                style: FgText.body,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      );
}
