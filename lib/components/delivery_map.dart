import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;

import '../app/theme/app_theme.dart';
import '../services/maps_loader.dart';
import '../types/delivery.dart';
import '../utils/constants.dart';
import '../utils/polyline.dart';

/// Map of a delivery: pharmacy, destination, route and (when shared) the driver.
///
/// With `--dart-define=MAPS_API_KEY=<client key>` it uses Google Maps; without a key it draws
/// a simplified schematic so the flow can be tested before the key exists.
class DeliveryMap extends StatelessWidget {
  const DeliveryMap({super.key, required this.delivery, this.height = 280});

  final Delivery delivery;
  final double height;

  @override
  Widget build(BuildContext context) {
    final map = AppConfig.hasMapsKey
        ? FutureBuilder<bool>(
            future: ensureGoogleMapsLoaded(AppConfig.mapsApiKey),
            builder: (context, snapshot) => switch (snapshot.data) {
              true => _GoogleDeliveryMap(delivery: delivery),
              false => SimplifiedRouteMap(delivery: delivery),
              null => const Center(child: CircularProgressIndicator(semanticsLabel: 'Cargando mapa')),
            },
          )
        : SimplifiedRouteMap(delivery: delivery);
    return Semantics(
      label: _description(delivery),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.l),
        child: SizedBox(height: height, width: double.infinity, child: map),
      ),
    );
  }

  static String _description(Delivery d) {
    final driver = d.driverLocation == null ? 'Ubicación del repartidor no disponible.' : 'Se muestra la ubicación del repartidor.';
    return 'Mapa del domicilio desde ${d.origin.address} hasta ${d.destination.address}. $driver';
  }
}

class _GoogleDeliveryMap extends StatefulWidget {
  const _GoogleDeliveryMap({required this.delivery});

  final Delivery delivery;

  @override
  State<_GoogleDeliveryMap> createState() => _GoogleDeliveryMapState();
}

class _GoogleDeliveryMapState extends State<_GoogleDeliveryMap> {
  gm.GoogleMapController? _controller;

  static gm.LatLng _ll(GeoPoint p) => gm.LatLng(p.lat, p.lng);

  @override
  void didUpdateWidget(covariant _GoogleDeliveryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final driver = widget.delivery.driverLocation?.point;
    if (driver != null && driver != oldWidget.delivery.driverLocation?.point) {
      _controller?.animateCamera(gm.CameraUpdate.newLatLng(_ll(driver)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.delivery;
    final route = decodePolyline(d.route.encodedPolyline).map(_ll).toList();
    final driver = d.driverLocation;
    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(target: _ll(d.destination.point), zoom: 14),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      polylines: {
        if (route.length >= 2)
          gm.Polyline(polylineId: const gm.PolylineId('route'), points: route, width: 5, color: context.colors.primary),
      },
      markers: {
        gm.Marker(
          markerId: const gm.MarkerId('origin'),
          position: _ll(d.origin.point),
          infoWindow: gm.InfoWindow(title: 'Farmacia', snippet: d.origin.address),
          icon: gm.BitmapDescriptor.defaultMarkerWithHue(gm.BitmapDescriptor.hueGreen),
        ),
        gm.Marker(
          markerId: const gm.MarkerId('destination'),
          position: _ll(d.destination.point),
          infoWindow: gm.InfoWindow(title: 'Entrega', snippet: d.destination.address),
        ),
        if (driver != null)
          gm.Marker(
            markerId: const gm.MarkerId('driver'),
            position: _ll(driver.point),
            rotation: driver.heading ?? 0,
            infoWindow: const gm.InfoWindow(title: 'Repartidor'),
            icon: gm.BitmapDescriptor.defaultMarkerWithHue(gm.BitmapDescriptor.hueAzure),
          ),
      },
      onMapCreated: (controller) {
        _controller = controller;
        Future<void>.delayed(const Duration(milliseconds: 300), () => _fit(controller));
      },
    );
  }

  void _fit(gm.GoogleMapController controller) {
    final d = widget.delivery;
    final points = [d.origin.point, d.destination.point, if (d.driverLocation != null) d.driverLocation!.point];
    final south = points.map((p) => p.lat).reduce(math.min);
    final north = points.map((p) => p.lat).reduce(math.max);
    final west = points.map((p) => p.lng).reduce(math.min);
    final east = points.map((p) => p.lng).reduce(math.max);
    if (south == north && west == east) return;
    controller.animateCamera(gm.CameraUpdate.newLatLngBounds(
      gm.LatLngBounds(southwest: gm.LatLng(south, west), northeast: gm.LatLng(north, east)),
      48,
    ));
  }
}

/// Schematic map (no tiles, no key): route, pharmacy, destination and driver on a grid.
class SimplifiedRouteMap extends StatelessWidget {
  const SimplifiedRouteMap({super.key, required this.delivery});

  final Delivery delivery;

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _RoutePainter(
              route: decodePolyline(delivery.route.encodedPolyline),
              origin: delivery.origin.point,
              destination: delivery.destination.point,
              driver: delivery.driverLocation?.point,
              background: context.status.brandSurface,
              grid: context.status.decorative,
              routeColor: context.colors.primary,
              originColor: context.status.onSuccessContainer,
              destinationColor: context.colors.error,
              driverColor: context.colors.secondary,
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.s,
          bottom: AppSpacing.s,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
            decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(AppRadii.s)),
            child: Text('Vista simplificada (mapa sin clave de Google)', style: context.text.labelSmall),
          ),
        ),
      ]);
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({
    required this.route,
    required this.origin,
    required this.destination,
    required this.driver,
    required this.background,
    required this.grid,
    required this.routeColor,
    required this.originColor,
    required this.destinationColor,
    required this.driverColor,
  });

  final List<GeoPoint> route;
  final GeoPoint origin, destination;
  final GeoPoint? driver;
  final Color background, grid, routeColor, originColor, destinationColor, driverColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final all = [...route, origin, destination, if (driver != null) driver!];
    final project = _projector(all, size);
    if (route.length >= 2) {
      final path = Path()..moveTo(project(route.first).dx, project(route.first).dy);
      for (final p in route.skip(1)) {
        final o = project(p);
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = routeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
    _dot(canvas, project(origin), originColor, 9);
    _dot(canvas, project(destination), destinationColor, 9);
    if (driver != null) _dot(canvas, project(driver!), driverColor, 11);
  }

  static void _dot(Canvas canvas, Offset at, Color color, double radius) {
    canvas.drawCircle(at, radius + 3, Paint()..color = Colors.white);
    canvas.drawCircle(at, radius, Paint()..color = color);
  }

  /// Fits all points in the box keeping the aspect ratio (longitude scaled by latitude).
  static Offset Function(GeoPoint) _projector(List<GeoPoint> points, Size size) {
    const padding = 28.0;
    final scaleLng = math.cos(points.first.lat * math.pi / 180);
    final xs = points.map((p) => p.lng * scaleLng);
    final ys = points.map((p) => p.lat);
    final minX = xs.reduce(math.min), maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min), maxY = ys.reduce(math.max);
    final spanX = math.max(maxX - minX, 1e-6), spanY = math.max(maxY - minY, 1e-6);
    final scale = math.min((size.width - 2 * padding) / spanX, (size.height - 2 * padding) / spanY);
    final offsetX = (size.width - spanX * scale) / 2, offsetY = (size.height - spanY * scale) / 2;
    return (p) => Offset(offsetX + (p.lng * scaleLng - minX) * scale, size.height - (offsetY + (p.lat - minY) * scale));
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) =>
      old.route != route || old.driver != driver || old.origin != origin || old.destination != destination;
}
