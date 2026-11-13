part of 'landing_sections.dart';

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
  _PasoEnvio(Icons.check_circle_outline, 'Entregado'),
];

const _pasosDomicilio = [
  _PasoEnvio(Icons.inbox_outlined, 'Recibido'),
  _PasoEnvio(Icons.assignment_ind_outlined, 'Asignado'),
  _PasoEnvio(Icons.local_shipping_outlined, 'En camino'),
  _PasoEnvio(Icons.check_circle_outline, 'Entregado'),
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
