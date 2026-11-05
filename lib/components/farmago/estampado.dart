import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';

/// Estampado de figuras de marca sobre un fondo (manual §22, categoría decorativa de identidad).
///
/// Ocho figuras simples (cruz, cápsula, gota, trayecto, pin, reloj, rueda y paquete) colocadas a lo
/// largo de ondas. Cada onda tiene su amplitud, longitud y fase; las figuras se separan de forma
/// irregular y cada una tiene un desplazamiento, un giro y una escala propios. La variación es
/// determinista: el mismo tamaño siempre produce el mismo dibujo. Va detrás del contenido, recortado
/// a su zona, sin semántica ni movimiento y con una opacidad que lo deja apenas visible.
class FgEstampado extends StatelessWidget {
  const FgEstampado({super.key, required this.child, this.opacidad});

  final Widget child;

  /// Opacidad del estampado; si es null, usa `FgOpacity.estampado`.
  final double? opacidad;

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: ClipRect(child: CustomPaint(painter: _EstampadoPainter(opacidad ?? FgOpacity.estampado))),
            ),
          ),
        ),
        child,
      ]);
}

/// Valor pseudoaleatorio determinista en [0, 1).
double _ruido(double semilla) {
  final v = math.sin(semilla * 12.9898) * 43758.5453;
  return v - v.floorToDouble();
}

class _EstampadoPainter extends CustomPainter {
  _EstampadoPainter(this.opacidad);

  final double opacidad;

  static const _separacionOndas = 64.0; // distancia base entre ondas
  static const _paso = 42.0; // distancia base entre figuras a lo largo de una onda
  static const _amplitud = 16.0; // altura base de la onda
  static const _longitudOnda = 230.0; // ancho base de una ola completa
  static const _figura = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final trazo = Paint()
      ..color = FgColors.azul200.withValues(alpha: opacidad)
      ..style = PaintingStyle.stroke
      ..strokeWidth = FgBorder.w1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final ondas = (size.height / _separacionOndas).ceil() + 2;

