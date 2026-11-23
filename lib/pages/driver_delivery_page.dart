import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/theme/farmago_tokens.dart';
import '../components/abrir_navegacion.dart';
import '../components/delivery_code.dart';
import '../components/delivery_map.dart';
import '../components/delivery_proof.dart';
import '../components/farmago/buttons.dart';
import '../components/farmago/dialogs.dart';
import '../components/farmago/feedback.dart';
import '../components/delivery_widgets.dart';
import '../hooks/driver_delivery_controller.dart';
import '../services/image_service.dart';
import '../types/delivery.dart';
import '../types/order.dart';
import '../utils/delivery_format.dart';
import '../components/farmago/card.dart';
import 'register_delivery_proof_page.dart';

/// Driver's active delivery: what to pick up, where to take it, status buttons and
/// automatic location sharing while on the way.
class DriverDeliveryPage extends StatefulWidget {
  const DriverDeliveryPage({
    super.key,
    required this.order,
    required this.createController,
    required this.onBack,
    this.takeProofPhoto,
    this.proofImages,
  });

  final DriverOrder order;
  final DriverDeliveryController Function(String deliveryId) createController;
  final VoidCallback onBack;

  /// Cámara para la foto de la prueba de entrega (inyectable en pruebas).
  final Future<XFile?> Function(BuildContext context)? takeProofPhoto;
  final ImageService? proofImages;

  @override
  State<DriverDeliveryPage> createState() => _DriverDeliveryPageState();
}

class _DriverDeliveryPageState extends State<DriverDeliveryPage> {
  late final DriverDeliveryController _controller = widget.createController(widget.order.deliveryId);

  static const _actionLabels = {
    DeliveryStatus.pickedUp: ('Ya recogí el pedido', Icons.inventory_2_outlined),
    DeliveryStatus.inTransit: ('Empezar viaje', Icons.navigation_outlined),
  };

