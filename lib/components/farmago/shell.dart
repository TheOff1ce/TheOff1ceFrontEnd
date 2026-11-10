import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';
import 'wordmark.dart';
import 'buttons.dart';
import 'focus_ring.dart';

/// Destino de navegación real de la aplicación (manual §8.12).
class FgDestino {
  const FgDestino({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
    this.seleccionado = false,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;
  final bool seleccionado;
}

/// Shell de la aplicación: separa la navegación del contenido.
///
/// - ≥ 1200 px: barra lateral de 264 px con todos los destinos, barra superior de 64 px y
///   contenido a la derecha.
/// - 768–1199 px: barra lateral colapsada de 72 px con iconos y etiqueta al pasar el puntero.
/// - < 768 px: contenido a todo el ancho y barra inferior con un máximo de cuatro destinos.
class FgAppShell extends StatelessWidget {
  const FgAppShell({
    super.key,
    required this.titulo,
    required this.destinos,
    required this.destinosMovil,
    required this.cuerpo,
    this.cuerpoMovil,
    this.accionesSuperiores = const [],
  }) : assert(destinosMovil.length <= 4, 'La barra inferior admite como máximo cuatro destinos');

  /// Nombre de la sección, en la barra superior de escritorio.
  final String titulo;

  /// Todos los destinos reales (barra lateral).
  final List<FgDestino> destinos;

  /// Destinos de la barra inferior en móvil (máximo cuatro).
  final List<FgDestino> destinosMovil;

  /// Contenido para escritorio y tablet.
  final Widget cuerpo;

  /// Contenido para móvil. Si no se pasa, se usa [cuerpo].
  final Widget? cuerpoMovil;

  /// Acciones de la barra superior de escritorio (notificaciones, cuenta).
  final List<Widget> accionesSuperiores;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    if (ancho >= FgBreakpoint.desktop) {
      return Scaffold(
        backgroundColor: FgColors.fondo,
        body: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _BarraLateral(destinos: destinos),
          Expanded(
            child: Column(children: [
              _BarraSuperior(titulo: titulo, acciones: accionesSuperiores),
              Expanded(child: cuerpo),
            ]),
          ),
        ]),
      );
    }
    if (!FgBreakpoint.esCompacto(ancho)) {
      return Scaffold(
        backgroundColor: FgColors.fondo,
        body: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _BarraLateral(destinos: destinos, colapsada: true),
          Expanded(
            child: Column(children: [
              _BarraSuperior(titulo: titulo, acciones: accionesSuperiores),
              Expanded(child: cuerpo),
            ]),
          ),
        ]),
      );
    }
    return Scaffold(
      backgroundColor: FgColors.fondo,
      body: SafeArea(bottom: false, child: cuerpoMovil ?? cuerpo),
      bottomNavigationBar: _BarraInferior(destinos: destinosMovil),
    );
  }
}

class _BarraLateral extends StatelessWidget {
  const _BarraLateral({required this.destinos, this.colapsada = false});

  final List<FgDestino> destinos;
  final bool colapsada;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: 'Navegación principal',
        child: Container(
          key: const ValueKey('navegacion-lateral'),
          width: colapsada ? FgSize.sidebarColapsado : FgSize.sidebar,
          decoration: const BoxDecoration(
            color: FgColors.superficie,
            border: Border(right: BorderSide(color: FgColors.linea, width: FgBorder.w1)),
          ),
          child: SafeArea(
            right: false,
            child: Padding(
              padding: EdgeInsets.all(colapsada ? FgSpace.sp2 : FgSpace.sp4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // Cabecera con el logo de marca (manual §2 y §21): 168 px, sobre superficie blanca.
                Padding(
                  padding: EdgeInsets.symmetric(vertical: FgSpace.sp5, horizontal: colapsada ? 0 : FgSpace.sp2),
                  child: colapsada
                      ? const Center(child: FgLogoSimbolo(lado: FgSize.ctrlSm))
                      : Image.asset(
                          'assets/images/logo_farmago.png',
                          width: FgSize.logoBarraLateral,
                          semanticLabel: 'FarmaGo',
                        ),
                ),
                for (final destino in destinos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: FgSpace.sp1),
                    child: _ItemLateral(destino: destino, colapsada: colapsada),
                  ),
              ]),
            ),
          ),
        ),
      );
}

class _ItemLateral extends StatefulWidget {
  const _ItemLateral({required this.destino, required this.colapsada});

  final FgDestino destino;
  final bool colapsada;

  @override
  State<_ItemLateral> createState() => _ItemLateralState();
}

