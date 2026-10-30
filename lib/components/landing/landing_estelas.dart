import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';

/// Colores de las tres estelas del logo, de azul a verde (manual §2 y §3.1). La central es la de
/// mayor grosor: es la que pasa por las estaciones.
const _coloresEstela = [FgColors.azul600, FgColors.cian500, FgColors.verde400];

/// Cuánto se cierran las estelas al llegar al final del trayecto: al 15 % de su separación inicial.
/// Así el recorrido se lee como un flujo que converge en la fecha límite, no como líneas paralelas.
const _cierre = .85;

/// Trayecto horizontal de escritorio. Las tres estelas parten de la primera estación y convergen
/// en [xFin] (el borde izquierdo del reloj). La onda se anula en el centro de cada estación, así
/// el punto queda sobre la línea y no al lado.
class EstelasTrayecto extends StatelessWidget {
  const EstelasTrayecto(
      {super.key,
      required this.estaciones,
      required this.anchoCarril,
      required this.xFin});

  /// Número de estaciones; cada una cae en el centro de su columna dentro de [anchoCarril].
  final int estaciones;

  /// Ancho del carril de estaciones, sin el reloj ni el hueco que lo separa.
  final double anchoCarril;

  /// Coordenada x donde terminan las estelas: el punto más a la izquierda del reloj.
  final double xFin;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(
          painter: _TrayectoPainter(
              estaciones: estaciones, anchoCarril: anchoCarril, xFin: xFin),
        ),
      );
}

class _TrayectoPainter extends CustomPainter {
  _TrayectoPainter(
      {required this.estaciones,
      required this.anchoCarril,
      required this.xFin});

  final int estaciones;
  final double anchoCarril, xFin;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    const amplitud = FgSpace.sp2;
    const separacion = FgSpace.sp3;
    for (var k = 0; k < _coloresEstela.length; k++) {
      final trazo = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = k == 1 ? FgBorder.w4 : FgBorder.w2
        ..strokeCap = StrokeCap.round
        ..color = _coloresEstela[k].withValues(alpha: FgOpacity.estela);
      final ruta = Path();
      for (var x = 0.0; x <= xFin; x += 3) {
        final g = 1 - _cierre * (x / xFin).clamp(0.0, 1.0);
        // sin(2π·n·x/ancho) vale 0 en cada centro de estación: la onda pasa por el punto.
        final onda = math.sin(2 * math.pi * estaciones * x / anchoCarril);
        final y = cy + (k - 1) * separacion * g + amplitud * g * onda;
        if (x == 0) {
          ruta.moveTo(x, y);
        } else {
          ruta.lineTo(x, y);
        }
      }
      canvas.drawPath(ruta, trazo);
    }
  }

  @override
  bool shouldRepaint(_TrayectoPainter old) =>
      old.estaciones != estaciones ||
      old.anchoCarril != anchoCarril ||
      old.xFin != xFin;
}

/// Riel vertical de una estación (móvil y tablet). Cada tramo empieza y termina con la misma
/// separación que el tramo vecino, así que las estelas se unen sin saltos entre estaciones.
class RielVertical extends StatelessWidget {
  const RielVertical({
    super.key,
    required this.primera,
    required this.ultima,
    required this.centroY,
    required this.indice,
    required this.total,
  });

  /// La primera estación arranca en el punto y la última termina en él.
  final bool primera, ultima;

  /// Altura del punto dentro del riel (centro del primer renglón del título).
  final double centroY;

  /// Posición de la estación y total: determinan cuánto se cierran las estelas en ese tramo.
  final int indice, total;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(
          painter: _RielPainter(
            primera: primera,
            ultima: ultima,
            centroY: centroY,
            gArriba: 1 - _cierre * (indice / total),
            gAbajo: 1 - _cierre * ((indice + 1) / total),
          ),
          child: const SizedBox(
              width: FgSpace.sp6 + FgSpace.sp2, height: double.infinity),
        ),
      );
}

class _RielPainter extends CustomPainter {
  _RielPainter({
    required this.primera,
    required this.ultima,
    required this.centroY,
    required this.gArriba,
    required this.gAbajo,
  });

  final bool primera, ultima;
  final double centroY, gArriba, gAbajo;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final inicio = primera ? centroY : 0.0;
    final fin = ultima ? centroY : size.height;
    const separacion = FgSpace.sp3;
    for (var k = 0; k < _coloresEstela.length; k++) {
      final trazo = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = k == 1 ? FgBorder.w4 : FgBorder.w2
        ..strokeCap = StrokeCap.round
        ..color = _coloresEstela[k].withValues(alpha: FgOpacity.estela);
      // Desplazamiento de cada estela en los extremos del tramo, según el cierre del riel.
      final x0 = cx + (k - 1) * separacion * gArriba;
      final x1 = cx + (k - 1) * separacion * gAbajo;
      final ruta = Path()..moveTo(x0, inicio);
      // Una media onda por tramo (S), igual en las tres estelas: se leen como estela, no como tabla.
      final alto = fin - inicio;
      ruta.cubicTo(
        x0 + FgSpace.sp2,
        inicio + alto / 3,
        x1 - FgSpace.sp2,
        inicio + 2 * alto / 3,
        x1,
        fin,
      );
      canvas.drawPath(ruta, trazo);
    }
  }

  @override
  bool shouldRepaint(_RielPainter old) =>
      old.primera != primera ||
      old.ultima != ultima ||
      old.centroY != centroY ||
      old.gArriba != gArriba ||
      old.gAbajo != gAbajo;
}
