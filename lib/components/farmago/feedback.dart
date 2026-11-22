import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';
import '../../errors/app_error.dart';
import 'buttons.dart';

enum FgBannerKind { info, aviso, error, exito }

/// Círculo de 28 px con el símbolo blanco del aviso (compartido por banner y toast).
class FgGlifo extends StatelessWidget {
  const FgGlifo({super.key, required this.color, required this.simbolo, this.diametro = 28, this.tamanoSimbolo = 16});

  final Color color;

  /// "i", "!" o un icono (check, x).
  final Object simbolo;
  final double diametro;
  final double tamanoSimbolo;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: diametro,
          height: diametro,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: simbolo is IconData
              ? Icon(simbolo as IconData, size: tamanoSimbolo, color: FgColors.blanco)
              : Text(
                  simbolo as String,
                  style: TextStyle(
                    fontFamily: FgText.family,
                    fontSize: tamanoSimbolo,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: FgColors.blanco,
                  ),
                ),
        ),
      );
}

/// Banner (§7.9): aviso persistente en el flujo de la pantalla, de superficie clara y sin sombra.
class FgBanner extends StatelessWidget {
  const FgBanner({
    super.key,
    required this.kind,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
    this.referencia,
  });

  final FgBannerKind kind;
  final String message;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Código de soporte (se muestra discreto, además del mensaje).
  final String? referencia;

  (Color, Object) get _glifo => switch (kind) {
        FgBannerKind.info => (FgColors.azul600, 'i'),
        FgBannerKind.aviso => (FgColors.riesgoSolid, '!'),
        FgBannerKind.error => (FgColors.peligro, Icons.close),
        FgBannerKind.exito => (FgColors.cumplidoSolid, Icons.check),
      };

  @override
  Widget build(BuildContext context) {
    final (color, simbolo) = _glifo;
    final ancho = MediaQuery.sizeOf(context).width;
    final accion = actionLabel != null && onAction != null
        ? FgLinkButton(label: actionLabel!, onPressed: onAction)
        : null;
    final texto = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) Text(title!, style: FgText.label),
        Text(message, style: FgText.body.copyWith(color: FgColors.inkSoft)),
        if (referencia != null) Text('Código de referencia: $referencia', style: FgText.caption),
        if (accion != null && FgBreakpoint.esCompacto(ancho)) accion,
      ],
    );
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: FgSpace.sp4h, vertical: FgSpace.sp4),
        decoration: BoxDecoration(
          color: FgColors.superficie,
          borderRadius: BorderRadius.circular(FgRadius.md),
          border: Border.all(color: FgColors.lineaSuave, width: FgBorder.w1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FgGlifo(color: color, simbolo: simbolo),
            const SizedBox(width: FgSpace.sp3),
            Expanded(child: texto),
            if (accion != null && !FgBreakpoint.esCompacto(ancho)) ...[const SizedBox(width: FgSpace.sp4), accion],
          ],
        ),
      ),
    );
  }
}

/// Nota (§7.9): aclaración silenciosa y permanente, sin fondo ni borde.
class FgNota extends StatelessWidget {
  const FgNota({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FgGlifo(color: FgColors.azul600, simbolo: 'i', diametro: 24, tamanoSimbolo: 14),
          const SizedBox(width: FgSpace.sp3),
          Expanded(child: Text(texto, style: FgText.caption)),
        ],
      );
}

/// Estado vacío (§8.15). Una ilustración es opcional según el manual §22 (solo para situaciones
/// sin datos y nunca en lugar del texto y la acción); hoy ningún estado vacío la usa.
class FgEmptyState extends StatelessWidget {
  const FgEmptyState({super.key, required this.titulo, required this.mensaje, this.accionLabel, this.onAccion});