class _ItemLateralState extends State<_ItemLateral> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.destino;
    final activo = d.seleccionado;
    final contenido = Container(
      constraints: const BoxConstraints(minHeight: FgSize.ctrlMd),
      padding: EdgeInsets.symmetric(horizontal: widget.colapsada ? 0 : FgSpace.sp4),
      alignment: widget.colapsada ? Alignment.center : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: activo ? FgColors.azul100 : Colors.transparent,
        borderRadius: BorderRadius.circular(FgRadius.md),
      ),
      child: Row(
        mainAxisSize: widget.colapsada ? MainAxisSize.min : MainAxisSize.max,
        children: [
          // Con texto visible no hay icono: solo la versión colapsada, sin etiqueta, lo necesita.
          if (widget.colapsada)
            ExcludeSemantics(
              child: Icon(d.icono, size: FgSize.iconoMd, color: activo ? FgColors.azul800 : FgColors.verde700),
            ),
          if (!widget.colapsada) ...[
            const SizedBox(width: FgSpace.sp3),
            Expanded(
              child: Text(
                d.etiqueta,

                style: FgText.label.copyWith(
                  color: activo ? FgColors.azul800 : FgColors.ink,
                  fontWeight: activo ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
    final item = _Presionable(child: Semantics(
      button: true,
      selected: activo,
      label: d.etiqueta,
      child: FgFocusRing(
        focusNode: _focus,
        radius: FgRadius.md,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(FgRadius.md),
          child: InkWell(
            focusNode: _focus,
            borderRadius: BorderRadius.circular(FgRadius.md),
            onTap: d.onTap,
            hoverColor: activo ? FgColors.azul200 : FgColors.fondo,
            child: contenido,
          ),
        ),
      ),
    ));
    if (!widget.colapsada) return item;
    return Tooltip(message: d.etiqueta, child: item);
  }
}

class _BarraSuperior extends StatelessWidget {
  const _BarraSuperior({required this.titulo, required this.acciones});

  final String titulo;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) => Container(
        height: FgSize.topbar,
        padding: const EdgeInsets.symmetric(horizontal: FgSpace.sp6),
        decoration: const BoxDecoration(
          color: FgColors.superficie,
          border: Border(bottom: BorderSide(color: FgColors.linea, width: FgBorder.w1)),
        ),
        child: Row(children: [
          Expanded(child: Text(titulo, style: FgText.h3, overflow: TextOverflow.ellipsis)),
          for (final accion in acciones) ...[
            const SizedBox(width: FgSpace.sp2),
            accion,
          ],
        ]),
      );
}

class _BarraInferior extends StatelessWidget {
  const _BarraInferior({required this.destinos});

  final List<FgDestino> destinos;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: FgColors.superficie,
          border: Border(top: BorderSide(color: FgColors.linea, width: FgBorder.w1)),
          boxShadow: FgShadow.eArriba,
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: FgSize.navMovil,
            child: Semantics(
              container: true,
              label: 'Navegación principal',
              child: Row(children: [
                for (final destino in destinos) Expanded(child: _ItemInferior(destino: destino)),
              ]),
            ),
          ),
        ),
      );
}

class _ItemInferior extends StatefulWidget {
  const _ItemInferior({required this.destino});

  final FgDestino destino;

  @override
  State<_ItemInferior> createState() => _ItemInferiorState();
}

class _ItemInferiorState extends State<_ItemInferior> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.destino;
    final activo = d.seleccionado;
    return _Presionable(child: Semantics(
      button: true,
      selected: activo,
      label: d.etiqueta,
      child: FgFocusRing(
        focusNode: _focus,
        radius: FgRadius.md,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            focusNode: _focus,
            onTap: d.onTap,
            child: Center(
              child: ExcludeSemantics(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Destino activo: línea de marca de 4 px sobre la etiqueta; sin icono.
                  Container(
                    width: FgSize.navIndicadorAncho,
                    height: FgBorder.w4,
                    decoration: BoxDecoration(
                      color: activo ? FgColors.azul600 : Colors.transparent,
                      borderRadius: BorderRadius.circular(FgRadius.pill),
                    ),
                  ),
                  const SizedBox(height: FgSpace.sp1),
                  Text(
                    d.etiqueta,
                    overflow: TextOverflow.ellipsis,
                    style: FgText.navMovil.copyWith(
                      color: activo ? FgColors.azul800 : FgColors.verde700,
                      fontWeight: activo ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

/// Botón de acción de la barra superior (notificaciones, cuenta). Usa el botón de icono del manual.
class FgAccionSuperior extends StatelessWidget {
  const FgAccionSuperior({super.key, required this.icono, required this.etiqueta, required this.onPressed});

  final IconData icono;
  final String etiqueta;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FgIconButton(icon: icono, tooltip: etiqueta, onPressed: onPressed);
}

/// Respuesta al presionar para destinos de navegación: escala 0.96, interrumpible y sin movimiento
/// si el sistema lo reduce (mismo criterio que `FgButton`, manual §8.1).
class _Presionable extends StatefulWidget {
  const _Presionable({required this.child});

  final Widget child;

  @override
  State<_Presionable> createState() => _PresionableState();
}

class _PresionableState extends State<_Presionable> {
  bool _presionado = false;

  void _marcar(bool valor) => setState(() => _presionado = valor);

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => _marcar(true),
        onPointerUp: (_) => _marcar(false),
        onPointerCancel: (_) => _marcar(false),
        child: AnimatedScale(
          scale: _presionado ? .96 : 1,
          duration: FgMotion.reducir(context, FgMotion.rapida),
          curve: FgMotion.ease,
          child: widget.child,
        ),
      );
}
