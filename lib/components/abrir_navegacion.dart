import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/theme/farmago_tokens.dart';
import '../types/delivery.dart';
import 'farmago/buttons.dart';
import 'farmago/feedback.dart';

/// Abre el destino en la app de navegación que el repartidor ya usa.
abstract final class NavegacionExterna {
  static Uri googleMaps(GeoPoint p) => Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '${p.lat},${p.lng}',
        'travelmode': 'driving',
      });

  static Uri waze(GeoPoint p) => Uri.https('waze.com', '/ul', {'ll': '${p.lat},${p.lng}', 'navigate': 'yes'});

  /// A dónde va ahora: la farmacia hasta recoger, después la casa del paciente.
  static DeliveryPlace? destinoActual(Delivery d) => switch (d.status) {
        DeliveryStatus.assigned => d.origin,
        DeliveryStatus.pickedUp || DeliveryStatus.inTransit || DeliveryStatus.arriving => d.destination,
        _ => null,
      };
}

typedef AbrirEnlace = Future<bool> Function(Uri uri);

Future<bool> _abrirFuera(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

/// «Abrir en Google Maps / Waze» para el tramo actual de la entrega. No se muestra si ya terminó.
class AbrirNavegacion extends StatelessWidget {
  const AbrirNavegacion({super.key, required this.delivery, this.abrir = _abrirFuera});

  final Delivery delivery;

  /// Inyectable en pruebas.
  final AbrirEnlace abrir;

  @override
  Widget build(BuildContext context) {
    final destino = NavegacionExterna.destinoActual(delivery);
    if (destino == null) return const SizedBox.shrink();
    final haciaFarmacia = delivery.status == DeliveryStatus.assigned;

    Future<void> ir(Uri uri) async {
      var ok = false;
      try {
        ok = await abrir(uri);
      } catch (_) {
        ok = false;
      }
      if (!ok && context.mounted) {
        showAppSnackBar(context, 'No pudimos abrir la app de mapas. Usa la dirección de abajo.', error: true);
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(haciaFarmacia ? 'Cómo llegar a la farmacia' : 'Cómo llegar donde el paciente', style: FgText.label),
      const SizedBox(height: FgSpace.sp2),
      Wrap(spacing: FgSpace.sp3, runSpacing: FgSpace.sp2, children: [
        FgButton(
          label: 'Abrir en Google Maps',
          icon: Icons.map_outlined,
          variant: FgButtonVariant.secondary,
          onPressed: () => ir(NavegacionExterna.googleMaps(destino.point)),
        ),
        FgButton(
          label: 'Abrir en Waze',
          icon: Icons.navigation_outlined,
          variant: FgButtonVariant.secondary,
          onPressed: () => ir(NavegacionExterna.waze(destino.point)),
        ),
      ]),
    ]);
  }
}
