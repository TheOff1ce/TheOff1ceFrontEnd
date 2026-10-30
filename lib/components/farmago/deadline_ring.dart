import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';
import '../../types/pendiente.dart';
import '../../utils/plazo_vista.dart';

/// Colores y símbolo de cada estado del plazo (manual §3.3). Siempre forma + símbolo + palabra.
extension EstadoPlazoEstilo on CumplimientoPlazo {
  Color get solido => switch (this) {
        CumplimientoPlazo.vigente => FgColors.vigenteSolid,
        CumplimientoPlazo.cumplido => FgColors.cumplidoSolid,
        CumplimientoPlazo.incumplido => FgColors.incumplidoSolid,
      };

  Color get texto => switch (this) {
        CumplimientoPlazo.vigente => FgColors.vigenteFg,
        CumplimientoPlazo.cumplido => FgColors.cumplidoFg,
        CumplimientoPlazo.incumplido => FgColors.incumplidoFg,
      };

  /// Reloj (vigente), check (cumplido) o "x" (incumplido).
  IconData get simbolo => switch (this) {
        CumplimientoPlazo.vigente => Icons.schedule_rounded,
        CumplimientoPlazo.cumplido => Icons.check_rounded,
        CumplimientoPlazo.incumplido => Icons.close_rounded,
      };
}

/// Anillo con la forma de la rueda del logo, sin animación ni texto (se reutiliza en el sello).
///
/// - Vigente: arco parcial que parte a las 12 y avanza en sentido horario sobre la pista.
/// - Incumplido: anillo discontinuo, sin progreso.
/// - Cumplido: anillo completo.
class EstadoAnillo extends StatelessWidget {
  const EstadoAnillo({
    super.key,
    required this.estado,
    required this.diametro,
    required this.trazo,
    required this.fraccion,
    this.tamanoSimbolo,
    this.centro,
  });

  final CumplimientoPlazo estado;
  final double diametro;
  final double trazo;

  /// Parte del anillo que queda (solo estado vigente).
  final double fraccion;

  /// Tamaño del símbolo central; `null` no lo dibuja (cuando hay [centro]).
  final double? tamanoSimbolo;
  final Widget? centro;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: diametro,
        height: diametro,
        child: CustomPaint(
          painter: _AnilloPainter(estado: estado, trazo: trazo, fraccion: fraccion),
          child: Center(
            child: centro ??
                (tamanoSimbolo == null ? null : Icon(estado.simbolo, size: tamanoSimbolo, color: estado.solido)),
          ),
        ),
      );
}

class _AnilloPainter extends CustomPainter {
  _AnilloPainter({required this.estado, required this.trazo, required this.fraccion});

  final CumplimientoPlazo estado;
  final double trazo;
  final double fraccion;

  /// Un anillo discontinuo: 8 trazos de ~8 % de la circunferencia con huecos de ~4,5 %.
  static const _trazosDiscontinuo = 8;
  static const _largoTrazo = 0.08;

  @override
  void paint(Canvas canvas, Size size) {
    final radio = (size.shortestSide - trazo) / 2;
    final centro = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: centro, radius: radio);
    final pintura = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = trazo
      ..strokeCap = StrokeCap.round
      ..color = estado.solido;

    switch (estado) {
      case CumplimientoPlazo.vigente:
        canvas.drawCircle(centro, radio, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = trazo
          ..color = FgColors.track);
        if (fraccion > 0) {
          canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * math.max(0.0, math.min(1.0, fraccion)), false, pintura);
        }
      case CumplimientoPlazo.cumplido:
        canvas.drawCircle(centro, radio, pintura);
      case CumplimientoPlazo.incumplido:
        // Los extremos redondos alargan cada trazo medio grosor por lado: se descuenta del arco.
        final recorteRad = trazo / radio;
        final barrido = math.max(2 * math.pi * _largoTrazo - recorteRad, 0.02);
        const paso = 2 * math.pi / _trazosDiscontinuo;
        for (var i = 0; i < _trazosDiscontinuo; i++) {
          final inicio = -math.pi / 2 + i * paso + recorteRad / 2;
          canvas.drawArc(rect, inicio, barrido, false, pintura);
        }
    }
  }

  @override
  bool shouldRepaint(_AnilloPainter oldDelegate) =>
      oldDelegate.estado != estado || oldDelegate.trazo != trazo || oldDelegate.fraccion != fraccion;
}

enum DeadlineRingSize {
  xs(40, 5),
  s(72, 8),
  m(120, 12),
  l(200, 18);

  const DeadlineRingSize(this.lado, this.trazo);

  final double lado;
  final double trazo;
}

/// Reloj de 48 h (§8.13): el anillo se vacía hasta la fecha límite.
///
/// El arco se dibuja en 600 ms al cargar (sin animación si se reduce el movimiento). La fecha límite
/// y el estado vienen del backend: este widget solo los presenta.
class DeadlineRing extends StatelessWidget {
  const DeadlineRing({super.key, required this.vista, required this.size, this.decorativo = false});

  final PlazoVista vista;
  final DeadlineRingSize size;

  /// Cuando un texto cercano ya dice lo mismo (tarjetas, hero), el anillo no se lee dos veces.
  final bool decorativo;

  Widget _centro() {
    final estado = vista.estado;
    final conTiempo = estado == CumplimientoPlazo.vigente && !vista.vencidoSinActualizar;
    switch (size) {
      case DeadlineRingSize.xs:
        return Icon(estado.simbolo, size: FgSize.simboloXs, color: estado.solido);
      case DeadlineRingSize.s:
        return Icon(estado.simbolo, size: FgSize.simboloS, color: estado.solido);
      case DeadlineRingSize.m:
        if (!conTiempo) return Icon(estado.simbolo, size: FgSize.simboloM, color: estado.solido);
        return _TextoCentro(principal: vista.centroPrincipal ?? '', estilo: FgText.cifra);
      case DeadlineRingSize.l:
        if (!conTiempo) return Icon(estado.simbolo, size: FgSize.simboloL, color: estado.solido);
        return _TextoCentro(
          principal: vista.centroPrincipal ?? '',
          secundario: vista.centroSecundario,
          estilo: FgText.display,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final anillo = TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: vista.fraccion),
      duration: FgMotion.reducir(context, FgMotion.reloj),
      curve: FgMotion.ease,
      builder: (context, valor, _) => EstadoAnillo(
        estado: vista.estado,
        diametro: size.lado,
        trazo: size.trazo,
        fraccion: valor,
        centro: _centro(),
      ),
    );
    if (decorativo) return ExcludeSemantics(child: anillo);
    return Semantics(image: true, label: vista.semantica, child: ExcludeSemantics(child: anillo));
  }
}

class _TextoCentro extends StatelessWidget {
  const _TextoCentro({required this.principal, this.secundario, required this.estilo});

  final String principal;
  final String? secundario;
  final TextStyle estilo;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(FgSpace.sp2),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(principal, style: FgText.num(estilo)),
              if (secundario != null)
                Text(secundario!, style: FgText.num(FgText.minutos)),
            ],
          ),
        ),
      );
}
