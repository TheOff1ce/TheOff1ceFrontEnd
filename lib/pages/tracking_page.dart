import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../components/delivery_map.dart';
import '../components/delivery_widgets.dart';
import '../components/feedback.dart';
import '../hooks/tracking_controller.dart';
import '../types/delivery.dart';
import '../utils/delivery_format.dart';

/// Live tracking for the patient: map, ETA, distance and status, updated in real time.
class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key, required this.createController, required this.onBack});

  final TrackingController Function() createController;
  final VoidCallback onBack;

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  late final TrackingController _controller = widget.createController();

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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final delivery = _controller.delivery;
          return DeliveryScaffold(
            title: 'Seguimiento',
            onBack: widget.onBack,
            onRefresh: _controller.start,
            children: [
              ErrorBanner(error: _controller.error),
              if (_controller.loading && delivery == null) const Center(child: DelayedSpinner()),
              if (delivery != null) ..._details(context, delivery),
            ],
          );
        },
      );

  List<Widget> _details(BuildContext context, Delivery d) => [
        if (!d.status.isFinished)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s),
            child: Row(children: [
              Icon(_controller.connected ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                  size: 18, color: _controller.connected ? context.status.onSuccessContainer : context.status.mutedText),
              const SizedBox(width: AppSpacing.xs),
              Text(_controller.connected ? 'En vivo' : 'Reconectando…', style: context.text.labelMedium),
            ]),
          ),
        DeliveryMap(delivery: d),
        const SizedBox(height: AppSpacing.l),
        Semantics(
          liveRegion: true,
          child: Text(d.status.label, style: context.text.headlineSmall),
        ),
        const SizedBox(height: AppSpacing.s),
        if (!d.status.isFinished) ...[
          _fact(context, Icons.schedule, 'Llegada estimada', DeliveryFormat.eta(d.eta)),
          if (d.distanceToDestinationMeters != null)
            _fact(context, Icons.straighten, 'Distancia', DeliveryFormat.distance(d.distanceToDestinationMeters!)),
          if (!d.status.isTracking)
            Text(
              d.driverAssigned
                  ? 'Verás al repartidor en el mapa cuando recoja tu pedido.'
                  : 'Estamos esperando que un repartidor tome tu pedido.',
              style: context.text.bodyMedium,
            ),
        ],
        if (d.status.isFinished)
          Text('La ubicación del repartidor ya no se comparte.', style: context.text.bodyMedium),
        const SizedBox(height: AppSpacing.l),
        DeliveryProgress(status: d.status),
        const SizedBox(height: AppSpacing.l),
        _fact(context, Icons.local_pharmacy_outlined, 'Farmacia', d.origin.address),
        _fact(context, Icons.home_outlined, 'Entrega', d.destination.address),
      ];

  Widget _fact(BuildContext context, IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: context.colors.primary),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: value),
            ]), style: context.text.bodyMedium),
          ),
        ]),
      );
}
