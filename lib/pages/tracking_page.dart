import 'package:flutter/material.dart';

import '../app/theme/farmago_tokens.dart';
import '../components/delivery_map.dart';
import '../components/farmago/feedback.dart';
import '../components/farmago/layout.dart';
import '../components/farmago/trail.dart';
import '../components/feedback.dart';
import '../hooks/tracking_controller.dart';
import '../types/delivery.dart';
import '../utils/delivery_format.dart';

/// Seguimiento en vivo del domicilio del paciente: mapa, llegada estimada, distancia y el
/// trayecto de estados. Un solo `h1` con el estado actual; el título de la pantalla va en el
/// encabezado.
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
  Widget build(BuildContext context) => FarmaGoThemed(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final delivery = _controller.delivery;
            final error = _controller.error;
            return FgScreen(
              titulo: 'Seguimiento',
              onBack: widget.onBack,
              onRefresh: _controller.start,
              children: [
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: FgSpace.sp5),
                    child: FgBanner(
                      kind: FgBannerKind.error,
                      message: error.userMessage,
                      referencia: error.showsReference ? error.referenceId : null,
                    ),
                  ),
                if (_controller.loading && delivery == null) const Center(child: DelayedSpinner()),
                if (delivery != null) ..._contenido(delivery),
              ],
            );
          },
        ),
      );

  List<Widget> _contenido(Delivery d) {
    final activo = !d.status.isFinished;
    final terminal = d.status == DeliveryStatus.cancelled || d.status == DeliveryStatus.failed;
    return [
      if (activo) _EnVivo(connected: _controller.connected),
      if (activo) const SizedBox(height: FgSpace.sp3),
      DeliveryMap(delivery: d),
      const SizedBox(height: FgSpace.sp5),
      Semantics(liveRegion: true, child: Text(d.status.label, style: FgText.h2)),
      const SizedBox(height: FgSpace.sp5),
      if (activo) ...[
        _Dato(
          etiqueta: 'Llegada estimada',
          valor: DeliveryFormat.eta(d.eta),
          estilo: FgText.num(FgText.h2),
        ),
        if (d.distanceToDestinationMeters != null)
          _Dato(
            etiqueta: 'Distancia',
            valor: DeliveryFormat.distance(d.distanceToDestinationMeters!),
            estilo: FgText.num(FgText.h2),
          ),
        if (!d.status.isTracking)
          Padding(
            padding: const EdgeInsets.only(bottom: FgSpace.sp4),
            child: Text(
              d.driverAssigned
                  ? 'Verás al repartidor en el mapa cuando recoja tu pedido.'
                  : 'Estamos esperando que un repartidor tome tu pedido.',
              style: FgText.bodyLg,
            ),
          ),
      ] else
        const Padding(
          padding: EdgeInsets.only(bottom: FgSpace.sp4),
          child: Text('La ubicación del repartidor ya no se comparte.', style: FgText.body),
        ),
      const SizedBox(height: FgSpace.sp4),
      if (terminal)
        FgBanner(
          kind: d.status == DeliveryStatus.failed ? FgBannerKind.error : FgBannerKind.aviso,
          message: d.status.label,
        )
      else
        FgTrail(
          etiquetas: [for (final paso in DeliveryStatus.steps) paso.label],
          actual: d.status == DeliveryStatus.delivered ? DeliveryStatus.steps.length : DeliveryStatus.steps.indexOf(d.status),
        ),
      const SizedBox(height: FgSpace.sp7),
      _Dato(etiqueta: 'Farmacia', valor: d.origin.address),
      _Dato(etiqueta: 'Entrega', valor: d.destination.address),
    ];
  }
}

/// Indicador de conexión en vivo. El texto acompaña al icono: no depende del color.
class _EnVivo extends StatelessWidget {
  const _EnVivo({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(
          connected ? Icons.wifi_tethering : Icons.wifi_tethering_off,
          size: FgSize.iconoSm,
          color: connected ? FgColors.azul800 : FgColors.inkSoft,
        ),
        const SizedBox(width: FgSpace.sp2),
        Text(connected ? 'En vivo' : 'Reconectando…', style: FgText.label),
      ]);
}

/// Dato con etiqueta pequeña y valor debajo, legible de un vistazo.
class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor, this.estilo = FgText.bodyLg});

  final String etiqueta, valor;
  final TextStyle estilo;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: FgSpace.sp4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(etiqueta, style: FgText.caption),
          const SizedBox(height: FgSpace.sp1),
          Text(valor, style: estilo),
        ]),
      );
}
