import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';
import 'wordmark.dart';
import 'buttons.dart';
import 'focus_ring.dart';
import 'selector_apariencia.dart';

/// Destino de navegación real de la aplicación (manual §8.12).
class FgDestino {
  const FgDestino({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
    this.seleccionado = false,
    this.ruta,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;
  final bool seleccionado;

  /// Ruta de la app a la que lleva (la ponen los destinos de `AppNavigation`).
  final String? ruta;
}

/// Pie de la barra lateral: «Cerrar sesión», siempre a la vista abajo y lejos de la navegación para
/// no tocarlo por error. Quién tiene la sesión abierta se muestra arriba ([FgCuentaChip]).
class FgPieLateral {
  const FgPieLateral({required this.onCerrarSesion});

  final Future<void> Function() onCerrarSesion;
}

/// Marca el subárbol que ya tiene la barra lateral fija de la app ([FgNavLateral]). Así
/// [FgAppShell] y [FgScreen] no dibujan una segunda barra y adaptan su encabezado.
class FgShellScope extends InheritedWidget {
  const FgShellScope({super.key, required super.child});

  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<FgShellScope>() != null;

  @override
  bool updateShouldNotify(FgShellScope oldWidget) => false;
}

/// Barra lateral fija para todas las pantallas privadas en tablet y escritorio (§23, ley de Jakob y
/// consistencia): la navegación no desaparece al entrar a una pantalla interna. En móvil devuelve el
/// contenido tal cual: cada pantalla interna conserva su encabezado con «Volver».
class FgNavLateral extends StatelessWidget {
  const FgNavLateral({super.key, required this.destinos, required this.child, this.pie});

  final List<FgDestino> destinos;
  final Widget child;
  final FgPieLateral? pie;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    if (FgBreakpoint.esCompacto(ancho) || destinos.isEmpty) return child;
    return Material(
      color: FgColors.fondo,
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _BarraLateral(destinos: destinos, pie: pie, colapsada: !FgBreakpoint.esDesktop(ancho)),
        Expanded(child: FgShellScope(child: child)),
      ]),
    );
  }
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
    this.pie,
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

  /// Sesión y «Cerrar sesión» al pie de la barra lateral (tablet y escritorio).
  final FgPieLateral? pie;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    // Dentro de [FgNavLateral] la barra lateral ya está: solo la barra superior y el contenido.
    if (!FgBreakpoint.esCompacto(ancho) && FgShellScope.of(context)) {
      return Scaffold(
        backgroundColor: FgColors.fondo,
        body: Column(children: [
          _BarraSuperior(titulo: titulo, acciones: accionesSuperiores),
          Expanded(child: cuerpo),
        ]),
      );
    }
    if (ancho >= FgBreakpoint.desktop) {
      return Scaffold(
        backgroundColor: FgColors.fondo,
        body: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _BarraLateral(destinos: destinos, pie: pie),
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
          _BarraLateral(destinos: destinos, pie: pie, colapsada: true),
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
  const _BarraLateral({required this.destinos, this.pie, this.colapsada = false});

  final List<FgDestino> destinos;
  final FgPieLateral? pie;
  final bool colapsada;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: 'Navegación principal',
        child: Container(
          key: const ValueKey('navegacion-lateral'),
          width: colapsada ? FgSize.sidebarColapsado : FgSize.sidebar,
          decoration: BoxDecoration(
            color: FgColors.superficie,
            border: Border(right: BorderSide(color: FgColors.lineaSuave, width: FgBorder.w1)),
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
                          FgColors.logoCompleto,
                          width: FgSize.logoBarraLateral,
                          semanticLabel: 'FarmaGo',
                        ),
                ),
                // Los destinos se desplazan si no caben; el pie queda siempre visible abajo.
                Expanded(
                  child: ListView(padding: EdgeInsets.zero, children: [
                    for (final destino in destinos)
                      Padding(
                        padding: const EdgeInsets.only(bottom: FgSpace.sp1),
                        child: _ItemLateral(destino: destino, colapsada: colapsada),
                      ),
                  ]),
                ),
                if (pie != null) _PieLateral(pie: pie!, colapsada: colapsada),
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
          // Icono + etiqueta (§23): se reconoce el destino sin leer. Inactivos en tinta suave.
          ExcludeSemantics(
            child: Icon(d.icono, size: FgSize.iconoMd, color: activo ? FgColors.azulTexto : FgColors.navInactivo),
          ),
          if (!widget.colapsada) ...[
            const SizedBox(width: FgSpace.sp3),
            Expanded(
              child: Text(
                d.etiqueta,
                style: (activo ? FgText.label : FgText.labelMedio).copyWith(
                  color: activo ? FgColors.azulTexto : FgColors.ink,
                  fontWeight: activo ? FgWeight.bold : FgWeight.medio,
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
            hoverColor: activo ? FgColors.azul200 : FgColors.azul50,
            child: contenido,
          ),
        ),
      ),
    ));
    if (!widget.colapsada) return item;
    return Tooltip(message: d.etiqueta, child: item);
  }
}

