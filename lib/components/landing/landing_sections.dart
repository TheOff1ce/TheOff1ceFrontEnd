import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';
import '../../types/pendiente.dart';
import '../../utils/plazo_vista.dart';
import '../farmago/buttons.dart';
import '../farmago/deadline_ring.dart';
import '../farmago/status_badge.dart';
import 'landing_estelas.dart';

/// Ancho desde el que la landing usa dos columnas (manual §10).
bool landingAncha(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= FgBreakpoint.tablet;

/// Escritorio: el reloj de 48 h se integra al final del trayecto, en una sola banda horizontal.
bool landingEscritorio(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= FgBreakpoint.desktop;

/// Titular de sección: sin kicker ni numeración, el texto carga el peso.
class _Titular extends StatelessWidget {
  const _Titular(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(texto, style: FgText.h2),
      );
}

/// Logo oficial de FarmaGo (docs/logo/logo.png, con fondo transparente; copia de 640 px en assets).
/// Sin recortes ni recoloreo (manual §2).
/// Ancho de presentación del logo en escritorio. Ni el manual ni los tokens fijan este valor
/// (§2 solo fija mínimos): queda registrado como pendiente de diseño.
const double _anchoLogo = 360;

class LogoOficial extends StatelessWidget {
  const LogoOficial(
      {super.key, this.ancho = _anchoLogo, this.alineadoAlMargen = false});

  /// Ancho de presentación. El pie lo usa más pequeño que el hero.
  final double ancho;

  /// Compensa el margen transparente del PNG para que el arte quede sobre el margen de la página.
  final bool alineadoAlMargen;

  /// Margen transparente a la izquierda del PNG, como fracción del ancho (64 de 1192 px).
  static const _margenPng = 0.054;

  @override
  Widget build(BuildContext context) {
    final imagen = Image.asset(
      'assets/images/logo_farmago.png',
      width: ancho,
      fit: BoxFit.contain,
    );
    return Semantics(
      image: true,
      label: 'Logo de FarmaGo, de la farmacia a tu puerta',
      // PNG con fondo transparente: se usa directamente sobre el fondo, sin panel blanco alrededor.
      child: alineadoAlMargen
          ? Transform.translate(
              offset: Offset(-ancho * _margenPng, 0), child: imagen)
          : imagen,
    );
  }
}

/// Mide un bloque de texto a la medida de lectura del manual (720 px, manual §5.3): en escritorio
/// evita líneas de más de 80 caracteres. Align da al hijo restricciones sueltas, así que el tope
/// sí se aplica aunque el contenedor pase un ancho exacto.
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

/// Hero. En escritorio el texto va solo: el reloj vive al final del trayecto. En tablet y móvil
/// el reloj acompaña al texto, porque el trayecto ya va en una columna.
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
    if (escritorio) {
      // El logo oficial ocupa el lado derecho: antes era un hueco sin función en 1440 px.
      return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
          flex: 7,
          // Align: el hijo recibe restricciones sueltas, así el tope de lectura sí se aplica.
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: FgSize.lectura + FgSpace.sp9),
              child: texto,
            ),
          ),
        ),
        const SizedBox(width: FgSpace.sp7),
        const Expanded(
            flex: 5,
            child:
                Align(alignment: Alignment.centerRight, child: LogoOficial())),
      ]);
    }
    // Tablet y móvil: solo el texto. El reloj de ejemplo va al final del recorrido, después de
    // "Dos caminos", igual que en escritorio.
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: FgSize.lectura + FgSpace.sp9),
        child: texto,
      ),
    );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Tu medicamento, de la farmacia a tu puerta.',
            style: ancha ? FgText.display : FgText.h1(ancho),
          ),
        ),
        const SizedBox(height: FgSpace.sp5),
        const Text(
          'FarmaGo conecta a tu EPS, tu farmacia y tu repartidor, y te muestra en qué va cada entrega, desde que sale de la farmacia hasta que la recibes.',
          style: FgText.bodyLg,
        ),
        const SizedBox(height: FgSpace.sp6),
        if (ancha)
          Wrap(spacing: FgSpace.sp4, runSpacing: FgSpace.sp4, children: [
            FgButton(
                label: 'Iniciar sesión',
                size: FgButtonSize.lg,
                onPressed: onLogin),
            FgButton(
              label: 'Crear cuenta',
              variant: FgButtonVariant.secondary,
              size: FgButtonSize.lg,
              onPressed: onRegister,
            ),
          ])
        else
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            FgButton(
                label: 'Iniciar sesión',
                size: FgButtonSize.lg,
                expand: true,
                onPressed: onLogin),
            const SizedBox(height: FgSpace.sp4),
            FgButton(
              label: 'Crear cuenta',
              variant: FgButtonVariant.secondary,
              size: FgButtonSize.lg,
              expand: true,
              onPressed: onRegister,
            ),
          ]),
      ],
    );
  }
}

