import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';
import '../farmago/buttons.dart';

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

/// Recorrido de un pendiente: cuatro pasos en orden, numerados porque son una secuencia.
/// Escritorio: en fila, unidos por una línea. Tablet y móvil: en columna, con la línea vertical.
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
        const _Titular('Así avanza un pendiente'),
        const SizedBox(height: FgSpace.sp7),
        if (escritorio)
          IntrinsicHeight(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var i = 0; i < _estaciones.length; i++)
                Expanded(
                  child: _PasoFila(
                    numero: i + 1,
                    titulo: _estaciones[i].$1,
                    detalle: _estaciones[i].$2,
                    ultimo: i == _estaciones.length - 1,
                  ),
                ),
            ]),
          )
        else
          _Medida(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < _estaciones.length; i++)
                    _PasoColumna(
                      numero: i + 1,
                      titulo: _estaciones[i].$1,
                      detalle: _estaciones[i].$2,
                      ultimo: i == _estaciones.length - 1,
                    ),
                ]),
          ),
      ],
    );
  }
}

/// Número del paso: círculo azul de marca con la cifra en blanco.
class _NumeroPaso extends StatelessWidget {
  const _NumeroPaso(this.numero);

  final int numero;

  @override
  Widget build(BuildContext context) => Container(
        width: FgSize.ctrlSm,
        height: FgSize.ctrlSm,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
            color: FgColors.azul600, shape: BoxShape.circle),
        child: ExcludeSemantics(
          child: Text('$numero',
              style: FgText.num(FgText.label).copyWith(color: FgColors.blanco)),
        ),
      );
}

/// Texto de un paso: el número va en la semántica para que el lector lo diga antes del título.
class _TextoPaso extends StatelessWidget {
  const _TextoPaso(
      {required this.numero, required this.titulo, required this.detalle});

  final int numero;
  final String titulo, detalle;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(
            label: 'Paso $numero. $titulo',
            excludeSemantics: true,
            child: Text(titulo, style: FgText.label)),
        const SizedBox(height: FgSpace.sp2),
        Text(detalle, style: FgText.body),
      ]);
}

/// Paso en fila (escritorio): número y línea hacia el siguiente, texto debajo.
class _PasoFila extends StatelessWidget {
  const _PasoFila(
      {required this.numero,
      required this.titulo,
      required this.detalle,
      required this.ultimo});

  final int numero;
  final String titulo, detalle;
  final bool ultimo;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _NumeroPaso(numero),
          if (!ultimo) ...[
            const SizedBox(width: FgSpace.sp3),
            Expanded(child: Container(height: FgBorder.w2, color: FgColors.azul200)),
            const SizedBox(width: FgSpace.sp3),
          ],
        ]),
        const SizedBox(height: FgSpace.sp5),
        Padding(
          padding: const EdgeInsets.only(right: FgSpace.sp6),
          child: _TextoPaso(numero: numero, titulo: titulo, detalle: detalle),
        ),
      ]);
}

/// Paso en columna (tablet y móvil): número a la izquierda y línea vertical hacia el siguiente.
class _PasoColumna extends StatelessWidget {
  const _PasoColumna(
      {required this.numero,
      required this.titulo,
      required this.detalle,
      required this.ultimo});

  final int numero;
  final String titulo, detalle;
  final bool ultimo;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Column(children: [
            _NumeroPaso(numero),
            if (!ultimo)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: FgSpace.sp2),
                  child: Container(width: FgBorder.w2, color: FgColors.azul200),
                ),
              ),
          ]),
          const SizedBox(width: FgSpace.sp4),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  top: FgSpace.sp2, bottom: ultimo ? 0 : FgSpace.sp6),
              child: _TextoPaso(numero: numero, titulo: titulo, detalle: detalle),
            ),
          ),
        ]),
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

