import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';
import 'buttons.dart';
import 'estampado.dart';
import 'shell.dart';

/// Marco de pantalla del manual (§5, §8.12): encabezado de 56 px en móvil (con el título como
/// `<h1>`) o de 64 px en tablet/desktop (con el `<h1>` en el contenido), contenido centrado de
/// hasta 1280 px con márgenes de 16/24/32 y barra de acción fija opcional (88 px).
class FgScreen extends StatelessWidget {
  const FgScreen({
    super.key,
    required this.titulo,
    required this.onBack,
    required this.children,
    this.acciones = const [],
    this.barraAccion,
    this.onRefresh,
    this.tituloEnContenido = true,
    this.anchoMaximo = FgSize.contenido,
    this.barraAccionConEntrada = false,
  });

  /// `false`: la pantalla pone su propio `<h1>` dentro del contenido (tablet y desktop).
  final bool tituloEnContenido;

  /// Ancho máximo del contenido (1280 por defecto; 960 en pantallas de lectura del paciente).
  final double anchoMaximo;

  /// La barra de acción sube desde abajo en 320 ms al aparecer (respuesta a una acción).
  final bool barraAccionConEntrada;

  final String titulo;
  final VoidCallback onBack;
  final List<Widget> children;

  /// Botones de icono a la derecha del encabezado (máximo 2).
  final List<Widget> acciones;

  /// Barra de acción fija inferior (flujos de una sola tarea en móvil).
  final Widget? barraAccion;

  /// Jalar para actualizar (solo móvil).
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final compacto = FgBreakpoint.esCompacto(ancho);
    final margen = FgBreakpoint.margenLateral(ancho);
    // Junto a la barra lateral fija (§23) el título va en la barra superior, como en el inicio, y
    // no se repite en el contenido.
    final tituloEnBarra = compacto || (tituloEnContenido && FgShellScope.of(context));
    final lista = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        margen,
        compacto ? FgSpace.sp4 : FgSpace.sp5,
        margen,
        (compacto ? FgSpace.sp6 : FgSpace.sp7) + (barraAccion == null ? 0 : FgSize.barraAccion),
      ),
      children: [
        if (!tituloEnBarra && tituloEnContenido) ...[
          Semantics(header: true, child: Text(titulo, style: FgText.h1(ancho))),
          const SizedBox(height: FgSpace.sp5),
        ],
        ...children,
      ],
    );
    final contenido = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: anchoMaximo),
        child: compacto && onRefresh != null ? RefreshIndicator(onRefresh: onRefresh!, child: lista) : lista,
      ),
    );
    return Scaffold(
      backgroundColor: FgColors.fondo,
      body: Column(
        children: [
          _Encabezado(titulo: tituloEnBarra ? titulo : null, onBack: onBack, acciones: acciones, compacto: compacto),
          Expanded(child: FgFondo(child: contenido)),
          if (barraAccion != null)
            barraAccionConEntrada
                ? _EntradaDesdeAbajo(child: _BarraAccion(anchoMaximo: anchoMaximo, child: barraAccion!))
                : _BarraAccion(anchoMaximo: anchoMaximo, child: barraAccion!),
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.titulo, required this.onBack, required this.acciones, required this.compacto});

  final String? titulo;
  final VoidCallback onBack;
  final List<Widget> acciones;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final alto = compacto ? FgSize.headerMovil : FgSize.topbar;
    return Material(
      color: FgColors.superficie,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: FgColors.lineaSuave, width: FgBorder.w1)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: alto,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compacto ? FgSpace.sp2 : FgSpace.sp4),
              child: Row(
                children: [
                  FgIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Volver', onPressed: onBack),
                  const SizedBox(width: FgSpace.sp2),
                  Expanded(
                    child: titulo == null
                        ? const SizedBox.shrink()
                        : Semantics(
                            header: true,
                            child: Text(
                              titulo!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: FgText.h3,
                            ),
                          ),
                  ),
                  ...acciones,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra de acción fija (§7.5): 88 px = 16 + botón 56 + 16, más el área segura inferior.
/// En pantallas anchas el botón se alinea con la columna de contenido (Gestalt continuidad).
class _BarraAccion extends StatelessWidget {
  const _BarraAccion({required this.child, required this.anchoMaximo});

  final Widget child;
  final double anchoMaximo;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(color: FgColors.superficie, boxShadow: FgShadow.eArriba),
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: anchoMaximo),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: FgBreakpoint.margenLateral(MediaQuery.sizeOf(context).width),
                  vertical: FgSpace.sp4,
                ),
                child: child,
              ),
            ),
          ),
        ),
      );
}

/// Entrada de la barra de acción: sube desde abajo en 320 ms (`--dur-lenta`, `--ease`).
/// Con movimiento reducido aparece directa.
class _EntradaDesdeAbajo extends StatelessWidget {
  const _EntradaDesdeAbajo({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: 0),
        duration: FgMotion.reducir(context, FgMotion.lenta),
        curve: FgMotion.ease,
        builder: (context, t, hijo) => FractionalTranslation(translation: Offset(0, t), child: hijo),
        child: child,
      );
}

/// Reconstruye cada minuto (el reloj de 48 h se actualiza por minuto, §8.13).
class MinuteTicker extends StatefulWidget {
  const MinuteTicker({super.key, required this.builder, this.onTick, this.periodo = const Duration(minutes: 1)});

  final WidgetBuilder builder;
  final VoidCallback? onTick;
  final Duration periodo;

  @override
  State<MinuteTicker> createState() => _MinuteTickerState();
}

class _MinuteTickerState extends State<MinuteTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.periodo, (_) {
      if (!mounted) return;
      widget.onTick?.call();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
