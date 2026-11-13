import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/hooks/tracking_controller.dart';
import 'package:farma_go/pages/tracking_page.dart';
import 'package:farma_go/services/delivery_service.dart';
import 'package:farma_go/services/tracking_channel.dart';
import 'package:farma_go/types/delivery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fuentes_reales.dart';

/// Servicios sin red: la página solo necesita el estado que el controlador ya tiene.
class _ServicioFalso implements DeliveryService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _CanalFalso implements TrackingChannel {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Controlador con una entrega ya cargada: no pide datos ni abre el canal en tiempo real.
class _ControladorFalso extends TrackingController {
  _ControladorFalso(this._entrega, {bool conectado = true})
      : super(deliveryId: 'd-1', deliveries: _ServicioFalso(), channel: _CanalFalso()) {
    delivery = _entrega;
    loading = false;
    connected = conectado;
  }

  final Delivery _entrega;

  @override
  Future<void> start() async {}
}

Delivery _entrega(DeliveryStatus estado, {bool sinEta = false}) => Delivery(
      id: 'd-1',
      orderId: 'o-1',
      status: estado,
      origin: const DeliveryPlace(address: 'Calle 10 # 20-30', point: GeoPoint(4.6, -74.1)),
      destination: const DeliveryPlace(address: 'Carrera 5 # 8-12', point: GeoPoint(4.61, -74.11)),
      route: const DeliveryRoute(encodedPolyline: "", distanceMeters: 1200, durationSeconds: 300),
      eta: sinEta ? null : DateTime.now().add(const Duration(minutes: 12)),
      driverAssigned: true,
      driverLocation: null,
      distanceToDestinationMeters: 1200,
    );

Future<void> _montar(
  WidgetTester tester,
  DeliveryStatus estado, {
  bool conectado = true,
  bool accionesDelPaciente = true,
}) async {
  // La lista es perezosa: el viewport alto deja visibles el trayecto y los datos de abajo.
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: AppTheme.light, 
    home: TrackingPage(
      createController: () => _ControladorFalso(_entrega(estado), conectado: conectado),
      onBack: () {},
      showPatientActions: accionesDelPaciente,
    ),
  ));
  await tester.pump();
}

void main() {
  captura();
  testWidgets('en camino: estado, llegada, distancia y el trayecto con sus tres estados', (tester) async {
    await _montar(tester, DeliveryStatus.inTransit);
    expect(find.text('En vivo'), findsOneWidget);
    expect(find.text('Llegada estimada'), findsOneWidget);
    expect(find.text('Distancia'), findsOneWidget);
    expect(find.text('Completado'), findsNWidgets(3));
    expect(find.text('En curso'), findsOneWidget);
    expect(find.text('Pendiente'), findsNWidgets(2));
    expect(find.text('Farmacia'), findsOneWidget);
    expect(find.text('Calle 10 # 20-30'), findsOneWidget);
  });

  testWidgets('el paciente confirma la entrega con el código cuando va en camino', (tester) async {
    await _montar(tester, DeliveryStatus.inTransit);
    expect(find.text('¿Ya recibiste tu pedido?'), findsOneWidget);
  });

  testWidgets('el administrador sigue el envío sin el formulario del código', (tester) async {
    await _montar(tester, DeliveryStatus.inTransit, accionesDelPaciente: false);
    expect(find.text('¿Ya recibiste tu pedido?'), findsNothing);
    expect(find.text('Confirmar entrega'), findsNothing);
    expect(find.text('Llegada estimada'), findsOneWidget);
  });

  testWidgets('sin conexión en vivo se dice con texto', (tester) async {
    await _montar(tester, DeliveryStatus.inTransit, conectado: false);
    expect(find.text('Reconectando…'), findsOneWidget);
    expect(find.text('En vivo'), findsNothing);
  });

  testWidgets('entregado: todos los pasos completados y sin datos de ruta en vivo', (tester) async {
    await _montar(tester, DeliveryStatus.delivered);
    expect(find.text('Completado'), findsNWidgets(6));
    expect(find.text('En curso'), findsNothing);
    expect(find.text('Llegada estimada'), findsNothing);
    expect(find.text('La ubicación del repartidor ya no se comparte.'), findsOneWidget);
    // Recién entregado y sin calificar: el paciente puede dejar sus estrellas.
    expect(find.text('¿Cómo estuvo la entrega?'), findsOneWidget);
  });

  testWidgets('el administrador no ve el formulario de calificación', (tester) async {
    await _montar(tester, DeliveryStatus.delivered, accionesDelPaciente: false);
    expect(find.text('¿Cómo estuvo la entrega?'), findsNothing);
  });

  testWidgets('cancelado: aparece como estado terminal, no como un paso del trayecto', (tester) async {
    await _montar(tester, DeliveryStatus.cancelled);
    expect(find.text('Cancelado'), findsWidgets);
    expect(find.text('Completado'), findsNothing);
    expect(find.text('Pendiente'), findsNothing);
    expect(find.text('Llegada estimada'), findsNothing);
  });

  testWidgets('no se pudo entregar: estado terminal de error con su palabra', (tester) async {
    await _montar(tester, DeliveryStatus.failed);
    expect(find.text('No se pudo entregar'), findsWidgets);
    expect(find.text('Pendiente'), findsNothing);
  });
}

void captura() {
  testWidgets('seguimiento en camino a 360 px, con la fuente real', (tester) async {
    await tester.runAsync(cargarFuentesReales);
    tester.view.physicalSize = const Size(360, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, 
      home: TrackingPage(
        createController: () => _ControladorFalso(_entrega(DeliveryStatus.inTransit, sinEta: true)),
        onBack: () {},
      ),
    ));
    await tester.pumpAndSettle();
    await expectLater(find.byType(TrackingPage), matchesGoldenFile('goldens/seguimiento_en_camino_360.png'));
  });
}