  final String titulo;
  final String mensaje;
  final String? accionLabel;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: FgSpace.sp8, horizontal: FgSpace.sp4),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: FgSize.dialogSm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(header: true, child: Text(titulo, style: FgText.h2, textAlign: TextAlign.center)),
                const SizedBox(height: FgSpace.sp2),
                Text(mensaje, style: FgText.body.copyWith(color: FgColors.inkSoft), textAlign: TextAlign.center),
                if (accionLabel != null && onAccion != null) ...[
                  const SizedBox(height: FgSpace.sp5),
                  FgButton(label: accionLabel!, onPressed: onAccion, variant: FgButtonVariant.secondary),
                ],
              ],
            ),
          ),
        ),
      );
}

/// Lista cargando (§23, umbral de Doherty): tarjetas esqueleto con la forma del contenido que viene,
/// en vez de un spinner centrado. Se anuncia una sola vez a lectores de pantalla.
class FgListaCargando extends StatelessWidget {
  const FgListaCargando({super.key, this.cantidad = 3, this.etiqueta = 'Cargando'});

  final int cantidad;
  final String etiqueta;

  @override
  Widget build(BuildContext context) => Semantics(
        label: etiqueta,
        liveRegion: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < cantidad; i++) ...[
            if (i > 0) const SizedBox(height: FgSpace.sp4),
            Container(
              padding: const EdgeInsets.all(FgSpace.sp5),
              decoration: FgDecor.tarjeta(),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FgSkeleton(ancho: FgSize.panel / 2, alto: FgSpace.sp5),
                SizedBox(height: FgSpace.sp3),
                FgSkeleton(alto: FgSpace.sp4),
                SizedBox(height: FgSpace.sp2),
                FgSkeleton(ancho: FgSize.panel / 3, alto: FgSpace.sp4),
              ]),
            ),
          ],
        ]),
      );
}

/// Esqueleto de carga (§8.15): bloque `--skeleton` con brillo de 1400 ms (sin brillo si se reduce el movimiento).
class FgSkeleton extends StatefulWidget {
  const FgSkeleton({super.key, this.ancho, required this.alto, this.radio = FgRadius.sm});

  final double? ancho;
  final double alto;
  final double radio;

  @override
  State<FgSkeleton> createState() => _FgSkeletonState();
}

class _FgSkeletonState extends State<FgSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _brillo = AnimationController(vsync: this, duration: FgMotion.brilloSkeleton);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _brillo.stop();
    } else if (!_brillo.isAnimating) {
      _brillo.repeat();
    }
  }

  @override
  void dispose() {
    _brillo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _brillo,
          builder: (context, _) {
            final t = _brillo.value;
            return Container(
              width: widget.ancho,
              height: widget.alto,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radio),
                // Brillo de carga (manual §8.15 y §22): indica un estado de carga, no es decoración.
                gradient: LinearGradient(
                  begin: Alignment(-2 + 4 * t, 0),
                  end: Alignment(-1 + 4 * t, 0),
                  colors: const [FgColors.skeleton, FgColors.fondoHundido, FgColors.skeleton],
                ),
              ),
            );
          },
        ),
      );
}

enum FgToastKind { exito, error, info }

/// Toast (§7.8): confirma algo que ya ocurrió. Oscuro, flota sobre todo (también sobre paneles
/// y diálogos), se cierra solo a los 6 s; los errores no se cierran solos.
///
/// Se muestra uno a la vez: uno nuevo reemplaza al anterior. [detalle] es una segunda línea, más
/// suave, con lo que sigue («Te avisamos cuando un repartidor lo tome»).
void showFgToast(
  BuildContext context,
  String mensaje, {
  FgToastKind kind = FgToastKind.exito,
  double separacionInferior = 0,
  String? detalle,
}) {
  final overlay = FgCapaAvisos._capa.currentState ?? Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _ToastHost.mostrar(overlay, mensaje, detalle, kind, separacionInferior);
}