    for (var onda = -1; onda < ondas; onda++) {
      // Cada onda es distinta: amplitud, longitud, fase y altura propias.
      final r1 = _ruido(onda * 1.7 + .3);
      final r2 = _ruido(onda * 3.1 + 1.1);
      final amplitud = _amplitud * (.5 + r1 * 1.3);
      final frecuencia = 2 * math.pi / (_longitudOnda * (.65 + r2 * .7));
      final fase = onda * .9 + r1 * 4;
      final base = onda * _separacionOndas + (r2 - .5) * 28;

      var x = -_paso + (onda.isOdd ? _paso / 2 : 0);
      var i = 0;
      while (x < size.width + _paso) {
        // Separación y giro irregulares dentro de la misma onda.
        final r3 = _ruido(onda * 7.3 + i * 1.9);
        // Algunas figuras se omiten: así se forman grupos y huecos en vez de una hilera continua.
        if (_ruido(onda * 11.3 + i * .7) < .12) {
          x += _paso * (.6 + r3 * .9);
          i++;
          continue;
        }
        final angulo = x * frecuencia + fase;
        final y = base + amplitud * math.sin(angulo) + (r3 - .5) * 10;
        final pendiente = amplitud * frecuencia * math.cos(angulo);
        final giro = math.atan2(pendiente, 1) * .8 + (r3 - .5) * 1.1;

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(giro);
        canvas.scale(.8 + r3 * .4);
        switch ((onda * 5 + i * 3 + (r3 * 8).floor()).abs() % 8) {
          case 0:
            _cruz(canvas, trazo);
          case 1:
            _capsula(canvas, trazo);
          case 2:
            _gota(canvas, trazo);
          case 3:
            _trayecto(canvas, trazo);
          case 4:
            _pin(canvas, trazo);
          case 5:
            _reloj(canvas, trazo);
          case 6:
            _rueda(canvas, trazo);
          default:
            _paquete(canvas, trazo);
        }
        canvas.restore();

        x += _paso * (.6 + r3 * .9);
        i++;
      }
    }
  }

  // Todas las figuras se dibujan centradas en el origen; la posición y el giro los pone el llamador.

  void _cruz(Canvas canvas, Paint p) {
    const m = _figura / 2;
    const b = _figura / 6;
    final camino = Path()
      ..moveTo(-b, -m)
      ..lineTo(b, -m)
      ..lineTo(b, -b)
      ..lineTo(m, -b)
      ..lineTo(m, b)
      ..lineTo(b, b)
      ..lineTo(b, m)
      ..lineTo(-b, m)
      ..lineTo(-b, b)
      ..lineTo(-m, b)
      ..lineTo(-m, -b)
      ..lineTo(-b, -b)
      ..close();
    canvas.drawPath(camino, p);
  }

  void _capsula(Canvas canvas, Paint p) {
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-_figura * .7, -_figura * .28, _figura * 1.4, _figura * .56),
      const Radius.circular(_figura * .28),
    );
    canvas.drawRRect(rect, p);
  }

  void _gota(Canvas canvas, Paint p) {
    const m = _figura / 2;
    final camino = Path()
      ..moveTo(0, m)
      ..cubicTo(-m, m * .2, -m * .7, -m * .6, 0, -m)
      ..cubicTo(m * .7, -m * .6, m, m * .2, 0, m)
      ..close();
    canvas.drawPath(camino, p);
  }

  void _trayecto(Canvas canvas, Paint p) {
    const m = _figura / 2;
    const inicio = Offset(-m, m * .6);
    const fin = Offset(m, -m * .6);
    final camino = Path()
      ..moveTo(inicio.dx, inicio.dy)
      ..cubicTo(-m * .2, m * .6, -m * .2, -m * .6, fin.dx, fin.dy);
    canvas.drawPath(camino, p);
    canvas.drawCircle(inicio, FgBorder.w2, p);
    canvas.drawCircle(fin, FgBorder.w2, p);
  }

  /// Pin de ubicación: cabeza circular y punta hacia abajo.
  void _pin(Canvas canvas, Paint p) {
    const m = _figura / 2;
    const cabeza = Offset(0, -m * .2);
    const radio = m * .6;
    canvas.drawCircle(cabeza, radio, p);
    canvas.drawLine(const Offset(-radio * .9, -m * .2 + radio * .4), const Offset(0, m), p);
    canvas.drawLine(const Offset(radio * .9, -m * .2 + radio * .4), const Offset(0, m), p);
  }

  /// Reloj: esfera con dos manecillas (el plazo).
  void _reloj(Canvas canvas, Paint p) {
    const m = _figura / 2;
    canvas.drawCircle(Offset.zero, m * .85, p);
    canvas.drawLine(Offset.zero, const Offset(0, -m * .5), p);
    canvas.drawLine(Offset.zero, const Offset(m * .35, 0), p);
  }

  /// Rueda: el logo en forma simple, con cubo y radios.
  void _rueda(Canvas canvas, Paint p) {
    const m = _figura / 2;
    canvas.drawCircle(Offset.zero, m * .85, p);
    canvas.drawCircle(Offset.zero, m * .2, p);
    for (var r = 0; r < 6; r++) {
      final a = r * math.pi / 3;
      canvas.drawLine(
        Offset(math.cos(a) * m * .2, math.sin(a) * m * .2),
        Offset(math.cos(a) * m * .85, math.sin(a) * m * .85),
        p,
      );
    }
  }

  /// Paquete: caja con cinta, para entregas.
  void _paquete(Canvas canvas, Paint p) {
    const m = _figura / 2;
    canvas.drawRect(const Rect.fromLTWH(-m * .8, -m * .5, m * 1.6, m * 1.3), p);
    canvas.drawLine(const Offset(-m * .8, -m * .1), const Offset(m * .8, -m * .1), p);
    canvas.drawLine(const Offset(0, -m * .5), const Offset(0, m * .8), p);
  }

  @override
  bool shouldRepaint(covariant _EstampadoPainter oldDelegate) => oldDelegate.opacidad != opacidad;
}