/// Datos del reloj de ejemplo. Son ilustrativos: no provienen de ningún pendiente real.
const _vistaEjemplo = PlazoVista(
  estado: CumplimientoPlazo.vigente,
  titular: '31 h 20 min',
  palabraEstado: 'Vigente',
  fecha: 'Vence 1 nov 2026, 3:30 p. m.',
  fraccion: .65,
  centroPrincipal: '31 h',
  centroSecundario: '20 min',
  semantica: '',
);

/// Reloj de ejemplo en tablet y móvil, junto al texto del hero.
class _MuestraPendiente extends StatelessWidget {
  const _MuestraPendiente();

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: DeadlineRing(
                vista: _vistaEjemplo,
                size: DeadlineRingSize.l,
                decorativo: true),
          ),
          SizedBox(height: FgSpace.sp4),
          _LeyendaReloj(),
        ],
      );
}

/// Leyenda del reloj: dos líneas fijas, identificador y plazo, y la marca de ejemplo.
class _LeyendaReloj extends StatelessWidget {
  const _LeyendaReloj();

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          StatusBadge(estado: CumplimientoPlazo.vigente, fraccion: .65),
          SizedBox(height: FgSpace.sp3),
          Text('Pendiente OM-1042',
              style: FgText.label, textAlign: TextAlign.center),
          SizedBox(height: FgSpace.sp1),
          // Espacios duros en "p. m.": la hora no se parte entre líneas.
          Text('Vence 1 nov 2026, 3:30 p. m.',
              style: FgText.caption, textAlign: TextAlign.center),
          SizedBox(height: FgSpace.sp2),
          Text('Ejemplo ilustrativo. No es un pendiente real.',
              style: FgText.caption, textAlign: TextAlign.center),
        ],
      );
}

/// Recorrido de un pendiente: las estelas del logo son la línea de tiempo (manual §9 y §13.2).
/// Escritorio: estaciones en una banda horizontal que termina en el reloj de 48 h.
/// Tablet y móvil: riel vertical.
class LandingTrayecto extends StatelessWidget {
  const LandingTrayecto({super.key});

  static const _estaciones = [
    (
      'Se registra la entrega incompleta',
      'La farmacia notifica la orden que no pudo entregar. El plazo de 48 horas empieza en ese momento.',
    ),
    (
      'La EPS indica el punto alterno',
      'La EPS o el gestor indica otro punto donde sí hay medicamento. FarmaGo no consulta inventarios.',
    ),
    (
      'Un repartidor lo lleva',
      'El repartidor recibe la orden asignada y registra la entrega.',
    ),
    (
      'Todos ven el estado',
      'Pacientes, EPS y gestor siguen el plazo hasta cerrarlo. El estado puede ser vigente, cumplido o incumplido.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final escritorio = landingEscritorio(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Espacio duro entre las dos últimas palabras: evita un título con una sola palabra en la última línea.
        const _Titular('Así avanza un pendiente'),
        const SizedBox(height: FgSpace.sp6),
        if (escritorio)
          const _Horizontal(estaciones: _estaciones)
        else
          // En tablet el riel se limita a una medida de lectura: sin tope, las líneas pasan de 100 caracteres.
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: FgSize.lectura),
                child: const _Vertical(estaciones: _estaciones),
              ),
            ),
            const SizedBox(height: FgSpace.sp7),
            const Center(child: _MuestraPendiente()),
          ]),
      ],
    );
  }
}

/// Ancho del hueco entre el último carril y el reloj.
const double _huecoReloj = FgSpace.sp7;

class _Horizontal extends StatelessWidget {
  const _Horizontal({required this.estaciones});

  final List<(String, String)> estaciones;