  DeliveryStatus? _estadoVisto;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_vigilarEntrega);
    _controller.start();
  }

  /// El paciente confirma con el código desde su celular: el repartidor se entera aquí.
  void _vigilarEntrega() {
    final estado = _controller.delivery?.status;
    if (estado == null) return;
    final antes = _estadoVisto;
    _estadoVisto = estado;
    if (!mounted || antes == null || antes == estado || estado != DeliveryStatus.delivered) return;
    // Con prueba de entrega la cerró el propio repartidor: ese aviso lo da _registrarEntrega.
    if (_controller.delivery?.proof != null || _controller.registeringProof) return;
    showFgToast(context, 'Entrega confirmada', detalle: 'El paciente confirmó con tu código.');
  }

  /// CU-14: foto, firma y ubicación en la puerta.
  Future<void> _registrarEntrega() async {
    final registrada = await showRegisterDeliveryProof(
      context,
      address: widget.order.deliveryAddress,
      onSubmit: _controller.registerProof,
      takePhoto: widget.takeProofPhoto,
      images: widget.proofImages,
    );
    if (!mounted || !registrada) return;
    showFgToast(context, 'Entrega registrada', detalle: 'Guardamos la foto, la firma y tu ubicación.');
  }

  @override
  void dispose() {
    _controller.removeListener(_vigilarEntrega);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _advance(DeliveryStatus status) async {
    final error = await _controller.advance(status);
    if (!mounted) return;
    if (error != null) return showAppSnackBar(context, error.userMessage, error: true);
    switch (status) {
      case DeliveryStatus.pickedUp:
        showFgToast(context, 'Pedido recogido', detalle: 'Cuando salgas hacia el paciente, toca «Empezar viaje».');
      case DeliveryStatus.inTransit:
        showFgToast(context, 'Viaje iniciado', detalle: 'El paciente ya puede seguirte en el mapa.');
      case DeliveryStatus.failed:
        showFgToast(context, 'Marcamos el pedido como no entregado',
            detalle: 'Dejamos de compartir tu ubicación.', kind: FgToastKind.info);
      default:
        break;
    }
  }

  Future<void> _fail() async {
    final confirmed = await showFgConfirm(
      context,
      titulo: '¿No pudiste entregar el pedido?',
      mensaje: 'El domicilio quedará como no entregado y dejarás de compartir tu ubicación. Esto no se puede deshacer.',
      confirmar: 'Marcar como no entregado',
      cancelar: 'Seguir con la entrega',
      peligro: true,
    );
    if (confirmed) await _advance(DeliveryStatus.failed);
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

  /// Paso del repartidor: 1 recoger, 2 salir, 3 entregar con el código.
  static int? _step(DeliveryStatus status) => switch (status) {
        DeliveryStatus.assigned => 1,
        DeliveryStatus.pickedUp => 2,
        DeliveryStatus.inTransit || DeliveryStatus.arriving => 3,
        _ => null,
      };

  List<Widget> _content(BuildContext context, Delivery d) {
    final next = _controller.nextStep;
    final action = next == null ? null : _actionLabels[next];
    final step = _step(d.status);
    return [
      TitleWithStatus(
        title: d.status.label,
        style: FgText.h2,
        status: _controller.sharing ? const StatusChip(label: 'Compartiendo ubicación', tone: StatusTone.success) : null,
      ),
      const SizedBox(height: FgSpace.sp3),
      ErrorBanner(error: _controller.locationError),
      if (_controller.sinSenal) ...[
        FgBanner(
          kind: FgBannerKind.aviso,
          title: 'Sin señal',
          message: _controller.pendientesSinEnviar > 0
              ? 'Guardamos tu ubicación y la enviamos apenas vuelva la conexión. Sigue con la entrega.'
              : 'Reintentando enviar tu ubicación…',
        ),
        const SizedBox(height: FgSpace.sp3),
      ],
      // Qué hacer ahora, antes que el mapa: es lo que el repartidor necesita con el pedido en la mano.
      if (d.status == DeliveryStatus.delivered) ...[
        FgBanner(
          kind: FgBannerKind.exito,
          message: d.proof != null
              ? 'Registraste la entrega con foto, firma y ubicación.'
              : 'El paciente confirmó la entrega con tu código.',
        ),
        if (d.proof != null) ...[
          const SizedBox(height: FgSpace.sp4),
          DeliveryProofSection(proof: d.proof!, loadImage: _controller.proofImage),
        ],
      ] else if (d.status.driverHint.isNotEmpty)
        FgCard(
          destacada: step != null,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (step != null) Text('Paso $step de 3', style: FgText.caption),
            if (step != null) const SizedBox(height: FgSpace.sp1),
            Text(d.status.driverHint, style: FgText.bodyLg),
            if (_controller.canRegisterProof) ...[
              const SizedBox(height: FgSpace.sp4),
              FgButton(
                label: 'Registrar entrega',
                icon: Icons.task_alt,
                size: FgButtonSize.lg,
                expand: true,
                onPressed: _controller.updating || _controller.registeringProof ? null : _registrarEntrega,
              ),
            ],
            if (d.deliveryCode != null && d.awaitsCode) ...[
              const SizedBox(height: FgSpace.sp4),
              DriverDeliveryCodeCard(code: d.deliveryCode!, awaitingPatient: true),
            ],
            if (action != null) ...[
              const SizedBox(height: FgSpace.sp4),
              FgButton(
                label: action.$1,
                icon: action.$2,
                size: FgButtonSize.lg,
                expand: true,
                loading: _controller.updating,
                loadingLabel: 'Guardando…',
                onPressed: () => _advance(next!),
              ),
            ],
          ]),
        ),
      const SizedBox(height: FgSpace.sp5),
      DeliveryMap(delivery: d, height: 240),
      if (NavegacionExterna.destinoActual(d) != null) ...[
        const SizedBox(height: FgSpace.sp3),
        AbrirNavegacion(delivery: d),
      ],
      if (_controller.lastSentAt != null) ...[
        const SizedBox(height: FgSpace.sp2),
        Text('Última ubicación enviada: ${DeliveryFormat.clock(_controller.lastSentAt!)}', style: FgText.caption),
      ],
      const SizedBox(height: FgSpace.sp5),
      FgCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionHeading('Recoger'),
          InfoLine(icon: Icons.storefront_outlined, text: '${widget.order.pharmacy.name} — ${widget.order.pharmacy.address}'),
          const SizedBox(height: FgSpace.sp1),
          OrderItemsList(items: widget.order.items),
          const SizedBox(height: FgSpace.sp4),
          const SectionHeading('Entregar'),
          InfoLine(icon: Icons.place_outlined, text: widget.order.deliveryAddress),
          if (widget.order.notes != null) InfoLine(icon: Icons.sticky_note_2_outlined, text: widget.order.notes!),
          InfoLine(
            icon: Icons.route_outlined,
            text: '${DeliveryFormat.distance(d.route.distanceMeters)} · unos ${DeliveryFormat.duration(d.route.durationSeconds)}',
          ),
        ]),
      ),
      if (_controller.canFail) ...[
        const SizedBox(height: FgSpace.sp5),
        // Salida de emergencia, lejos del botón principal para no tocarla por error.
        Center(
          child: FgButton(
            label: 'No se pudo entregar',
            variant: FgButtonVariant.ghost,
            onPressed: _controller.updating || _controller.registeringProof ? null : _fail,
          ),
        ),
      ],
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
          Center(child: FgButton(label: 'Ir a mis domicilios', onPressed: onBack)),
        ],
      );
}