/// Dos caminos con un selector y un flujo de íconos con palabra, dentro de un solo panel. Al elegir
/// un camino, sus pasos se encienden en orden; sin movimiento, aparecen ya encendidos.
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
        const SizedBox(height: FgSpace.sp5),
        // Un solo panel para el camino elegido: el flujo y sus datos se leen juntos.
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(ancha ? FgSpace.sp7 : FgSpace.sp5),
          decoration: BoxDecoration(
            gradient: FgGradients.suave,
            borderRadius: BorderRadius.circular(FgRadius.lg),
            border: Border.all(color: FgColors.azul100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    _EstadoFila(paso: pasos[i], encendido: i < encendidos),
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
                child:
                    _EstadoColumna(paso: pasos[i], encendido: i < encendidos),
              ),
            ],
          ]);
        },
      ),
    );
  }
}

/// Estado en horizontal: círculo con ícono y palabra debajo.
class _EstadoColumna extends StatelessWidget {
  const _EstadoColumna({required this.paso, required this.encendido});

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

/// Estado en vertical (móvil): círculo a la izquierda, palabra a la derecha.
class _EstadoFila extends StatelessWidget {
  const _EstadoFila({required this.paso, required this.encendido});

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
        // En pantallas anchas cada dato es una columna: el camino ocupa el ancho del panel.
        final columnas = restricciones.maxWidth >= FgBreakpoint.tablet - FgSpace.sp9;
        final celdas = [for (final fila in filas) _Celda(fila: fila)];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: FgText.h3),
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
                style: fila.destacada
                    ? FgText.display.copyWith(color: FgColors.azul800)
                    : FgText.body),
          ],
        ),
      );
}

/// Línea entre dos estados: gris de fondo y azul de marca que se llena con [avance] (0 a 1).
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
/// Escritorio: cuatro columnas. Tablet: dos. Móvil: una.
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
    final ancho = MediaQuery.sizeOf(context).width;
    final columnas = ancho >= FgBreakpoint.desktop
        ? 4
        : ancho >= FgBreakpoint.tablet
            ? 2
            : 1;
    final roles = [
      for (final (icono, titulo, detalle) in _roles)
        _Rol(icono: icono, titulo: titulo, detalle: detalle),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Titular('Quién participa'),
        const SizedBox(height: FgSpace.sp7),
        for (var fila = 0; fila < roles.length; fila += columnas) ...[
          if (fila > 0) const SizedBox(height: FgSpace.sp6),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = fila; i < fila + columnas; i++) ...[
              if (i > fila) const SizedBox(width: FgSpace.sp6),
              Expanded(
                  child: i < roles.length ? roles[i] : const SizedBox.shrink()),
            ],
          ]),
        ],
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
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ExcludeSemantics(
          child: Container(
            width: FgSize.tapMin,
            height: FgSize.tapMin,
            decoration: BoxDecoration(
              color: FgColors.azul100,
              borderRadius: BorderRadius.circular(FgRadius.md),
            ),
            child: Icon(icono, size: FgSize.iconoMd, color: FgColors.azul700),
          ),
        ),
        const SizedBox(height: FgSpace.sp4),
        Text(titulo, style: FgText.label),
        const SizedBox(height: FgSpace.sp2),
        Text(detalle, style: FgText.body),
      ]);
}

/// Lo que FarmaGo no decide: la frontera de alcance, dicha sin rodeos (manual §1).
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

/// Cierre: invita a crear la cuenta. La acción ya está en el hero, así que aquí solo va el mensaje,
/// sobre el degradado profundo de marca.
class LandingCierre extends StatelessWidget {
  const LandingCierre({super.key});

  @override
  Widget build(BuildContext context) => _Medida(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Titular('¿Tu medicamento quedó pendiente?',
                color: FgColors.blanco),
            const SizedBox(height: FgSpace.sp3),
            Text(
              'Si eres paciente, crea tu cuenta para ver el estado de tus medicamentos. Las cuentas de las EPS las asigna un administrador.',
              style: FgText.bodyLg.copyWith(color: FgColors.azul100),
            ),
          ],
        ),
      );
}