  @override
  Widget build(BuildContext context) {
    const lado = DeadlineRingSize.l;
    return LayoutBuilder(builder: (context, restricciones) {
      final ancho = restricciones.maxWidth;
      final anchoCarril = ancho - _huecoReloj - lado.lado;
      final anchoEstacion = anchoCarril / estaciones.length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: lado.lado,
            child: Stack(children: [
              // Las estelas van por detrás de los puntos y terminan en el borde izquierdo del reloj.
              Positioned.fill(
                child: EstelasTrayecto(
                  estaciones: estaciones.length,
                  anchoCarril: anchoCarril,
                  xFin: ancho - lado.lado,
                ),
              ),
              Row(children: [
                SizedBox(
                  width: anchoCarril,
                  child: Row(children: [
                    for (var i = 0; i < estaciones.length; i++)
                      const Expanded(child: Center(child: _Punto())),
                  ]),
                ),
                const SizedBox(width: _huecoReloj),
                const ExcludeSemantics(
                  child: DeadlineRing(
                      vista: _vistaEjemplo, size: lado, decorativo: true),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: FgSpace.sp5),
          IntrinsicHeight(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(
                width: anchoCarril,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (titulo, detalle) in estaciones)
                        SizedBox(
                          width: anchoEstacion,
                          child: Padding(
                            padding: const EdgeInsets.only(right: FgSpace.sp5),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(titulo, style: FgText.label),
                                  const SizedBox(height: FgSpace.sp2),
                                  Text(detalle, style: FgText.body),
                                ]),
                          ),
                        ),
                    ]),
              ),
              const SizedBox(width: _huecoReloj),
              SizedBox(
                width: lado.lado,
                child: const _LeyendaReloj(),
              ),
            ]),
          ),
        ],
      );
    });
  }
}

class _Vertical extends StatelessWidget {
  const _Vertical({required this.estaciones});

  final List<(String, String)> estaciones;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < estaciones.length; i++)
              IntrinsicHeight(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: FgSpace.sp6 + FgSpace.sp2,
                        child: Stack(children: [
                          Positioned.fill(
                            child: RielVertical(
                              primera: i == 0,
                              ultima: i == estaciones.length - 1,
                              centroY: FgSpace.sp3,
                              indice: i,
                              total: estaciones.length,
                            ),
                          ),
                          const Positioned(
                              left: FgSpace.sp3,
                              top: FgSpace.sp1,
                              child: _Punto()),
                        ]),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: FgSpace.sp6),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(estaciones[i].$1, style: FgText.label),
                                const SizedBox(height: FgSpace.sp2),
                                Text(estaciones[i].$2, style: FgText.body),
                              ]),
                        ),
                      ),
                    ]),
              ),
          ],
        ),
      );
}

/// Punto de estación: azul de marca con aro del color de la banda, para separarlo de la estela.
class _Punto extends StatelessWidget {
  const _Punto();

  @override
  Widget build(BuildContext context) => Container(
        width: FgSpace.sp4,
        height: FgSpace.sp4,
        decoration: const BoxDecoration(
          color: FgColors.azul600,
          shape: BoxShape.circle,
          border: Border.fromBorderSide(
              BorderSide(color: FgColors.superficie, width: FgBorder.w4)),
        ),
      );
}

/// Duración de cada paso del flujo al encenderse. En reposo, o con movimiento reducido, no hay animación.
const _duracionPaso = FgMotion.media;

/// Un paso del recorrido: ícono y palabra. Nunca un ícono solo (manual §13.1).
class _PasoEnvio {
  const _PasoEnvio(this.icono, this.texto);

  final IconData icono;
  final String texto;
}

/// Estados de seguimiento documentados (PRODUCT §7, módulo B). El pendiente añade su paso de origen.
const _pasosPendiente = [
  _PasoEnvio(Icons.assignment_late_outlined, 'Pendiente registrado'),
  _PasoEnvio(Icons.inbox_outlined, 'Recibido'),
  _PasoEnvio(Icons.assignment_ind_outlined, 'Asignado'),
  _PasoEnvio(Icons.local_shipping_outlined, 'En camino'),
  _PasoEnvio(Icons.check_circle_outline_rounded, 'Entregado'),
];

const _pasosDomicilio = [
  _PasoEnvio(Icons.inbox_outlined, 'Recibido'),
  _PasoEnvio(Icons.assignment_ind_outlined, 'Asignado'),
  _PasoEnvio(Icons.local_shipping_outlined, 'En camino'),
  _PasoEnvio(Icons.check_circle_outline_rounded, 'Entregado'),
];

