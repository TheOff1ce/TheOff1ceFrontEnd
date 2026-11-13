import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/auth/auth_controller.dart';
import 'package:farma_go/auth/auth_repository.dart';
import 'package:farma_go/hooks/eps_resumen_controller.dart';
import 'package:farma_go/hooks/patient_home_controller.dart';
import 'package:farma_go/hooks/patient_orders_controller.dart';
import 'package:farma_go/notifications/notification_controller.dart';
import 'package:farma_go/notifications/notification_repository.dart';
import 'package:farma_go/pages/home_page.dart';
import 'package:farma_go/services/delivery_service.dart';
import 'package:farma_go/services/order_service.dart';
import 'package:farma_go/services/pendientes_service.dart';
import 'package:farma_go/types/auth_models.dart';
import 'package:farma_go/types/delivery.dart';
import 'package:farma_go/types/order.dart';
import 'package:farma_go/types/pendiente.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fuentes_reales.dart';

/// Servicios sin red: la home de prueba nunca los llama porque el foco se fija directamente.
class _OrdenesFalsas implements OrderService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _PendientesFalsos implements PendientesService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _EntregasFalsas implements DeliveryService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Inicio del paciente con un foco fijo. No consulta nada.
class InicioFalso extends PatientHomeController {
  InicioFalso(this._foco, {this.recordatorio})
      : super(
          orders: PatientOrdersController(_OrdenesFalsas()),
          pendientes: _PendientesFalsos(),
          deliveries: _EntregasFalsas(),
        );

  final FocoInicio? _foco;
  final PorCalificar? recordatorio;

  @override
  Future<void> load() async {
    foco = _foco;
    porCalificar = recordatorio;
    notifyListeners();
  }
}

/// Domicilio de prueba con fechas fijas. `detalle` es opcional: sin él no hay hora estimada.
FocoDomicilio focoDomicilio({Delivery? detalle, OrderStatus estadoPedido = OrderStatus.taken}) => FocoDomicilio(
      pedido: PatientOrder(
        id: 'p-1',
        status: estadoPedido,
        pharmacy: const Pharmacy(name: 'Farmacia Central', address: 'Calle 10 # 20-30'),
        deliveryAddress: 'Carrera 5 # 8-12',
        items: const [],
        notes: null,
        deliveryId: 'd-1',
        routeSummary: const RouteSummary(distanceMeters: 1200, durationSeconds: 300),
        driverAssigned: true,
        createdAt: DateTime.utc(2026, 11, 1, 12),
      ),
      estado: DeliveryStatus.inTransit,
      detalle: detalle,
    );

/// Entrega con los campos que usa la home.
Delivery entregaDePrueba({DateTime? eta}) => Delivery(
      id: 'd-1',
      orderId: 'p-1',
      status: DeliveryStatus.inTransit,
      origin: const DeliveryPlace(address: 'Calle 10 # 20-30', point: GeoPoint(4.6, -74.1)),
      destination: const DeliveryPlace(address: 'Carrera 5 # 8-12', point: GeoPoint(4.61, -74.11)),
      route: const DeliveryRoute(encodedPolyline: '', distanceMeters: 1200, durationSeconds: 300),
      eta: eta,
      driverAssigned: true,
      driverLocation: null,
      distanceToDestinationMeters: 1200,
    );

/// Pendiente vigente de prueba: 48 h de plazo, ninguna entrega todavía.
FocoPendiente focoPendiente({String cumplimiento = 'VIGENTE'}) => FocoPendiente(
      PendienteResumen.fromJson({
        'id': 'pend-1',
        'ordenMedicamentoId': 'om-1',
        'pacienteId': 'pac-1',
        'epsUserId': 'eps-1',
        'dispensarioId': 'disp-1',
        'fechaEvento': '2026-10-31T12:00:00Z',
        'fechaRegistro': '2026-10-31T12:00:00Z',
        'fechaLimite': '2026-11-02T12:00:00Z',
        'estadoEntrega': 'PENDIENTE',
        'fechaEntrega': null,
        'cumplimientoPlazo': cumplimiento,
        'evaluadoEn': '2026-11-01T12:00:00Z',
        'medicamentosTotal': 2,
        'medicamentosEntregados': 1,
        'cantidadNovedades': 0,
      }),
    );

/// Monta la home con el rol, el foco y el ancho dados.
Future<void> montarInicio(
  WidgetTester tester, {
  required String role,
  required String name,
  required double ancho,
  double altura = 1100,
  FocoInicio? foco,
  VoidCallback? onAnalyze,
  VoidCallback? onMyOrders,
  void Function(String)? onTracking,
  void Function(String)? onPendienteDetalle,
  EpsResumenController? resumenEps,
  PorCalificar? porCalificar,
  void Function(String)? onCalificar,
}) async {
  await tester.runAsync(cargarFuentesReales);
  tester.view.physicalSize = Size(ancho, altura);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final auth = AuthController(
    AuthRepository('http://localhost', client: MockClient((_) async => http.Response('{}', 500))),
    retryDelays: const [],
  );
  auth.user = AuthUser(id: '1', name: name, email: 'prueba@farmago.test', role: role);

  void noop() {}
  // El logo es una imagen: se espera su decodificación para que la captura no la omita.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pumpWidget(MaterialApp(theme: AppTheme.light, 
    debugShowCheckedModeBanner: false,
    home: HomePage(
      auth: auth,
      notifications: NotificationController(NotificationRepository()),
      inicio: InicioFalso(foco, recordatorio: porCalificar),
      onCalificar: onCalificar,
      resumenEps: resumenEps,
      onAnalyze: onAnalyze ?? noop,
      onNotifications: noop,
      onAccount: noop,
      onRequestDelivery: noop,
      onMyOrders: onMyOrders ?? noop,
      onDriverBoard: noop,
      onPendientes: noop,
      onAdminUsers: noop,
      onAdminOrders: noop,
      onTracking: onTracking ?? (_) {},
      onPendienteDetalle: onPendienteDetalle ?? (_) {},
    ),
  ));
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pumpAndSettle();
}
