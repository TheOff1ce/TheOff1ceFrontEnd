import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';

/// Forma del anillo (manual §8.8): la forma ya dice el estado, además del símbolo y la palabra.
enum FormaAnillo {
  /// Anillo completo (Autorizado, No requiere).
  completo,

  /// Arco parcial sobre la pista (Vigente, Por autorizar).
  parcial,

  /// Anillo discontinuo (Vencida).
  discontinuo,

  /// Anillo punteado (Sin información).
  punteado,
}

/// Anillo con la forma de la rueda del logo para estados que no son el cumplimiento del plazo de
/// 48 h (D4). Hermano de `EstadoAnillo`: mismos trazos, pista `--track` y extremos redondos.
class AnilloMarca extends StatelessWidget {
  const AnilloMarca({
    super.key,
    required this.forma,
    required this.color,
    required this.diametro,
    required this.trazo,
    this.fraccion = .62,
    this.centro,
  });

  final FormaAnillo forma;
  final Color color;
  final double diametro;
  final double trazo;

  /// Parte del anillo que se dibuja (solo [FormaAnillo.parcial]).
  final double fraccion;
  final Widget? centro;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: diametro,
        height: diametro,
        child: CustomPaint(
          painter: _AnilloMarcaPainter(forma: forma, color: color, trazo: trazo, fraccion: fraccion),
          child: Center(child: centro),
        ),
      );
}

class _AnilloMarcaPainter extends CustomPainter {
  _AnilloMarcaPainter({required this.forma, required this.color, required this.trazo, required this.fraccion});

  final FormaAnillo forma;
  final Color color;
  final double trazo;
  final double fraccion;

  static const _trazosDiscontinuo = 8;
  static const _largoTrazo = 0.08;
  static const _puntos = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final radio = (size.shortestSide - trazo) / 2;
    final centro = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: centro, radius: radio);
    final pintura = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = trazo
      ..strokeCap = StrokeCap.round
      ..color = color;
    switch (forma) {
      case FormaAnillo.completo:
        canvas.drawCircle(centro, radio, pintura);
      case FormaAnillo.parcial:
        canvas.drawCircle(
          centro,
          radio,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = trazo
            ..color = FgColors.track,
        );
        // Un arco casi vacío sigue visible como un punto (extremos redondos).
        final barrido = 2 * math.pi * math.max(0.004, math.min(1.0, fraccion));
        if (fraccion > 0) canvas.drawArc(rect, -math.pi / 2, barrido, false, pintura);
      case FormaAnillo.discontinuo:
        _trazos(canvas, rect, radio, pintura, _trazosDiscontinuo, _largoTrazo);
      case FormaAnillo.punteado:
        _trazos(canvas, rect, radio, pintura, _puntos, .02);
    }
  }

  void _trazos(Canvas canvas, Rect rect, double radio, Paint pintura, int cantidad, double largo) {
    final recorte = trazo / radio;
    final barrido = math.max(2 * math.pi * largo - recorte, 0.02);
    final paso = 2 * math.pi / cantidad;
    for (var i = 0; i < cantidad; i++) {
      canvas.drawArc(rect, -math.pi / 2 + i * paso + recorte / 2, barrido, false, pintura);
    }
  }

  @override
  bool shouldRepaint(_AnilloMarcaPainter old) =>
      old.forma != forma || old.color != color || old.trazo != trazo || old.fraccion != fraccion;
}

/// Sello de estado genérico (§8.8): anillo de 24 con el símbolo dentro + palabra 16/700.
///
/// Es la variante de [StatusBadge] para los estados de órdenes (autorización y vigencia): forma,
/// símbolo y palabra, sin fondo ni borde. El símbolo es un `IconData` o un texto («!», «?»).
class SelloEstado extends StatelessWidget {
  const SelloEstado({
    super.key,
    required this.palabra,
    required this.forma,
    required this.solido,
    required this.texto,
    required this.simbolo,
    this.fraccion = .62,
  });

  final String palabra;
  final FormaAnillo forma;

  /// Color del anillo y del símbolo.
  final Color solido;

  /// Color de la palabra (par `*-fg`, AAA sobre blanco).
  final Color texto;
  final Object simbolo;
  final double fraccion;

  @override
  Widget build(BuildContext context) {
    final glifo = simbolo is IconData
        ? Icon(simbolo as IconData, size: FgSize.simboloMini, color: solido)
        : Text(
            simbolo as String,
            style: TextStyle(
              fontFamily: FgText.family,
              fontSize: FgSize.simboloMini,
              fontWeight: FontWeight.w700,
              height: 1,
              color: solido == FgColors.lineaControl ? FgColors.neutroFg : solido,
            ),
          );
    return Semantics(
      label: 'Estado: $palabra',
      excludeSemantics: true,
      child: SizedBox(
        height: FgSize.selloAlto,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnilloMarca(
              forma: forma,
              color: solido,
              diametro: FgSize.anilloSello,
              trazo: 3,
              fraccion: fraccion,
              centro: glifo,
            ),
            const SizedBox(width: FgSpace.sp2),
            Flexible(
              child: Text(palabra, style: FgText.caption.copyWith(color: texto, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
