import '../components/farmago/dialogs.dart';
import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../components/delivery_widgets.dart';
import '../components/farmago/feedback.dart';
import '../hooks/admin_orders_controller.dart';
import '../types/admin.dart';
import '../types/delivery.dart';
import '../types/order.dart';
import '../utils/delivery_format.dart';
import '../components/farmago/buttons.dart';

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
    final confirmed = await showFgConfirm(
      context,
      titulo: '¿Cancelar este domicilio?',
      mensaje: 'Se cancelará el pedido a ${order.order.pharmacy.name} para ${order.order.deliveryAddress}. '
          'El paciente y el repartidor lo verán cancelado.',
      confirmar: 'Cancelar domicilio',
      cancelar: 'Conservar pedido',
      peligro: true,
    );
    if (!confirmed) return;
    final error = await widget.controller.cancel(order);
    if (mounted) showAppSnackBar(context, error?.userMessage ?? 'Domicilio cancelado.', error: error != null);
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
              if (c.loading && c.orders.isEmpty) const FgListaCargando(etiqueta: 'Cargando domicilios'),
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
          TitleWithStatus(
            title: o.pharmacy.name,
            style: context.text.titleMedium,
            status: StatusChip(label: _status.$1, tone: _status.$2),
          ),
          const SizedBox(height: AppSpacing.s),
          // §23: mismas líneas con icono que las tarjetas del paciente y del repartidor (consistencia).
          InfoLine(icon: Icons.storefront_outlined, text: 'Recoger en ${o.pharmacy.address}'),
          InfoLine(icon: Icons.place_outlined, text: 'Entregar en ${o.deliveryAddress}'),
          InfoLine(
            icon: Icons.route_outlined,
            text: '${DeliveryFormat.distance(o.routeSummary.distanceMeters)}, '
                'aprox. ${DeliveryFormat.duration(o.routeSummary.durationSeconds)}',
          ),
          if (created != null) InfoLine(icon: Icons.schedule_outlined, text: 'Pedido el ${_when(created)}'),
          InfoLine(
            icon: Icons.delivery_dining_outlined,
            text: order.driverId == null ? 'Sin repartidor asignado' : 'Con repartidor asignado',
          ),
          if (o.notes != null && o.notes!.isNotEmpty) InfoLine(icon: Icons.notes_outlined, text: 'Notas: ${o.notes}'),
          // Los códigos internos sirven para soporte, no para leer la tarjeta: van al final y pequeños
          // (correspondencia con el mundo real).
          SelectableText(
            'Códigos de soporte: paciente ${_short(order.patientId)}'
            '${order.driverId == null ? '' : ', repartidor ${_short(order.driverId!)}'}',
            style: context.text.bodySmall?.copyWith(color: context.status.mutedText),
          ),
          const SizedBox(height: AppSpacing.s),
          OrderItemsList(items: o.items),
          const SizedBox(height: AppSpacing.s),
          Wrap(spacing: AppSpacing.s, runSpacing: AppSpacing.s, children: [
            if (o.deliveryId.isNotEmpty)
              FgButton(label: 'Ver en el mapa', icon: Icons.map_outlined, onPressed: onTrack),
            if (canCancel) FgButton(label: 'Cancelar', variant: FgButtonVariant.secondary, onPressed: onCancel),
          ]),
        ]),
      ),
    );
  }
}