const _caminoPendiente = _Camino(
  titulo: 'Gestión de pendientes',
  filas: [
    _Fila('Cuándo',
        'La farmacia no tenía existencias para entregarlo completo en el punto original.'),
    _Fila('Plazo máximo', '48 horas', destacada: true),
    _Fila('Quién paga el envío', 'La EPS o el gestor. Tú no pagas el envío.'),
  ],
);

const _caminoDomicilio = _Camino(
  titulo: 'Domicilio voluntario',
  filas: [
    _Fila('Cuándo',
        'Tu EPS ya autorizó el medicamento y tú prefieres recibirlo en casa.'),
    _Fila('Plazo', 'La fecha que tú elijas al agendar.'),
    _Fila('Quién paga el envío', 'Tú, con una tarifa de conveniencia.'),
  ],
);

/// Dos caminos con un selector y un flujo de íconos con palabra. Al elegir un camino, sus pasos se
/// encienden en orden; sin movimiento, aparecen ya encendidos.
class LandingCaminos extends StatefulWidget {
  const LandingCaminos({super.key});

  @override
  State<LandingCaminos> createState() => _LandingCaminosState();
}

class _LandingCaminosState extends State<LandingCaminos>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flujo = AnimationController(vsync: this);
  bool _pendiente = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reproducir();
    });
  }

  @override
  void dispose() {
    _flujo.dispose();
    super.dispose();
  }

  void _elegir(bool pendiente) {
    if (_pendiente == pendiente) return;
    setState(() => _pendiente = pendiente);
    _reproducir();
  }

  void _reproducir() {
    final reducido = MediaQuery.disableAnimationsOf(context);
    final pasos = _pendiente ? _pasosPendiente.length : _pasosDomicilio.length;
    if (reducido) {
      _flujo.value = 1;
      return;
    }
    _flujo.duration = _duracionPaso * pasos;
    _flujo.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final ancha = landingAncha(context);
    final pasos = _pendiente ? _pasosPendiente : _pasosDomicilio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Titular('Dos caminos, una misma red'),
        const SizedBox(height: FgSpace.sp5),
        Wrap(spacing: FgSpace.sp3, runSpacing: FgSpace.sp3, children: [
          FgChip(
              label: 'Pendiente',
              selected: _pendiente,
              onPressed: () => _elegir(true)),
          FgChip(
              label: 'Domicilio voluntario',
              selected: !_pendiente,
              onPressed: () => _elegir(false)),
        ]),
        const SizedBox(height: FgSpace.sp6),
        _FlujoEnvio(pasos: pasos, progreso: _flujo, ancho: ancha),
        const SizedBox(height: FgSpace.sp7),
        AnimatedSwitcher(
          duration: FgMotion.reducir(context, FgMotion.media),
          child: KeyedSubtree(
            key: ValueKey(_pendiente),
            child: _pendiente ? _caminoPendiente : _caminoDomicilio,
          ),
        ),
      ],
    );
  }
}

/// Flujo de la entrega: un círculo por estado con su ícono y su palabra, unidos por una línea que
/// se llena al encenderse cada paso. La lectura no depende de la animación.
class _FlujoEnvio extends StatelessWidget {
  const _FlujoEnvio(
      {required this.pasos, required this.progreso, required this.ancho});

  final List<_PasoEnvio> pasos;
  final Animation<double> progreso;
  final bool ancho;

  @override
  Widget build(BuildContext context) {
    final resumen =
        'Recorrido de la entrega: ${pasos.map((p) => p.texto).join(', ')}.';
    return Semantics(
      label: resumen,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: progreso,
        builder: (context, _) {
          final encendidos = (progreso.value * pasos.length).floor();
          if (!ancho) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < pasos.length; i++) ...[
                    if (i > 0) const SizedBox(height: FgSpace.sp3),
                    _PasoFila(paso: pasos[i], encendido: i < encendidos),
                  ],
                ]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < pasos.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: SizedBox(
                    height: FgSize.ctrlLg,
                    // La línea se llena cuando el paso anterior ya está encendido.
                    child: Center(
                      child: _Linea(
                        avance: (progreso.value * pasos.length - (i - 1))
                            .clamp(0.0, 1.0),
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: 112,
                child: _PasoColumna(paso: pasos[i], encendido: i < encendidos),
              ),
            ],
          ]);
        },
      ),
    );
  }
}

