import 'package:flutter/material.dart';

import '../app/theme/farmago_tokens.dart';
import '../components/delivery_widgets.dart';
import '../components/farmago/buttons.dart';
import '../components/feedback.dart';
import '../hooks/driver_board_controller.dart';
import '../types/delivery.dart';
import '../types/order.dart';
import '../utils/delivery_format.dart';

/// Driver board: published orders to take, and the deliveries already taken.
class DriverBoardPage extends StatefulWidget {
  const DriverBoardPage({super.key, required this.controller, required this.onOpen, required this.onBack});

  final DriverBoardController controller;
  final ValueChanged<DriverOrder> onOpen;
  final VoidCallback onBack;

  @override
  State<DriverBoardPage> createState() => _DriverBoardPageState();
}

class _DriverBoardPageState extends State<DriverBoardPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  Future<void> _take(AvailableOrder order) async {
    final (taken, error) = await widget.controller.take(order.id);
    if (!mounted) return;
    if (error != null) {
      showAppSnackBar(context, error.userMessage, error: true);
    } else if (taken != null) {
      widget.onOpen(taken);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final c = widget.controller;
          final active = c.active;
          return DeliveryScaffold(
            title: 'Domicilios',
            onBack: widget.onBack,
            onRefresh: c.load,
            children: [
              ErrorBanner(error: c.error),
              if (active.isNotEmpty) ...[
                const SectionHeading('Tus entregas en curso'),
                for (final order in active)
                  Padding(
                    padding: const EdgeInsets.only(bottom: FgSpace.sp4),
                    child: _ActiveCard(
                      order: order,
                      status: c.deliveryStatuses[order.deliveryId],
                      onOpen: () => widget.onOpen(order),
                    ),
                  ),
                const SizedBox(height: FgSpace.sp4),
              ],
              const SectionHeading('Pedidos disponibles'),
              if (c.loading && c.available.isEmpty) const Center(child: DelayedSpinner()),
              if (!c.loading && c.available.isEmpty) ...[
                const EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No hay pedidos por ahora',
                  message: 'Cuando un paciente pida un domicilio aparecerá aquí.',
                ),
                Center(
                  child: FgButton(
                    label: 'Actualizar',
                    icon: Icons.refresh_rounded,
                    variant: FgButtonVariant.secondary,
                    onPressed: c.load,
                  ),
                ),
              ],
              for (final order in c.available)
                Padding(
                  padding: const EdgeInsets.only(bottom: FgSpace.sp4),
                  child: _AvailableCard(
                    order: order,
                    busy: c.takingId == order.id,
                    // Mientras se toma uno, los demás esperan: evita tomar dos por error.
                    enabled: c.takingId == null,
                    onTake: () => _take(order),
                  ),
                ),
            ],
          );
        },
      );
}

/// Entrega que el repartidor ya tomó: lo primero de la pantalla, con qué hacer ahora.
class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.order, required this.status, required this.onOpen});

  final DriverOrder order;
  final DeliveryStatus? status;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final hint = status?.driverHint ?? '';
    return FgCard(
      destacada: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        StatusChip(label: status?.label ?? order.status.label),
        const SizedBox(height: FgSpace.sp3),
        Text(order.pharmacy.name, style: FgText.h3),
        if (hint.isNotEmpty) ...[
          const SizedBox(height: FgSpace.sp1),
          Text(hint, style: FgText.body),
        ],
        const SizedBox(height: FgSpace.sp3),
        InfoLine(icon: Icons.place_outlined, text: 'Entregar en ${order.deliveryAddress}'),
        const SizedBox(height: FgSpace.sp3),
        FgButton(label: 'Continuar entrega', icon: Icons.arrow_forward_rounded, onPressed: onOpen),
      ]),
    );
  }
}

class _AvailableCard extends StatelessWidget {
  const _AvailableCard({required this.order, required this.busy, required this.enabled, required this.onTake});

  final AvailableOrder order;
  final bool busy, enabled;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) => FgCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(order.pharmacy.name, style: FgText.h3),
          const SizedBox(height: FgSpace.sp2),
          InfoLine(icon: Icons.storefront_outlined, text: 'Recoger en ${order.pharmacy.address}'),
          InfoLine(
            icon: Icons.route_outlined,
            text: '${DeliveryFormat.distance(order.routeSummary.distanceMeters)} · '
                'unos ${DeliveryFormat.duration(order.routeSummary.durationSeconds)}',
          ),
          InfoLine(icon: Icons.medication_outlined, text: DeliveryFormat.items(order.itemCount)),
          const SizedBox(height: FgSpace.sp3),
          FgButton(
            label: 'Tomar pedido',
            icon: Icons.check_rounded,
            loading: busy,
            loadingLabel: 'Tomando…',
            onPressed: enabled || busy ? onTake : null,
          ),
        ]),
      );
}
