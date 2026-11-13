import 'dart:async';

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
/// Se muestra uno a la vez: uno nuevo reemplaza al anterior.
void showFgToast(
  BuildContext context,
  String mensaje, {
  FgToastKind kind = FgToastKind.exito,
  double separacionInferior = 0,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _ToastHost.mostrar(overlay, mensaje, kind, separacionInferior);
}

abstract final class _ToastHost {
  static OverlayEntry? _entrada;
  static Timer? _temporizador;
  static const _duracion = Duration(seconds: 6);

  static void mostrar(OverlayState overlay, String mensaje, FgToastKind kind, double separacion) {
    cerrar();
    late final OverlayEntry entrada;
    entrada = OverlayEntry(
      builder: (context) => _ToastView(
        mensaje: mensaje,
        kind: kind,
        separacionInferior: separacion,
        onCerrar: cerrar,
        onPausa: () => _temporizador?.cancel(),
        onReanudar: () => _armar(kind),
      ),
    );
    _entrada = entrada;
    overlay.insert(entrada);
    _armar(kind);
  }

  static void _armar(FgToastKind kind) {
    _temporizador?.cancel();
    if (kind == FgToastKind.error) return; // los errores no se cierran solos
    _temporizador = Timer(_duracion, cerrar);
  }

  static void cerrar() {
    _temporizador?.cancel();
    _temporizador = null;
    _entrada?.remove();
    _entrada = null;
  }
}

class _ToastView extends StatelessWidget {
  const _ToastView({
    required this.mensaje,
    required this.kind,
    required this.separacionInferior,
    required this.onCerrar,
    required this.onPausa,
    required this.onReanudar,
  });

  final String mensaje;
  final FgToastKind kind;
  final double separacionInferior;
  final VoidCallback onCerrar, onPausa, onReanudar;

  @override
  Widget build(BuildContext context) {
    final medidas = MediaQuery.of(context);
    final compacto = FgBreakpoint.esCompacto(medidas.size.width);
    final (color, simbolo) = switch (kind) {
      FgToastKind.exito => (FgColors.cumplidoSolid, Icons.check),
      FgToastKind.error => (FgColors.peligro, Icons.close),
      FgToastKind.info => (FgColors.azul600, Icons.info_outline),
    };
    final tarjeta = MouseRegion(
      onEnter: (_) => onPausa(),
      onExit: (_) => onReanudar(),
      child: Material(
        color: FgColors.ink,
        borderRadius: BorderRadius.circular(FgRadius.md),
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(FgSpace.sp4h, FgSpace.sp4, FgSpace.sp2, FgSpace.sp4),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(FgRadius.md), boxShadow: FgShadow.e3),
          child: Row(
            children: [
              FgGlifo(color: color, simbolo: simbolo),
              const SizedBox(width: FgSpace.sp3),
              Expanded(child: Text(mensaje, style: FgText.body.copyWith(color: FgColors.blanco))),
              IconButton(
                tooltip: 'Cerrar aviso',
                onPressed: onCerrar,
                constraints: const BoxConstraints(minWidth: FgSize.ctrlSm, minHeight: FgSize.ctrlSm),
                icon: const Icon(Icons.close, color: FgColors.blanco, size: FgSize.iconoMd),
              ),
            ],
          ),
        ),
      ),
    );
    return Positioned(
      left: compacto ? FgSpace.sp4 : FgSpace.sp5,
      right: compacto ? FgSpace.sp4 : null,
      bottom: (compacto ? FgSpace.sp4 : FgSpace.sp5) + medidas.padding.bottom + separacionInferior,
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
          label: kind == FgToastKind.error ? 'Error: $mensaje' : mensaje,
          child: tarjeta,
        ),
      ),
    );
  }
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
