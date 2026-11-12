import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../app/theme/farmago_tokens.dart';
import 'farmago/buttons.dart';
import 'farmago/feedback.dart';
import 'farmago/layout.dart';
import '../types/delivery.dart';
import '../types/order.dart';

/// Step-by-step progress of a delivery, readable by screen readers.
class DeliveryProgress extends StatelessWidget {
  const DeliveryProgress({super.key, required this.status});

  final DeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == DeliveryStatus.cancelled || status == DeliveryStatus.failed) {
      return StatusChip(label: status.label, tone: StatusTone.error);
    }
    final current = DeliveryStatus.steps.indexOf(status);
    return Semantics(
      label: 'Estado del domicilio: ${status.label}',
      child: ExcludeSemantics(
        child: Column(children: [
          for (final (index, step) in DeliveryStatus.steps.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(children: [
                Icon(
                  index < current
                      ? Icons.check_circle
                      : index == current
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                  size: 20,
                  color: index <= current ? context.colors.primary : context.status.decorative,
                ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  step.label,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: index == current ? FontWeight.w700 : FontWeight.w400,
                    color: index <= current ? context.colors.onSurface : context.status.mutedText,
                  ),
                ),
              ]),
            ),
        ]),
      ),
    );
  }
}

enum StatusTone { neutral, success, warning, error }

/// Sello de estado del domicilio (manual §8.8): forma + símbolo + palabra, nunca solo color.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.tone = StatusTone.neutral});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, symbol) = switch (tone) {
      StatusTone.success => (FgColors.cumplidoBg, FgColors.cumplidoFg, Icons.check_rounded),
      StatusTone.warning => (FgColors.riesgoBg, FgColors.riesgoFg, Icons.schedule_rounded),
      StatusTone.error => (FgColors.incumplidoBg, FgColors.incumplidoFg, Icons.close_rounded),
      StatusTone.neutral => (FgColors.vigenteBg, FgColors.vigenteFg, Icons.circle),
    };
    return Semantics(
      label: 'Estado: $label',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: FgSize.selloAlto),
        padding: const EdgeInsets.symmetric(horizontal: FgSpace.sp3),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(FgRadius.pill)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(symbol, size: tone == StatusTone.neutral ? FgSize.simboloMini - 4 : FgSize.simboloSm, color: foreground),
          const SizedBox(width: FgSpace.sp2),
          Flexible(
            child: Text(label, style: FgText.caption.copyWith(color: foreground, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

StatusTone toneForOrder(OrderStatus status) => switch (status) {
      OrderStatus.published => StatusTone.warning,
      OrderStatus.taken => StatusTone.success,
      OrderStatus.cancelled => StatusTone.error,
      OrderStatus.unknown => StatusTone.neutral,
    };

/// Simple titled list of requested items.
class OrderItemsList extends StatelessWidget {
  const OrderItemsList({super.key, required this.items});

  final List<OrderItem> items;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: FgSpace.sp1),
              child: Text('• ${item.name} × ${item.quantity}', style: FgText.body),
            ),
        ],
      );
}

/// Marco de las pantallas de domicilios y administración: [FgScreen] del manual (encabezado de
/// 56/64 px con "Volver", título `h1` en pantallas anchas), contenido a ancho de lectura y barra de
/// acción fija opcional para la acción principal.
class DeliveryScaffold extends StatelessWidget {
  const DeliveryScaffold({
    super.key,
    required this.title,
    required this.onBack,
    required this.children,
    this.onRefresh,
    this.barraAccion,
  });

  final String title;
  final VoidCallback onBack;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  /// Acción principal fija abajo (por ejemplo, "Pedir domicilio").
  final Widget? barraAccion;

  @override
  Widget build(BuildContext context) => FarmaGoThemed(
        child: FgScreen(
          titulo: title,
          onBack: onBack,
          onRefresh: onRefresh,
          barraAccion: barraAccion,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: FgSize.lectura),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
              ),
            ),
          ],
        ),
      );
}

/// Estado vacío del manual (§8.15): título, qué pasa y qué hacer.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message});

  /// Se conserva por compatibilidad; el manual no usa iconos decorativos en estados vacíos.
  final IconData icon;
  final String title, message;

  @override
  Widget build(BuildContext context) => FgEmptyState(titulo: title, mensaje: message);
}

/// Botón principal de la barra de acción fija: ancho completo en móvil y a la derecha en pantallas
/// anchas (manual §8.1).
class PrimaryActionBar extends StatelessWidget {
  const PrimaryActionBar({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final compacto = FgBreakpoint.esCompacto(MediaQuery.sizeOf(context).width);
    final boton = FgButton(
      label: label,
      icon: icon,
      size: FgButtonSize.lg,
      expand: compacto,
      onPressed: onPressed,
    );
    return compacto ? boton : Align(alignment: Alignment.centerRight, child: boton);
  }
}

/// Título de una tarjeta o pantalla con su estado al lado. En pantallas angostas el estado baja
/// a la línea siguiente en vez de recortar el título.
class TitleWithStatus extends StatelessWidget {
  const TitleWithStatus({super.key, required this.title, required this.style, this.status});

  final String title;
  final TextStyle? style;
  final Widget? status;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: FgSpace.sp3,
        runSpacing: FgSpace.sp2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [Text(title, style: style), if (status != null) status!],
      );
}

/// Tarjeta del manual: superficie blanca, borde fino y radio medio. Agrupa lo que va junto.
class FgCard extends StatelessWidget {
  const FgCard({super.key, required this.child, this.destacada = false});

  final Widget child;

  /// Borde azul grueso para lo que pide atención ahora (una sola por pantalla).
  final bool destacada;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(FgSpace.sp5),
        decoration: FgDecor.tarjeta(destacada: destacada),
        child: child,
      );
}

/// Título de un grupo dentro de una pantalla.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: FgSpace.sp3),
        child: Semantics(header: true, child: Text(text, style: FgText.h3)),
      );
}

/// Dato secundario con su icono: se reconoce de un vistazo sin leer una etiqueta.
class InfoLine extends StatelessWidget {
  const InfoLine({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: FgSpace.sp1),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: ExcludeSemantics(child: Icon(icon, size: FgSize.iconoSm, color: FgColors.inkSoft)),
          ),
          const SizedBox(width: FgSpace.sp2),
          Expanded(child: Text(text, style: FgText.body.copyWith(color: FgColors.inkSoft))),
        ]),
      );
}