/// Aviso sin `BuildContext`, para cuando la pantalla que hizo la acción ya se cerró (por ejemplo,
/// al verificar el código el enrutador lleva a otra pantalla). Necesita [FgCapaAvisos] en la app.
void avisar(String mensaje, {String? detalle, FgToastKind kind = FgToastKind.exito}) {
  final overlay = FgCapaAvisos._capa.currentState;
  if (overlay == null) return;
  _ToastHost.mostrar(overlay, mensaje, detalle, kind, 0);
}

/// Capa de avisos por encima de todas las pantallas (va en `MaterialApp.builder`). Así un aviso
/// sigue visible aunque el enrutador cambie de pantalla o reconstruya su navegador.
class FgCapaAvisos extends StatefulWidget {
  const FgCapaAvisos({super.key, required this.child});

  final Widget child;

  static final _capa = GlobalKey<OverlayState>(debugLabel: 'FgCapaAvisos');

  @override
  State<FgCapaAvisos> createState() => _FgCapaAvisosState();
}

class _FgCapaAvisosState extends State<FgCapaAvisos> {
  late final _app = OverlayEntry(builder: (_) => widget.child);

  @override
  void didUpdateWidget(FgCapaAvisos oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) _app.markNeedsBuild();
  }

  @override
  void dispose() {
    _ToastHost.cerrar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Overlay(key: FgCapaAvisos._capa, initialEntries: [_app]);
}

abstract final class _ToastHost {
  static OverlayEntry? _entrada;

  static void mostrar(OverlayState overlay, String mensaje, String? detalle, FgToastKind kind, double separacion) {
    cerrar();
    late final OverlayEntry entrada;
    entrada = OverlayEntry(
      builder: (context) => _ToastView(
        key: UniqueKey(),
        mensaje: mensaje,
        detalle: detalle,
        kind: kind,
        separacionInferior: separacion,
        onCerrar: () {
          if (identical(_entrada, entrada)) cerrar();
        },
      ),
    );
    _entrada = entrada;
    overlay.insert(entrada);
  }