/// Paso en horizontal: círculo con ícono y palabra debajo.
class _PasoColumna extends StatelessWidget {
  const _PasoColumna({required this.paso, required this.encendido});

  final _PasoEnvio paso;
  final bool encendido;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _Circulo(icono: paso.icono, encendido: encendido),
          const SizedBox(height: FgSpace.sp2),
          Text(
            paso.texto,
            style: encendido ? FgText.label : FgText.caption,
            textAlign: TextAlign.center,
          ),
        ],
      );
}

/// Paso en vertical (móvil): círculo a la izquierda, palabra a la derecha.
class _PasoFila extends StatelessWidget {
  const _PasoFila({required this.paso, required this.encendido});

  final _PasoEnvio paso;
  final bool encendido;

  @override
  Widget build(BuildContext context) => Row(children: [
        _Circulo(icono: paso.icono, encendido: encendido),
        const SizedBox(width: FgSpace.sp4),
        Expanded(
            child: Text(paso.texto,
                style: encendido ? FgText.label : FgText.caption)),
      ]);
}

/// Círculo de estado: relleno azul de marca cuando está encendido. El color no es el único aviso:
/// el ícono y la palabra también cambian.
class _Circulo extends StatelessWidget {
  const _Circulo({required this.icono, required this.encendido});

  final IconData icono;
  final bool encendido;

  @override
  Widget build(BuildContext context) => Container(
        width: FgSize.ctrlLg,
        height: FgSize.ctrlLg,
        decoration: BoxDecoration(
          color: encendido ? FgColors.azul600 : FgColors.superficie,
          shape: BoxShape.circle,
          border: Border.all(
            color: encendido ? FgColors.azul600 : FgColors.lineaControl,
            width: FgBorder.w2,
          ),
        ),
        child: Icon(icono,
            size: FgSize.iconoMd,
            color: encendido ? FgColors.blanco : FgColors.inkSoft),
      );
}

/// Una fila de un camino: etiqueta pequeña y valor. La destacada usa la cifra de display.
class _Fila {
  const _Fila(this.etiqueta, this.valor, {this.destacada = false});

  final String etiqueta, valor;
  final bool destacada;
}

/// Un camino: sin tarjeta ni líneas de tabla. La jerarquía la marca la tipografía.
class _Camino extends StatelessWidget {
  const _Camino({required this.titulo, required this.filas});

  final String titulo;
  final List<_Fila> filas;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, restricciones) {
        // En pantallas anchas cada dato es una columna: el camino ocupa el ancho de la sección.
        final columnas = restricciones.maxWidth >= FgBreakpoint.tablet;
        final celdas = [for (final fila in filas) _Celda(fila: fila)];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: FgText.h2),
            const SizedBox(height: FgSpace.sp5),
            if (columnas)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (var i = 0; i < celdas.length; i++) ...[
                  if (i > 0) const SizedBox(width: FgSpace.sp6),
                  Expanded(child: celdas[i]),
                ],
              ])
            else
              for (var i = 0; i < celdas.length; i++) ...[
                if (i > 0) const SizedBox(height: FgSpace.sp5),
                celdas[i],
              ],
          ],
        );
      });
}

/// Un dato del camino: línea superior fina, etiqueta y valor. La cifra destacada usa display.
class _Celda extends StatelessWidget {
  const _Celda({required this.fila});

  final _Fila fila;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: FgSpace.sp4),
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: FgColors.linea))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fila.etiqueta, style: FgText.caption),
            const SizedBox(height: FgSpace.sp1),
            Text(fila.valor,
                style: fila.destacada ? FgText.display : FgText.body),
          ],
        ),
      );
}

/// Línea entre dos pasos: gris de fondo y azul de marca que se llena con [avance] (0 a 1).
class _Linea extends StatelessWidget {
  const _Linea({required this.avance});

  final double avance;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(height: FgBorder.w2, color: FgColors.linea),
          FractionallySizedBox(
            widthFactor: avance,
            child: Container(height: FgBorder.w2, color: FgColors.azul600),
          ),
        ],
      );
}

/// Quién participa y qué hace cada uno (PRODUCT §3).
class LandingRoles extends StatelessWidget {
  const LandingRoles({super.key});

