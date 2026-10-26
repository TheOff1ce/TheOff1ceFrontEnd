import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../components/delivery_widgets.dart';
import '../components/feedback.dart';
import '../hooks/admin_orders_controller.dart';
import '../types/admin.dart';
import '../types/delivery.dart';
import '../types/order.dart';
import '../utils/delivery_format.dart';

/// Administrators: every home-delivery order (pending by default), with tracking and cancel.
class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key, required this.controller, required this.onTrack, required this.onBack});

  final AdminOrdersController controller;
  final ValueChanged<AdminOrder> onTrack;
  final VoidCallback onBack;

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  Future<void> _cancel(AdminOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar este domicilio?'),
        content: Text(
          'Se cancelará el pedido a ${order.order.pharmacy.name} para ${order.order.deliveryAddress}. '
          'El paciente y el repartidor lo verán cancelado.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await widget.controller.cancel(order);
    if (mounted) showAppSnackBar(context, error?.userMessage ?? 'Domicilio cancelado.');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final c = widget.controller;
          return DeliveryScaffold(
            title: 'Domicilios',
            onBack: widget.onBack,
            onRefresh: c.load,
            children: [
              Wrap(spacing: AppSpacing.s, runSpacing: AppSpacing.s, children: [
                for (final filter in AdminOrderFilter.values)
                  ChoiceChip(
                    label: Text(filter.label),
                    selected: c.filter == filter,
                    onSelected: (_) => c.setFilter(filter),
                  ),
              ]),
              const SizedBox(height: AppSpacing.m),
              Semantics(
                liveRegion: true,
                child: Text(
                  c.loading ? 'Cargando…' : '${c.orders.length} ${c.orders.length == 1 ? 'domicilio' : 'domicilios'}',
                  style: context.text.bodySmall?.copyWith(color: context.status.mutedText),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              ErrorBanner(error: c.error),
              if (c.loading && c.orders.isEmpty) const Center(child: DelayedSpinner()),
              if (!c.loading && c.orders.isEmpty && c.error == null)
                const EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No hay domicilios',
                  message: 'Cuando los pacientes pidan medicamentos aparecerán aquí.',
                ),
              for (final order in c.orders) ...[
                _AdminOrderCard(
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

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({
    required this.order,
    required this.deliveryStatus,
    required this.canCancel,
    required this.onTrack,
    required this.onCancel,
  });

  final AdminOrder order;
  final DeliveryStatus? deliveryStatus;
  final bool canCancel;
  final VoidCallback onTrack, onCancel;

  (String, StatusTone) get _status {
    final o = order.order;
    final delivery = deliveryStatus;
    if (o.status == OrderStatus.cancelled || delivery == null) return (o.status.label, toneForOrder(o.status));
    final tone = switch (delivery) {
      DeliveryStatus.delivered => StatusTone.success,
      DeliveryStatus.cancelled || DeliveryStatus.failed => StatusTone.error,
      DeliveryStatus.created => StatusTone.warning,
      _ => StatusTone.neutral,
    };
    return (delivery.label, tone);
  }

  static String _short(String id) => id.length > 8 ? id.substring(0, 8) : id;

  static String _when(DateTime date) {
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${DeliveryFormat.clock(d)}';
  }

  @override
  Widget build(BuildContext context) {
    final o = order.order;
    final created = o.createdAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(o.pharmacy.name, style: context.text.titleMedium)),
            StatusChip(label: _status.$1, tone: _status.$2),
          ]),
          const SizedBox(height: AppSpacing.xs),
          Text('Recoger: ${o.pharmacy.address}', style: context.text.bodySmall),
          Text('Entregar: ${o.deliveryAddress}', style: context.text.bodySmall),
          Text(
            '${DeliveryFormat.distance(o.routeSummary.distanceMeters)} · '
            'aprox. ${DeliveryFormat.duration(o.routeSummary.durationSeconds)}'
            '${created == null ? '' : ' · pedido ${_when(created)}'}',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Paciente ${_short(order.patientId)} · '
            '${order.driverId == null ? 'sin repartidor' : 'repartidor ${_short(order.driverId!)}'}',
            style: context.text.bodySmall?.copyWith(color: context.status.mutedText),
          ),
          if (o.notes != null && o.notes!.isNotEmpty) Text('Notas: ${o.notes}', style: context.text.bodySmall),
          const SizedBox(height: AppSpacing.s),
          OrderItemsList(items: o.items),
          const SizedBox(height: AppSpacing.s),
          Wrap(spacing: AppSpacing.s, runSpacing: AppSpacing.s, children: [
            if (o.deliveryId.isNotEmpty)
              FilledButton.icon(onPressed: onTrack, icon: const Icon(Icons.map_outlined), label: const Text('Ver en el mapa')),
            if (canCancel) OutlinedButton(onPressed: onCancel, child: const Text('Cancelar')),
          ]),
        ]),
      ),
    );
  }
}
