import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../components/delivery_widgets.dart';
import '../components/feedback.dart';
import '../hooks/patient_orders_controller.dart';
import '../types/delivery.dart';
import '../types/order.dart';
import '../utils/delivery_format.dart';

/// Patient's home-delivery requests, with access to live tracking.
class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({
    super.key,
    required this.controller,
    required this.onRequest,
    required this.onTrack,
    required this.onBack,
  });

  final PatientOrdersController controller;
  final VoidCallback onRequest;
  final ValueChanged<PatientOrder> onTrack;
  final VoidCallback onBack;

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  Future<void> _cancel(PatientOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar el domicilio?'),
        content: Text('Se cancelará el pedido a ${order.pharmacy.name}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await widget.controller.cancel(order.id);
    if (mounted) showAppSnackBar(context, error?.userMessage ?? 'Domicilio cancelado.');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final c = widget.controller;
          return DeliveryScaffold(
            title: 'Mis domicilios',
            onBack: widget.onBack,
            onRefresh: c.load,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: widget.onRequest,
              icon: const Icon(Icons.add),
              label: const Text('Pedir domicilio'),
            ),
            children: [
              ErrorBanner(error: c.error),
              if (c.loading && c.orders.isEmpty) const Center(child: DelayedSpinner()),
              if (!c.loading && c.orders.isEmpty && c.error == null)
                const EmptyState(
                  icon: Icons.delivery_dining_outlined,
                  title: 'Aún no tienes domicilios',
                  message: 'Pide tus medicamentos y sigue al repartidor en el mapa.',
                ),
              for (final order in c.orders) ...[
                _OrderCard(
                  order: order,
                  deliveryStatus: c.deliveryStatusOf(order),
                  canCancel: c.canCancel(order),
                  onTrack: () => widget.onTrack(order),
                  onCancel: () => _cancel(order),
                ),
                const SizedBox(height: AppSpacing.m),
              ],
            ],
          );
        },
      );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.deliveryStatus,
    required this.canCancel,
    required this.onTrack,
    required this.onCancel,
  });

  final PatientOrder order;
  final DeliveryStatus? deliveryStatus;
  final bool canCancel;
  final VoidCallback onTrack, onCancel;

  /// The delivery status (from Geolocation) is more precise than the board status.
  (String, StatusTone) get _status {
    final delivery = deliveryStatus;
    if (order.status == OrderStatus.cancelled || delivery == null) return (order.status.label, toneForOrder(order.status));
    final tone = switch (delivery) {
      DeliveryStatus.delivered => StatusTone.success,
      DeliveryStatus.cancelled || DeliveryStatus.failed => StatusTone.error,
      DeliveryStatus.created => StatusTone.warning,
      _ => StatusTone.neutral,
    };
    return (delivery.label, tone);
  }

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(order.pharmacy.name, style: context.text.titleMedium)),
              StatusChip(label: _status.$1, tone: _status.$2),
            ]),
            const SizedBox(height: AppSpacing.xs),
            Text('Para: ${order.deliveryAddress}', style: context.text.bodySmall),
            Text(
              '${DeliveryFormat.distance(order.routeSummary.distanceMeters)} · '
              'aprox. ${DeliveryFormat.duration(order.routeSummary.durationSeconds)} de recorrido',
              style: context.text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.s),
            OrderItemsList(items: order.items),
            const SizedBox(height: AppSpacing.s),
            Wrap(spacing: AppSpacing.s, children: [
              if (order.status != OrderStatus.cancelled)
                FilledButton.icon(onPressed: onTrack, icon: const Icon(Icons.map_outlined), label: const Text('Seguir pedido')),
              if (canCancel) OutlinedButton(onPressed: onCancel, child: const Text('Cancelar')),
            ]),
          ]),
        ),
      );
}