  static void cerrar() {
    final entrada = _entrada;
    _entrada = null;
    if (entrada != null && entrada.mounted) entrada.remove();
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({
    super.key,
    required this.mensaje,
    required this.detalle,
    required this.kind,
    required this.separacionInferior,
    required this.onCerrar,
  });

  final String mensaje;
  final String? detalle;
  final FgToastKind kind;
  final double separacionInferior;
  final VoidCallback onCerrar;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> {
  static const _duracion = Duration(seconds: 6);

  /// El aviso es dueño de su temporizador: si la app o la pantalla desaparecen, se cancela con él.
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    _armar();
  }

  void _armar() {
    _temporizador?.cancel();
    if (widget.kind == FgToastKind.error) return; // los errores no se cierran solos
    _temporizador = Timer(_duracion, widget.onCerrar);
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _ToastView(:mensaje, :detalle, :kind, :separacionInferior, :onCerrar) = widget;
    final medidas = MediaQuery.of(context);
    final compacto = FgBreakpoint.esCompacto(medidas.size.width);
    final (color, simbolo) = switch (kind) {
      FgToastKind.exito => (FgColors.cumplidoSolid, Icons.check),
      FgToastKind.error => (FgColors.peligro, Icons.close),
      FgToastKind.info => (FgColors.azul600, Icons.info_outline),
    };
    final tarjeta = MouseRegion(
      // Con el puntero encima no se cierra: da tiempo a leerlo.
      onEnter: (_) => _temporizador?.cancel(),
      onExit: (_) => _armar(),
      child: Material(
        color: FgColors.ink,
        borderRadius: BorderRadius.circular(FgRadius.md),
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(FgSpace.sp4h, FgSpace.sp4, FgSpace.sp2, FgSpace.sp4),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(FgRadius.md), boxShadow: FgShadow.e3),
          child: Row(
            // Con dos líneas, el símbolo y el botón de cerrar se alinean con el título.
            crossAxisAlignment: detalle == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              if (kind == FgToastKind.exito) const _CheckQueSeDibuja() else FgGlifo(color: color, simbolo: simbolo),
              const SizedBox(width: FgSpace.sp3),
              // Un mensaje muy largo se desplaza dentro del aviso en vez de salirse de la pantalla.
              Expanded(
                child: SingleChildScrollView(
                  child: detalle == null
                      ? Text(mensaje, style: FgText.body.copyWith(color: FgColors.blanco))
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(mensaje, style: FgText.label.copyWith(color: FgColors.blanco)),
                          const SizedBox(height: FgSpace.sp1),
                          Text(detalle, style: FgText.body.copyWith(color: FgColors.blanco.withValues(alpha: .72))),
                        ]),
                ),
              ),
              Transform.translate(
                // Con dos líneas, la X queda a la altura del título.
                offset: Offset(0, detalle == null ? 0 : -FgSpace.sp2),
                child: IconButton(
                  tooltip: 'Cerrar aviso',
                  onPressed: onCerrar,
                  constraints: const BoxConstraints(minWidth: FgSize.ctrlSm, minHeight: FgSize.ctrlSm),
                  icon: const Icon(Icons.close, color: FgColors.blanco, size: FgSize.iconoMd),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final margen = compacto ? FgSpace.sp4 : FgSpace.sp5;
    // Sobre el teclado si está abierto, para que el aviso no quede tapado en el celular.
    final abajo = margen +
        (medidas.viewInsets.bottom > 0 ? medidas.viewInsets.bottom : medidas.padding.bottom) +
        separacionInferior;
    // Nunca más alto que el espacio libre: así no se sale por arriba de la pantalla.
    final altoMaximo =
        math.max(FgSize.ctrlSm + 2 * FgSpace.sp4, medidas.size.height - abajo - medidas.padding.top - margen);
    return Positioned(
      left: margen,
      right: compacto ? margen : null,
      bottom: abajo,
      width: compacto ? null : FgSize.toast,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: FgMotion.reducir(context, FgMotion.media),
        curve: FgMotion.ease,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, FgSpace.sp4 * (1 - t)), child: child),
        ),
        child: Semantics(
          container: true,
          liveRegion: true,
          label: [if (kind == FgToastKind.error) 'Error:', mensaje, if (detalle != null) detalle].join(' '),
          child: ConstrainedBox(constraints: BoxConstraints(maxHeight: altoMaximo), child: tarjeta),
        ),
      ),
    );
  }
}

/// El check de un aviso de éxito se dibuja solo, trazo a trazo, justo después de que aparece la
/// tarjeta: es la confirmación visible de que la acción terminó. Con movimiento reducido aparece
/// ya dibujado.
class _CheckQueSeDibuja extends StatefulWidget {
  const _CheckQueSeDibuja();

  @override
  State<_CheckQueSeDibuja> createState() => _CheckQueSeDibujaState();
}

class _CheckQueSeDibujaState extends State<_CheckQueSeDibuja> with SingleTickerProviderStateMixin {
  late final _trazo = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _trazo.value = 1;
    } else if (!_trazo.isAnimating && _trazo.value == 0) {
      _trazo.forward();
    }
  }

  @override
  void dispose() {
    _trazo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox.square(
          dimension: 28,
          child: AnimatedBuilder(
            animation: _trazo,
            builder: (context, _) => CustomPaint(
              painter: _CheckPainter(
                // El círculo entra en el primer tercio; el check se traza después.
                circulo: FgMotion.ease.transform((_trazo.value * 3).clamp(0, 1)),
                trazo: Curves.easeOutCubic.transform(((_trazo.value - .3) / .7).clamp(0, 1)),
              ),
            ),
          ),
        ),
      );
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.circulo, required this.trazo});

  final double circulo, trazo;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    canvas.drawCircle(
      centro,
      size.width / 2 * (.6 + .4 * circulo),
      Paint()..color = FgColors.cumplidoSolid.withValues(alpha: circulo),
    );
    if (trazo == 0) return;
    final w = size.width;
    final check = Path()
      ..moveTo(w * .29, w * .52)
      ..lineTo(w * .44, w * .66)
      ..lineTo(w * .72, w * .37);
    final metrica = check.computeMetrics().first;
    canvas.drawPath(
      metrica.extractPath(0, metrica.length * trazo),
      Paint()
        ..color = FgColors.blanco
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.circulo != circulo || old.trazo != trazo;
}