  static const _roles = [
    (
      Icons.person_outline_rounded,
      'Pacientes',
      'Ven qué les falta, cuándo vence el plazo y en qué estado va su medicamento.'
    ),
    (
      Icons.account_balance_outlined,
      'EPS y gestores',
      'Siguen el cumplimiento y asignan el punto alterno de cada pendiente.'
    ),
    (
      Icons.local_pharmacy_outlined,
      'Farmacias',
      'Notifican la entrega incompleta desde su propio sistema y alistan el medicamento reasignado.'
    ),
    (
      Icons.local_shipping_outlined,
      'Repartidores',
      'Reciben sus entregas y registran cada entrega en ruta.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ancha = landingAncha(context);
    final filas = [
      for (final (icono, titulo, detalle) in _roles)
        _Rol(icono: icono, titulo: titulo, detalle: detalle),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Titular('Quién participa'),
        const SizedBox(height: FgSpace.sp5),
        if (ancha)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(children: [filas[0], filas[1]])),
            const SizedBox(width: FgSpace.sp6),
            Expanded(child: Column(children: [filas[2], filas[3]])),
          ])
        else
          Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: filas),
      ],
    );
  }
}

class _Rol extends StatelessWidget {
  const _Rol(
      {required this.icono, required this.titulo, required this.detalle});

  final IconData icono;
  final String titulo, detalle;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: FgSpace.sp4),
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: FgColors.linea))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ExcludeSemantics(
              child:
                  Icon(icono, size: FgSize.iconoMd, color: FgColors.azul600)),
          const SizedBox(width: FgSpace.sp4),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: FgText.label),
              const SizedBox(height: FgSpace.sp1),
              Text(detalle, style: FgText.body),
            ]),
          ),
        ]),
      );
}

/// Lo que FarmaGo no decide: la frontera de alcance, dicha sin rodeos (manual §1).
/// Va en una banda de color propia, sin tarjeta.
class LandingNoHace extends StatelessWidget {
  const LandingNoHace({super.key});

  static const _limites = [
    'Decisiones clínicas.',
    'Cobertura o autorización de medicamentos, que corresponde a la EPS, al gestor o a la junta médica.',
    'Consulta de inventarios de farmacias.',
  ];

  @override
  Widget build(BuildContext context) => _Medida(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Titular('Lo que FarmaGo no decide'),
            const SizedBox(height: FgSpace.sp3),
            const Text(
              'FarmaGo organiza la logística y el seguimiento de cada entrega. No participa en estas decisiones:',
              style: FgText.bodyLg,
            ),
            const SizedBox(height: FgSpace.sp5),
            for (final limite in _limites)
              Padding(
                padding: const EdgeInsets.only(bottom: FgSpace.sp3),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Guion centrado en la primera línea de texto: la altura de línea sale del propio estilo.
                      SizedBox(
                        height: FgText.body.fontSize! * FgText.body.height!,
                        child: const ExcludeSemantics(
                          child: Center(
                            child: SizedBox(
                              width: FgSpace.sp3,
                              height: FgBorder.w2,
                              child: ColoredBox(color: FgColors.azul800),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: FgSpace.sp3),
                      Expanded(child: Text(limite, style: FgText.body)),
                    ]),
              ),
          ],
        ),
      );
}

/// Cierre con una sola acción: crear cuenta (el primario ya está en el hero).
class LandingCierre extends StatelessWidget {
  const LandingCierre({super.key, required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final ancha = landingAncha(context);
    const texto = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Titular('¿Tu medicamento quedó pendiente?'),
        SizedBox(height: FgSpace.sp3),
        Text(
          'Si eres paciente, crea tu cuenta para ver el estado de tus medicamentos. Las cuentas de las EPS las asigna un administrador.',
          style: FgText.bodyLg,
        ),
      ],
    );
    final boton = FgButton(
      label: 'Crear cuenta',
      variant: FgButtonVariant.secondary,
      size: FgButtonSize.lg,
      expand: !ancha,
      onPressed: onRegister,
    );
    if (!ancha) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        texto,
        const SizedBox(height: FgSpace.sp5),
        boton,
      ]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const Expanded(child: _Medida(child: texto)),
      const SizedBox(width: FgSpace.sp6),
      boton,
    ]);
  }
}
