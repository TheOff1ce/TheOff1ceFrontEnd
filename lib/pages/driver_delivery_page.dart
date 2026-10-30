import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../components/delivery_map.dart';
import '../components/delivery_widgets.dart';
import '../components/feedback.dart';
import '../hooks/driver_delivery_controller.dart';
import '../types/delivery.dart';
import '../types/order.dart';
import '../utils/delivery_format.dart';

/// Driver's active delivery: what to pick up, where to take it, status buttons and
/// automatic location sharing while on the way.
class DriverDeliveryPage extends StatefulWidget {
  const DriverDeliveryPage({super.key, required this.order, required this.createController, required this.onBack});

  final DriverOrder order;
  final DriverDeliveryController Function(String deliveryId) createController;
  final VoidCallback onBack;

  @override
  State<DriverDeliveryPage> createState() => _DriverDeliveryPageState();
}

class _DriverDeliveryPageState extends State<DriverDeliveryPage> {
  late final DriverDeliveryController _controller = widget.createController(widget.order.deliveryId);

  static const _actionLabels = {
    DeliveryStatus.pickedUp: ('Ya recogí el pedido', Icons.inventory_2_outlined),
    DeliveryStatus.inTransit: ('Empezar viaje', Icons.navigation_outlined),
    DeliveryStatus.delivered: ('Marcar como entregado', Icons.check_circle_outline),
  };

  @override
  void initState() {
    super.initState();
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _advance(DeliveryStatus status) async {
    final error = await _controller.advance(status);
    if (mounted && error != null) showAppSnackBar(context, error.userMessage);
  }

  Future<void> _fail() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿No se pudo entregar?'),
        content: const Text('El domicilio quedará como no entregado y dejarás de compartir tu ubicación.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmed == true) await _advance(DeliveryStatus.failed);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final d = _controller.delivery;
          return DeliveryScaffold(
            title: 'Entrega',
            onBack: widget.onBack,
            onRefresh: _controller.start,
            children: [
              ErrorBanner(error: _controller.error),
              if (_controller.loading && d == null) const Center(child: DelayedSpinner()),
              if (d != null) ..._content(context, d),
            ],
          );
        },
      );

  List<Widget> _content(BuildContext context, Delivery d) {
    final next = _controller.nextStep;
    final action = next == null ? null : _actionLabels[next];
    return [
      Row(children: [
        Expanded(child: Text(d.status.label, style: context.text.headlineSmall)),
        if (_controller.sharing) const StatusChip(label: 'Compartiendo ubicación', tone: StatusTone.success),
      ]),
      const SizedBox(height: AppSpacing.s),
      ErrorBanner(error: _controller.locationError),
      DeliveryMap(delivery: d, height: 240),
      const SizedBox(height: AppSpacing.l),
      if (action != null)
        FilledButton.icon(
          onPressed: _controller.updating ? null : () => _advance(next!),
          icon: Icon(action.$2),
          label: Text(action.$1),
        ),
      if (_controller.canFail)
        TextButton(onPressed: _controller.updating ? null : _fail, child: const Text('No se pudo entregar')),
      if (_controller.lastSentAt != null)
        Text('Última ubicación enviada: ${DeliveryFormat.clock(_controller.lastSentAt!)}', style: context.text.bodySmall),
      const SizedBox(height: AppSpacing.l),
      Semantics(header: true, child: Text('Recoger', style: context.text.titleMedium)),
      Text('${widget.order.pharmacy.name} — ${widget.order.pharmacy.address}', style: context.text.bodyMedium),
      const SizedBox(height: AppSpacing.s),
      OrderItemsList(items: widget.order.items),
      const SizedBox(height: AppSpacing.m),
      Semantics(header: true, child: Text('Entregar', style: context.text.titleMedium)),
      Text(widget.order.deliveryAddress, style: context.text.bodyMedium),
      if (widget.order.notes != null) Text('Indicaciones: ${widget.order.notes}', style: context.text.bodySmall),
      const SizedBox(height: AppSpacing.s),
      Text(
        'Ruta: ${DeliveryFormat.distance(d.route.distanceMeters)} · ${DeliveryFormat.duration(d.route.durationSeconds)}',
        style: context.text.bodySmall,
      ),
    ];
  }
}

/// Shown when the app was reloaded on a delivery that is not in memory any more.
class MissingDeliveryPage extends StatelessWidget {
  const MissingDeliveryPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => DeliveryScaffold(
        title: 'Entrega',
        onBack: onBack,
        children: [
          const EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Abre la entrega desde tus domicilios',
            message: 'No encontramos este pedido entre los que tomaste. Vuelve a la lista para abrirlo.',
          ),
          FilledButton(onPressed: onBack, child: const Text('Ir a mis domicilios')),
        ],
      );
}
