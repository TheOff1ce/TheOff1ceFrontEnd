import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../components/delivery_widgets.dart';
import '../components/feedback.dart';
import '../hooks/driver_board_controller.dart';
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
      showAppSnackBar(context, error.userMessage);
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
                Semantics(header: true, child: Text('Mis entregas', style: context.text.titleLarge)),
                const SizedBox(height: AppSpacing.s),
                for (final order in active) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.delivery_dining),
                      title: Text(order.pharmacy.name),
                      subtitle: Text(
                        '${c.deliveryStatuses[order.deliveryId]?.label ?? order.status.label} · '
                        'Entregar en ${order.deliveryAddress}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => widget.onOpen(order),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                ],
                const SizedBox(height: AppSpacing.l),
              ],
              Semantics(header: true, child: Text('Disponibles', style: context.text.titleLarge)),
              const SizedBox(height: AppSpacing.s),
              if (c.loading && c.available.isEmpty) const Center(child: DelayedSpinner()),
              if (!c.loading && c.available.isEmpty)
                const EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No hay pedidos por ahora',
                  message: 'Desliza hacia abajo para actualizar.',
                ),
              for (final order in c.available) ...[
                _AvailableCard(order: order, busy: c.takingId == order.id, onTake: () => _take(order)),
                const SizedBox(height: AppSpacing.m),
              ],
            ],
          );
        },
      );
}

class _AvailableCard extends StatelessWidget {
  const _AvailableCard({required this.order, required this.busy, required this.onTake});

  final AvailableOrder order;
  final bool busy;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(order.pharmacy.name, style: context.text.titleMedium),
            Text('Recoger en ${order.pharmacy.address}', style: context.text.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${DeliveryFormat.items(order.itemCount)} · ${DeliveryFormat.distance(order.routeSummary.distanceMeters)} · '
              'aprox. ${DeliveryFormat.duration(order.routeSummary.durationSeconds)}',
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.m),
            FilledButton.icon(
              onPressed: busy ? null : onTake,
              icon: const Icon(Icons.check),
              label: Text(busy ? 'Tomando…' : 'Tomar pedido'),
            ),
          ]),
        ),
      );
}