// Errores, carga y avisos de la app (antes en components/feedback.dart).

/// Inline error for forms and sections; announced by screen readers (FE-008).
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.error});

  final AppError? error;

  @override
  Widget build(BuildContext context) {
    final current = error;
    if (current == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: FgSpace.sp4),
      child: FgBanner(
        kind: FgBannerKind.error,
        message: current.userMessage,
        referencia: current.showsReference ? current.referenceId : null,
      ),
    );
  }
}

/// Discreet support reference, shown in addition to (never instead of) the message.
class ReferenceText extends StatelessWidget {
  const ReferenceText({super.key, required this.error});

  final AppError error;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: FgSpace.sp1),
        child: SelectableText('Código de referencia: ${error.referenceId}', style: FgText.caption),
      );
}

/// Full-screen or section error with a recovery action (frontend-guardian §4).
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.title,
    required this.error,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryIcon = Icons.refresh,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final AppError error;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FgSpace.sp5),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: FgSize.dialogSm),
            child: Semantics(
              liveRegion: true,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const FgGlifo(color: FgColors.peligro, simbolo: Icons.close, diametro: 56, tamanoSimbolo: 32),
                const SizedBox(height: FgSpace.sp5),
                Semantics(
                  header: true,
                  child: Text(title, style: FgText.h2, textAlign: TextAlign.center),
                ),
                const SizedBox(height: FgSpace.sp2),
                Text(error.userMessage, style: FgText.body.copyWith(color: FgColors.inkSoft), textAlign: TextAlign.center),
                if (error.showsReference) ReferenceText(error: error),
                const SizedBox(height: FgSpace.sp6),
                FgButton(
                  label: primaryLabel,
                  icon: primaryIcon,
                  expand: true,
                  onPressed: onPrimary,
                ),
                if (secondaryLabel != null && onSecondary != null) ...[
                  const SizedBox(height: FgSpace.sp3),
                  FgButton(
                    label: secondaryLabel!,
                    variant: FgButtonVariant.secondary,
                    expand: true,
                    onPressed: onSecondary,
                  ),
                ],
              ]),
            ),
          ),
        ),
      );
}

/// Spinner that only appears after a short delay, avoiding flicker (frontend-guardian §3).
class DelayedSpinner extends StatefulWidget {
  const DelayedSpinner({super.key, this.size = 40, this.label = 'Cargando'});

  final double size;
  final String label;

  @override
  State<DelayedSpinner> createState() => _DelayedSpinnerState();
}

class _DelayedSpinnerState extends State<DelayedSpinner> {
  static const _delay = Duration(milliseconds: 300);
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: _visible
            ? Semantics(label: widget.label, child: Center(child: FgSpinner(size: widget.size)))
            : null,
      );
}

/// Aviso breve de algo que ya ocurrió. Sin acción usa el toast del manual, para que los avisos de
/// la app se vean y se comporten igual (los errores no se cierran solos). Con acción (por ejemplo
/// "Deshacer") usa la barra inferior, que es la que admite un botón.
void showAppSnackBar(BuildContext context, String message, {SnackBarAction? action, bool error = false}) {
  if (action == null) {
    showFgToast(context, message, kind: error ? FgToastKind.error : FgToastKind.exito);
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 6), action: action));
}
