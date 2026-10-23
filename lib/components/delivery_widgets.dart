import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
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

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.tone = StatusTone.neutral});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      StatusTone.success => (context.status.successContainer, context.status.onSuccessContainer),
      StatusTone.warning => (context.status.warningContainer, context.status.onWarningContainer),
      StatusTone.error => (context.colors.errorContainer, context.colors.onErrorContainer),
      StatusTone.neutral => (context.status.brandSurface, context.colors.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadii.s)),
      child: Text(label, style: context.text.labelMedium?.copyWith(color: foreground, fontWeight: FontWeight.w700)),
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
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text('• ${item.name} × ${item.quantity}', style: context.text.bodyMedium),
            ),
        ],
      );
}

/// Shared page frame for the delivery screens (max width, back button, title).
class DeliveryScaffold extends StatelessWidget {
  const DeliveryScaffold({
    super.key,
    required this.title,
    required this.onBack,
    required this.children,
    this.onRefresh,
    this.floatingActionButton,
  });

  final String title;
  final VoidCallback onBack;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.m, AppSpacing.xl, AppSpacing.xxl * 2),
      children: children,
    );
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(tooltip: 'Volver', icon: const Icon(Icons.arrow_back), onPressed: onBack),
        title: Text(title),
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: onRefresh == null ? list : RefreshIndicator(onRefresh: onRefresh!, child: list),
          ),
        ),
      ),
    );
  }
}

/// Empty-state message with an icon.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title, message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(children: [
          Icon(icon, size: 48, color: context.colors.primary),
          const SizedBox(height: AppSpacing.m),
          Text(title, style: context.text.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(message, style: context.text.bodyMedium, textAlign: TextAlign.center),
        ]),
      );
}
