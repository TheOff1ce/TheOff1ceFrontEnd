import 'package:flutter/material.dart';

import '../app/theme/farmago_tokens.dart';
import '../components/delivery_widgets.dart';
import '../components/farmago/buttons.dart';
import '../components/farmago/dialogs.dart';
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
    final confirmed = await showFgConfirm(
      context,
      titulo: '¿Cancelar este domicilio?',
      mensaje: 'Se cancelará tu pedido a ${order.pharmacy.name}. Si lo necesitas después, tendrás que pedirlo de nuevo.',
      confirmar: 'Cancelar domicilio',
      cancelar: 'Conservar pedido',
      peligro: true,
    );
    if (!confirmed) return;
    final error = await widget.controller.cancel(order.id);
    if (mounted) showAppSnackBar(context, error?.userMessage ?? 'Domicilio cancelado.', error: error != null);
  }

  /// En curso: ni cancelado ni terminado. Lo demás es historial.
  bool _isActive(PatientOrder order) {
    if (order.status == OrderStatus.cancelled) return false;
    return !(widget.controller.deliveryStatusOf(order)?.isFinished ?? false);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final c = widget.controller;
          final active = [for (final o in c.orders) if (_isActive(o)) o];
          final past = [for (final o in c.orders) if (!_isActive(o)) o];
          Widget card(PatientOrder order) => Padding(
                padding: const EdgeInsets.only(bottom: FgSpace.sp4),
                child: _OrderCard(
                  order: order,
                  deliveryStatus: c.deliveryStatusOf(order),
                  active: _isActive(order),
                  canCancel: c.canCancel(order),
                  onTrack: () => widget.onTrack(order),
                  onCancel: () => _cancel(order),
                ),
              );
          return DeliveryScaffold(
            title: 'Mis domicilios',
            onBack: widget.onBack,
            onRefresh: c.load,
            barraAccion: PrimaryActionBar(label: 'Pedir domicilio', icon: Icons.add_rounded, onPressed: widget.onRequest),
            children: [
              ErrorBanner(error: c.error),
              if (c.loading && c.orders.isEmpty) const Center(child: DelayedSpinner()),
              if (!c.loading && c.orders.isEmpty && c.error == null)
                const EmptyState(
                  icon: Icons.delivery_dining_outlined,
                  title: 'Aún no tienes domicilios',
                  message: 'Pide tus medicamentos con el botón "Pedir domicilio" y sigue al repartidor en el mapa.',
                ),
              if (active.isNotEmpty) ...[
                const SectionHeading('En curso'),
                for (final order in active) card(order),
              ],
              if (past.isNotEmpty) ...[
                if (active.isNotEmpty) const SizedBox(height: FgSpace.sp4),
                const SectionHeading('Anteriores'),
                for (final order in past) card(order),
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
    required this.active,
    required this.canCancel,
    required this.onTrack,
    required this.onCancel,
  });

  final PatientOrder order;
  final DeliveryStatus? deliveryStatus;
  final bool active, canCancel;
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

  String? get _hint {
    if (order.status == OrderStatus.cancelled) return DeliveryStatus.cancelled.patientHint;
    return deliveryStatus?.patientHint;
  }

  @override
  Widget build(BuildContext context) {
    final hint = _hint;
    return FgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // El estado va primero: es lo que la persona viene a mirar.
        StatusChip(label: _status.$1, tone: _status.$2),
        const SizedBox(height: FgSpace.sp3),
        Text(order.pharmacy.name, style: FgText.h3),
        if (hint != null && active) ...[
          const SizedBox(height: FgSpace.sp1),
          Text(hint, style: FgText.body),
        ],
        const SizedBox(height: FgSpace.sp3),
        InfoLine(icon: Icons.place_outlined, text: order.deliveryAddress),
        InfoLine(
          icon: Icons.route_outlined,
          text: '${DeliveryFormat.distance(order.routeSummary.distanceMeters)} · '
              'unos ${DeliveryFormat.duration(order.routeSummary.durationSeconds)} de recorrido',
        ),
        const SizedBox(height: FgSpace.sp2),
        OrderItemsList(items: order.items),
        if (order.status != OrderStatus.cancelled || canCancel) ...[
          const SizedBox(height: FgSpace.sp4),
          Wrap(spacing: FgSpace.sp3, runSpacing: FgSpace.sp3, children: [
            if (order.status != OrderStatus.cancelled)
              FgButton(
                label: active ? 'Seguir pedido' : 'Ver detalle',
                icon: active ? Icons.map_outlined : null,
                variant: active ? FgButtonVariant.primary : FgButtonVariant.secondary,
                onPressed: onTrack,
              ),
            if (canCancel) FgButton(label: 'Cancelar domicilio', variant: FgButtonVariant.ghost, onPressed: onCancel),
          ]),
        ],
      ]),
    );
  }
}