class _PieLateral extends StatefulWidget {
  const _PieLateral({required this.pie, required this.colapsada});

  final FgPieLateral pie;
  final bool colapsada;

  @override
  State<_PieLateral> createState() => _PieLateralState();
}

class _PieLateralState extends State<_PieLateral> {
  bool _saliendo = false;

  Future<void> _cerrarSesion() async {
    if (_saliendo) return;
    setState(() => _saliendo = true);
    try {
      await widget.pie.onCerrarSesion();
    } finally {
      if (mounted) setState(() => _saliendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: FgSpace.sp3),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: FgColors.lineaSuave, width: FgBorder.w1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _ItemLateral(
          colapsada: widget.colapsada,
          destino: FgDestino(
            icono: Icons.logout,
            etiqueta: _saliendo ? 'Cerrando sesión…' : 'Cerrar sesión',
            onTap: _cerrarSesion,
          ),
        ),
      ]),
    );
  }
}

/// Quién tiene la sesión abierta, en la barra superior junto a las notificaciones: inicial, nombre
/// y rol. En pantallas angostas queda solo la inicial.
///
/// Con [onCerrarSesion], tocarlo abre el menú de la cuenta (datos, Mi cuenta, Apariencia y Cerrar
/// sesión); sin él, abre «Mi cuenta» directamente.
class FgCuentaChip extends StatefulWidget {
  const FgCuentaChip({
    super.key,
    required this.nombre,
    required this.rol,
    required this.onTap,
    this.correo,
    this.onCerrarSesion,
  });

  final String nombre;

  /// Rol legible («Paciente», «Repartidor»…).
  final String rol;

  /// Abre «Mi cuenta».
  final VoidCallback onTap;
  final String? correo;
  final Future<void> Function()? onCerrarSesion;

  @override
  State<FgCuentaChip> createState() => _FgCuentaChipState();
}

class _FgCuentaChipState extends State<FgCuentaChip> {
  final _focus = FocusNode();
  final _menu = MenuController();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  bool get _conMenu => widget.onCerrarSesion != null;

  static const _anchoMenu = 336.0;

  void _tocar() {
    if (!_conMenu) return widget.onTap();
    if (_menu.isOpen) return _menu.close();
    // Alineado al borde derecho del chip, que está al final de la barra superior.
    final caja = context.findRenderObject() as RenderBox?;
    final tamano = caja?.size ?? Size.zero;
    _menu.open(position: Offset(tamano.width - _anchoMenu, tamano.height + FgSpace.sp2));
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.nombre.trim();
    final inicial = nombre.isEmpty ? '?' : nombre.characters.first.toUpperCase();
    final compacto = MediaQuery.sizeOf(context).width < FgBreakpoint.desktop;
    final avatar = _Avatar(inicial: inicial, lado: FgSize.ctrlSm);
    final contenido = Padding(
      padding: EdgeInsets.fromLTRB(FgSpace.sp1, FgSpace.sp1, compacto ? FgSpace.sp1 : FgSpace.sp3, FgSpace.sp1),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        avatar,
        if (!compacto) ...[
          const SizedBox(width: FgSpace.sp3),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nombre.isEmpty ? 'Mi cuenta' : nombre,
                  style: FgText.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(widget.rol, style: FgText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ],
      ]),
    );
    final quien = '${nombre.isEmpty ? '' : '$nombre, '}${widget.rol}';
    final chip = Tooltip(
      message: _conMenu ? 'Tu cuenta' : 'Mi cuenta',
      child: _Presionable(
        child: Semantics(
          button: true,
          label: _conMenu ? 'Menú de tu cuenta. $quien' : 'Mi cuenta. $quien',
          excludeSemantics: true,
          child: FgFocusRing(
            focusNode: _focus,
            radius: FgRadius.pill,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(FgRadius.pill),
              child: InkWell(
                focusNode: _focus,
                borderRadius: BorderRadius.circular(FgRadius.pill),
                onTap: _tocar,
                hoverColor: FgColors.azul50,
                child: ConstrainedBox(constraints: const BoxConstraints(minHeight: FgSize.ctrlMd), child: contenido),
              ),
            ),
          ),
        ),
      ),
    );
    if (!_conMenu) return chip;
    return MenuAnchor(
      controller: _menu,
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(FgColors.superficie),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: WidgetStatePropertyAll(FgColors.sombraMaterial),
        elevation: const WidgetStatePropertyAll(3),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FgRadius.md),
          side: BorderSide(color: FgColors.lineaSuave, width: FgBorder.w1),
        )),
      ),
      menuChildren: [
        _MenuCuenta(
          inicial: inicial,
          nombre: nombre,
          correo: widget.correo,
          rol: widget.rol,
          onMiCuenta: () {
            _menu.close();
            widget.onTap();
          },
          onCerrarSesion: () {
            _menu.close();
            widget.onCerrarSesion!();
          },
        ),
      ],
      child: chip,
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.inicial, required this.lado});

  final String inicial;
  final double lado;

  @override
  Widget build(BuildContext context) => Container(
        width: lado,
        height: lado,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: FgColors.azul100, shape: BoxShape.circle),
        child: Text(
          inicial,
          style: (lado > FgSize.ctrlSm ? FgText.h3 : FgText.label)
              .copyWith(color: FgColors.azulTexto, fontWeight: FgWeight.bold),
        ),
      );
}

