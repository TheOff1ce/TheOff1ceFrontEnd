import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';

/// Entrada escalonada al llegar una respuesta de la EPS (D11, manual §13.3 ampliado).
///
/// Opacidad 0→1 y desplazamiento de 16 px hacia arriba en 320 ms con `FgMotion.ease`, tras un
/// [retraso]. Se reproduce al construirse: la pantalla cambia la `Key` del hijo cuando llega una
/// respuesta o cambia el filtro, nunca al marcar, abrir un diálogo o recibir un 409. Con
/// movimiento reducido devuelve el hijo sin animar.
class FgEntrada extends StatefulWidget {
  const FgEntrada({super.key, this.retraso = Duration.zero, required this.child});

  final Duration retraso;
  final Widget child;

  /// Retraso de la pieza [indice] (en pantalla) con un tope, p. ej. tarjetas: 180 ms + k × 60 ms.
  static Duration escalonada(int indice, {Duration base = Duration.zero, int tope = 6}) =>
      base + FgMotion.escalon * (indice < tope ? indice : tope);

  @override
  State<FgEntrada> createState() => _FgEntradaState();
}

class _FgEntradaState extends State<FgEntrada> with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(vsync: this, duration: FgMotion.lenta);
  Timer? _espera;
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controlador.value = 1;
    } else if (widget.retraso == Duration.zero) {
      _controlador.forward();
    } else {
      _espera = Timer(widget.retraso, () {
        if (mounted) _controlador.forward();
      });
    }
  }

  @override
  void dispose() {
    _espera?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    final curva = CurvedAnimation(parent: _controlador, curve: FgMotion.ease);
    return AnimatedBuilder(
      animation: curva,
      builder: (context, hijo) => Opacity(
        opacity: curva.value,
        child: Transform.translate(offset: Offset(0, FgSpace.sp4 * (1 - curva.value)), child: hijo),
      ),
      child: widget.child,
    );
  }
}

/// Cifra que cuenta de 0 al valor en 600 ms (la duración del arco), con un [retraso] opcional.
///
/// Los lectores de pantalla leen solo el valor final con [semantica]; con movimiento reducido el
/// valor aparece directo.
class FgConteo extends StatefulWidget {
  const FgConteo({super.key, required this.valor, required this.style, required this.semantica, this.retraso = Duration.zero});

  final int valor;
  final TextStyle style;
  final String semantica;
  final Duration retraso;

  @override
  State<FgConteo> createState() => _FgConteoState();
}

class _FgConteoState extends State<FgConteo> {
  bool _listo = false;
  Timer? _espera;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_listo || _espera != null) return;
    if (widget.retraso == Duration.zero || MediaQuery.disableAnimationsOf(context)) {
      _listo = true;
    } else {
      _espera = Timer(widget.retraso, () {
        if (mounted) setState(() => _listo = true);
      });
    }
  }

  @override
  void dispose() {
    _espera?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estilo = FgText.num(widget.style);
    final duracion = FgMotion.reducir(context, FgMotion.reloj);
    return Semantics(
      label: widget.semantica,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: _listo ? widget.valor.toDouble() : 0),
        duration: duracion,
        curve: FgMotion.ease,
        builder: (context, v, _) => Text('${v.round()}', style: estilo),
      ),
    );
  }
}

/// Punto «en vivo» de 10 px con un halo que late cada 2 s. El punto no cambia: solo el halo.
/// Con movimiento reducido queda fijo.
class FgPuntoEnVivo extends StatefulWidget {
  const FgPuntoEnVivo({super.key});

  @override
  State<FgPuntoEnVivo> createState() => _FgPuntoEnVivoState();
}

class _FgPuntoEnVivoState extends State<FgPuntoEnVivo> with SingleTickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(vsync: this, duration: FgMotion.pulso);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulso.stop();
    } else if (!_pulso.isAnimating) {
      _pulso.repeat();
    }
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const lado = FgSize.puntoEnVivo;
    return ExcludeSemantics(
      child: SizedBox(
        width: lado,
        height: lado,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulso,
              builder: (context, _) {
                final t = FgMotion.ease.transform(_pulso.value);
                return Opacity(
                  opacity: MediaQuery.disableAnimationsOf(context) ? 0 : .55 * (1 - t),
                  child: Transform.scale(
                    scale: 1 + 1.8 * t,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(color: FgColors.cumplidoSolid, shape: BoxShape.circle),
                      child: SizedBox(width: lado, height: lado),
                    ),
                  ),
                );
              },
            ),
            const DecoratedBox(
              decoration: BoxDecoration(color: FgColors.cumplidoSolid, shape: BoxShape.circle),
              child: SizedBox(width: lado, height: lado),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filete de 4 px con el degradado de marca (D3). Mientras [cargando], el degradado se desplaza en
/// bucle cada 1400 ms; con movimiento reducido queda quieto. Nunca lleva texto encima.
class FgFileteMarca extends StatefulWidget {
  const FgFileteMarca({super.key, this.cargando = false});

  final bool cargando;

  @override
  State<FgFileteMarca> createState() => _FgFileteMarcaState();
}

class _FgFileteMarcaState extends State<FgFileteMarca> with SingleTickerProviderStateMixin {
  late final AnimationController _desplazamiento =
      AnimationController(vsync: this, duration: FgMotion.brilloSkeleton);

  void _sincronizar() {
    if (widget.cargando && !MediaQuery.disableAnimationsOf(context)) {
      if (!_desplazamiento.isAnimating) _desplazamiento.repeat();
    } else {
      _desplazamiento.stop();
      _desplazamiento.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sincronizar();
  }

  @override
  void didUpdateWidget(FgFileteMarca oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sincronizar();
  }

  @override
  void dispose() {
    _desplazamiento.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          height: FgBorder.w4,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _desplazamiento,
            builder: (context, _) => DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: FgGradients.marca.begin,
                  end: FgGradients.marca.end,
                  colors: FgGradients.marca.colors,
                  stops: FgGradients.marca.stops,
                  tileMode: TileMode.mirror,
                  transform: _Desplazar(_desplazamiento.value),
                ),
              ),
            ),
          ),
        ),
      );
}

class _Desplazar extends GradientTransform {
  const _Desplazar(this.t);

  final double t;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * 2 * t, 0, 0);
}
