import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../app/theme/farmago_tokens.dart';
import '../components/farmago/estampado.dart';
import '../components/farmago/wordmark.dart';
import '../components/landing/landing_sections.dart';

/// Landing pública de FarmaGo. Presenta el módulo de pendientes con el reloj de 48 h como gesto principal.
///
/// Las secciones se reparten en bandas: las transparentes dejan ver el fondo con el estampado de
/// marca (el mismo de todas las pantallas) y se alternan con bandas blancas y de color.
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
      body: FgFondo(child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Degradado de marca de la bienvenida: 8 px sobre la landing (manual §3.4 y §22).
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
                      // Un solo logo por pantalla: en escritorio va el logo grande del hero; en tablet y
                      // móvil, donde el hero es solo texto, la marca va en la cabecera.
                      if (!landingEscritorio(context)) ...[
                        const _Cabecera(),
                        SizedBox(height: ancha ? FgSpace.sp8 : FgSpace.sp7),
                      ],
                      LandingHero(onLogin: onLogin, onRegister: onRegister),
                    ]),
              ),
              _Banda(
                margen: margen,
                aire: aire,
                gradient: FgGradients.velo,
                child: const LandingCaminos(),
              ),
              _Banda(
                  margen: margen, aire: aire, child: const LandingTrayecto()),
              _Banda(
                  margen: margen,
                  aire: aire,
                  gradient: FgGradients.velo,
                  child: const LandingRoles()),
              // La banda oscura entra y sale con un degradado propio: el texto siempre queda sobre
              // el azul pleno y los bordes se funden con las bandas vecinas.
              const _Fundido(FgGradients.entradaProfundo),
              _Banda(
                  margen: margen,
                  aire: ancha ? FgSpace.sp7 : FgSpace.sp6,
                  gradient: FgGradients.profundo,
                  estampado: true,
                  child: const LandingCierre()),
              const _Fundido(FgGradients.salidaProfundo),
              _Banda(
                  margen: margen,
                  aire: aire,
                  child: const LandingNoHace()),
              _Banda(
                  margen: margen,
                  aire: FgSpace.sp7,
                  gradient: FgGradients.velo,
                  child: const _Pie()),
            ],
          ),
        ),
      )),
    );
  }
}

/// Banda de página: su fondo ocupa todo el ancho y el contenido se centra con el ancho máximo del
/// manual (1280 px). Sin color, deja ver el fondo con estampado de la pantalla. Con [gradient], el
/// degradado va encima; [estampado] repite las figuras de marca sobre él.
class _Banda extends StatelessWidget {
  const _Banda(
      {required this.margen,
      required this.aire,
      required this.child,
      this.gradient,
      this.estampado = false});

  final double margen, aire;
  final Widget child;
  final Gradient? gradient;
  final bool estampado;

  @override
  Widget build(BuildContext context) {
    final contenido = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: FgSize.contenido),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: margen, vertical: aire),
          child: child,
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: estampado
          ? FgEstampado(opacidad: FgOpacity.estampadoOscuro, child: contenido)
          : contenido,
    );
  }
}

/// Franja de transición entre dos bandas: corta (24 px), apenas suaviza el borde.
class _Fundido extends StatelessWidget {
  const _Fundido(this.gradient);

  final Gradient gradient;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(gradient: gradient),
        child: const SizedBox(height: FgSpace.sp5, width: double.infinity),
      );
}

/// Cabecera: solo la marca. El inicio de sesión ya tiene su acción principal en el hero; repetirlo
/// en la cabecera duplicaba la misma acción en tablet y escritorio.
class _Cabecera extends StatelessWidget {
  const _Cabecera();

  @override
  Widget build(BuildContext context) => const Row(children: [FgMarca()]);
}

/// Pie: una línea divisoria y el aviso de alcance. Sin logo: la marca ya está arriba.
class _Pie extends StatelessWidget {
  const _Pie();

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(height: 1, color: FgColors.linea),
          SizedBox(height: FgSpace.sp6),
          Text(
            'Esta información no reemplaza a tu médico ni a tu EPS.',
            style: FgText.body,
            textAlign: TextAlign.center,
          ),
        ],
      );
}