/// Menú de la cuenta: quién es, Mi cuenta, Apariencia y Cerrar sesión. La apariencia se cambia
/// ahí mismo y se ve al instante; el menú no se cierra para que se pueda comparar.
class _MenuCuenta extends StatelessWidget {
  const _MenuCuenta({
    required this.inicial,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.onMiCuenta,
    required this.onCerrarSesion,
  });

  final String inicial, nombre, rol;
  final String? correo;
  final VoidCallback onMiCuenta, onCerrarSesion;

  @override
  Widget build(BuildContext context) {
    final separador = Divider(height: FgBorder.w1, thickness: FgBorder.w1, color: FgColors.lineaSuave);
    return SizedBox(
      width: _FgCuentaChipState._anchoMenu,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.all(FgSpace.sp4),
          child: Row(children: [
            _Avatar(inicial: inicial, lado: FgSize.tapMin),
            const SizedBox(width: FgSpace.sp3),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nombre.isEmpty ? 'Tu cuenta' : nombre,
                    style: FgText.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (correo != null && correo!.isNotEmpty)
                  Text(correo!, style: FgText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(rol, style: FgText.caption.copyWith(color: FgColors.azulTexto, fontWeight: FgWeight.semibold)),
              ]),
            ),
          ]),
        ),
        separador,
        _ItemMenu(icono: Icons.person_outline, etiqueta: 'Mi cuenta', onPressed: onMiCuenta),
        separador,
        Padding(
          padding: const EdgeInsets.fromLTRB(FgSpace.sp4, FgSpace.sp3, FgSpace.sp4, FgSpace.sp4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Apariencia', style: FgText.captionFuerte),
            const SizedBox(height: FgSpace.sp2),
            const FgSelectorApariencia(),
          ]),
        ),
        separador,
        _ItemMenu(icono: Icons.logout, etiqueta: 'Cerrar sesión', onPressed: onCerrarSesion),
      ]),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu({required this.icono, required this.etiqueta, required this.onPressed});

  final IconData icono;
  final String etiqueta;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => MenuItemButton(
        onPressed: onPressed,
        leadingIcon: Icon(icono, size: FgSize.iconoMd, color: FgColors.inkSoft),
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(FgSize.tapMin + FgSpace.sp1)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: FgSpace.sp4)),
          foregroundColor: WidgetStatePropertyAll(FgColors.ink),
          overlayColor: WidgetStatePropertyAll(FgColors.azul50),
          textStyle: WidgetStatePropertyAll(FgText.labelMedio),
        ),
        child: Text(etiqueta),
      );
}

class _BarraSuperior extends StatelessWidget {
  const _BarraSuperior({required this.titulo, required this.acciones});

  final String titulo;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) => Container(
        height: FgSize.topbar,
        padding: const EdgeInsets.symmetric(horizontal: FgSpace.sp6),
        decoration: BoxDecoration(
          color: FgColors.superficie,
          border: Border(bottom: BorderSide(color: FgColors.lineaSuave, width: FgBorder.w1)),
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
        decoration: BoxDecoration(
          color: FgColors.superficie,
          border: Border(top: BorderSide(color: FgColors.lineaSuave, width: FgBorder.w1)),
          boxShadow: FgShadow.barra,
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
                  // Icono + etiqueta (§23, ley de Jakob): el destino activo lleva el icono dentro de
                  // una píldora azul 100; los inactivos van en tinta suave, no en verde.
                  AnimatedContainer(
                    duration: FgMotion.reducir(context, FgMotion.micro),
                    curve: FgMotion.ease,
                    width: FgSize.navIndicadorAncho,
                    height: FgSize.navIndicadorAlto,
                    decoration: BoxDecoration(
                      color: activo ? FgColors.azul100 : Colors.transparent,
                      borderRadius: BorderRadius.circular(FgRadius.pill),
                    ),
                    child: Icon(
                      d.icono,
                      size: FgSize.iconoMd,
                      color: activo ? FgColors.azulTexto : FgColors.navInactivo,
                    ),
                  ),
                  const SizedBox(height: FgSpace.sp1),
                  Text(
                    d.etiqueta,
                    overflow: TextOverflow.ellipsis,
                    style: FgText.navMovil.copyWith(
                      color: activo ? FgColors.azulTexto : FgColors.navInactivo,
                      fontWeight: activo ? FgWeight.bold : FgWeight.medio,
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

/// Respuesta al presionar para destinos de navegación: escala 0.98 en 150 ms (§23), interrumpible y sin movimiento
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
          scale: _presionado ? FgMotion.escalaPresion : 1,
          duration: FgMotion.reducir(context, FgMotion.micro),
          curve: FgMotion.ease,
          child: widget.child,
        ),
      );
}
