import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';
import 'buttons.dart';

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
  });

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
    final lista = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        margen,
        compacto ? FgSpace.sp4 : FgSpace.sp5,
        margen,
        (compacto ? FgSpace.sp6 : FgSpace.sp7) + (barraAccion == null ? 0 : FgSize.barraAccion),
      ),
      children: [
        if (!compacto) ...[
          Semantics(header: true, child: Text(titulo, style: FgText.h1(ancho))),
          const SizedBox(height: FgSpace.sp5),
        ],
        ...children,
      ],
    );
    final contenido = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: FgSize.contenido),
        child: compacto && onRefresh != null ? RefreshIndicator(onRefresh: onRefresh!, child: lista) : lista,
      ),
    );
    return Scaffold(
      backgroundColor: FgColors.fondo,
      body: Column(
        children: [
          _Encabezado(titulo: compacto ? titulo : null, onBack: onBack, acciones: acciones, compacto: compacto),
          Expanded(child: contenido),
          if (barraAccion != null) _BarraAccion(child: barraAccion!),
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
          border: Border(bottom: BorderSide(color: FgColors.linea, width: FgBorder.w1)),
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
class _BarraAccion extends StatelessWidget {
  const _BarraAccion({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(color: FgColors.superficie, boxShadow: FgShadow.eArriba),
        child: SafeArea(
          top: false,
          child: Padding(padding: const EdgeInsets.all(FgSpace.sp4), child: child),
        ),
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
