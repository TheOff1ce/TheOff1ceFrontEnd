import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../app/theme/farmago_tokens.dart';
import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../types/delivery.dart';
import '../utils/delivery_format.dart';
import '../utils/pendiente_format.dart';
import 'delivery_widgets.dart';
import 'farmago/buttons.dart';
import 'farmago/card.dart';
import 'farmago/feedback.dart';

/// "Prueba de entrega" de un envío cerrado por el repartidor (CU-14): quién recibió, cuándo, a qué
/// distancia de la dirección, y la foto y la firma, que se cargan aparte (cada una con su carga y
/// su reintento, sin tumbar el resto de la pantalla).
class DeliveryProofSection extends StatelessWidget {
  const DeliveryProofSection({super.key, required this.proof, required this.loadImage});

  final DeliveryProof proof;
  final Future<Uint8List> Function(DeliveryProofImage image) loadImage;

  /// Desde este ancho la foto y la firma van lado a lado.
  static const _anchoDosColumnas = 480.0;

  @override
  Widget build(BuildContext context) {
    final nombre = proof.receiverName;
    return FgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeading('Prueba de entrega'),
          InfoLine(
            icon: Icons.person_outline,
            text: nombre == null ? 'No se anotó el nombre de quien recibió' : 'Recibió: $nombre',
          ),
          InfoLine(icon: Icons.schedule, text: 'Registrada el ${PendienteFormat.fechaHora(proof.recordedAt)}'),
          InfoLine(
            icon: Icons.place_outlined,
            text: 'A ${DeliveryFormat.distance(proof.distanceToDestinationMeters)} de la dirección de entrega',
          ),
          const SizedBox(height: FgSpace.sp4),
          LayoutBuilder(builder: (context, constraints) {
            final foto = _ProofImage(
              key: const ValueKey('proof-photo'),
              titulo: 'Foto de la entrega',
              descripcion: 'Foto del pedido entregado',
              imagen: DeliveryProofImage.photo,
              load: loadImage,
            );
            final firma = _ProofImage(
              key: const ValueKey('proof-signature'),
              titulo: 'Firma de quien recibió',
              descripcion: nombre == null ? 'Firma de quien recibió' : 'Firma de $nombre',
              imagen: DeliveryProofImage.signature,
              load: loadImage,
              fondoFirma: true,
            );
            if (constraints.maxWidth < _anchoDosColumnas) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [foto, const SizedBox(height: FgSpace.sp4), firma],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: foto),
                const SizedBox(width: FgSpace.sp4),
                Expanded(child: firma),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _ProofImage extends StatefulWidget {
  const _ProofImage({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.imagen,
    required this.load,
    this.fondoFirma = false,
  });

  final String titulo;

  /// Texto alternativo de la imagen para lectores de pantalla.
  final String descripcion;
  final DeliveryProofImage imagen;
  final Future<Uint8List> Function(DeliveryProofImage image) load;

  /// La firma se ve sobre su papel blanco también en modo oscuro.
  final bool fondoFirma;

  @override
  State<_ProofImage> createState() => _ProofImageState();
}

class _ProofImageState extends State<_ProofImage> {
  Uint8List? _bytes;
  AppError? _error;
  bool _cargando = true;
  int _intento = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _reintentar() {
    setState(() {
      _cargando = true;
      _error = null;
    });
    _cargar();
  }

  Future<void> _cargar() async {
    final intento = ++_intento;
    try {
      final bytes = await widget.load(widget.imagen);
      if (!mounted || intento != _intento) return;
      setState(() {
        _bytes = bytes;
        _cargando = false;
      });
    } catch (e) {
      final error = ErrorMapper.fromException(e);
      ErrorReporter.report(error);
      if (!mounted || intento != _intento) return;
      setState(() {
        _error = error;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const alto = FgSize.fotoPruebaAlto;
    final fondo = widget.fondoFirma ? FgColors.firmaFondo : FgColors.fondoHundido;
    final error = _error;
    final bytes = _bytes;
    final Widget contenido;
    if (_cargando) {
      contenido = Semantics(
        label: 'Cargando ${widget.titulo.toLowerCase()}',
        child: const FgSkeleton(alto: FgSize.fotoPruebaAlto, radio: FgRadius.md),
      );
    } else if (error != null || bytes == null) {
      contenido = _Fallo(
        mensaje: error?.userMessage ?? 'No pudimos mostrar la imagen. Vuelve a intentarlo.',
        onRetry: _reintentar,
      );
    } else {
      final cacheHeight = (alto * MediaQuery.devicePixelRatioOf(context)).round();
      contenido = ClipRRect(
        borderRadius: BorderRadius.circular(FgRadius.md),
        child: ColoredBox(
          color: fondo,
          child: SizedBox(
            height: alto,
            width: double.infinity,
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              cacheHeight: cacheHeight,
              semanticLabel: widget.descripcion,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) => _Fallo(
                mensaje: 'No pudimos mostrar la imagen. Vuelve a intentarlo.',
                onRetry: _reintentar,
              ),
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.titulo, style: FgText.captionFuerte),
        const SizedBox(height: FgSpace.sp2),
        contenido,
      ],
    );
  }
}

/// Error de una sola imagen: el resto de la prueba sigue visible.
class _Fallo extends StatelessWidget {
  const _Fallo({required this.mensaje, required this.onRetry});

  final String mensaje;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: FgSize.fotoPruebaAlto),
        padding: const EdgeInsets.all(FgSpace.sp4),
        decoration: BoxDecoration(
          color: FgColors.fondoHundido,
          borderRadius: BorderRadius.circular(FgRadius.md),
        ),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FgGlifo(color: FgColors.peligro, simbolo: Icons.close),
              const SizedBox(height: FgSpace.sp2),
              Text(mensaje, style: FgText.caption, textAlign: TextAlign.center),
              const SizedBox(height: FgSpace.sp2),
              FgButton(label: 'Reintentar', icon: Icons.refresh, variant: FgButtonVariant.secondary, onPressed: onRetry),
            ],
          ),
        ),
      );
}
