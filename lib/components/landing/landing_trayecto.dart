part of 'landing_sections.dart';

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
