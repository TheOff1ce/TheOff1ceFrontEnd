import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/auth/auth_controller.dart';
import 'package:farma_go/auth/auth_repository.dart';
import 'package:farma_go/hooks/admin_inicio_controller.dart';
import 'package:farma_go/hooks/eps_resumen_controller.dart';
import 'package:farma_go/hooks/patient_home_controller.dart';
import 'package:farma_go/hooks/patient_orders_controller.dart';
import 'package:farma_go/notifications/notification_controller.dart';
import 'package:farma_go/notifications/notification_repository.dart';
import 'package:farma_go/pages/home_page.dart';
import 'package:farma_go/services/admin_service.dart';
import 'package:farma_go/services/authorized_json_client.dart';
import 'package:farma_go/services/access_token_source.dart';
import 'package:farma_go/types/calificaciones.dart';
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
  AdminInicioController? inicioAdmin,
  void Function(String)? onAdminTracking,
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
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    debugShowCheckedModeBanner: false,
    home: HomePage(
      auth: auth,
      notifications: NotificationController(NotificationRepository()),
      inicio: InicioFalso(foco, recordatorio: porCalificar),
      onCalificar: onCalificar,
      inicioAdmin: inicioAdmin,
      onAdminTracking: onAdminTracking,
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

/// Tablero del administrador con datos fijos (sin red), para capturas y pruebas de la vista.
class InicioAdminFalso extends AdminInicioController {
  InicioAdminFalso({DateTime? ahora})
      : _ahora = ahora ?? DateTime(2026, 11, 21, 16),
        super(deliveries: _EntregasFalsas(), admin: AdminService(auth: _cliente(), orders: _cliente()));

  final DateTime _ahora;

  @override
  DateTime get ahora => _ahora;

  static AuthorizedJsonClient _cliente() => AuthorizedJsonClient(
        'http://localhost',
        tokens: _SinToken(),
        client: MockClient((_) async => http.Response('{}', 500)),
        timeout: const Duration(seconds: 5),
      );

  static Delivery _entrega(String id, DeliveryStatus estado, DateTime desde, {String origen = 'Farmacia Calle 72'}) =>
      Delivery(
        id: id,
        orderId: 'o-$id',
        status: estado,
        origin: DeliveryPlace(address: origen, point: const GeoPoint(4.66, -74.06)),
        destination: const DeliveryPlace(address: 'Calle 92 # 15-30, Bogotá', point: GeoPoint(4.68, -74.05)),
        route: const DeliveryRoute(encodedPolyline: '', distanceMeters: 2300, durationSeconds: 615),
        eta: null,
        driverAssigned: estado != DeliveryStatus.created,
        driverLocation: null,
        distanceToDestinationMeters: null,
        deliveredAt: estado == DeliveryStatus.delivered ? desde : null,
        statusTimes: {estado: desde},
      );

  @override
  Future<void> load() async {
    final entregas = <Delivery>[
      _entrega('e1', DeliveryStatus.created, _ahora.subtract(const Duration(minutes: 42))),
      _entrega('e2', DeliveryStatus.created, _ahora.subtract(const Duration(minutes: 9)), origen: 'Droguería Central'),
      for (var i = 0; i < 4; i++) _entrega('c$i', DeliveryStatus.inTransit, _ahora),
      for (var dia = 0; dia < 7; dia++) ...[
        for (var i = 0; i < 5 + dia % 3 * 2; i++)
          _entrega('d$dia-$i', DeliveryStatus.delivered, _ahora.subtract(Duration(days: dia, minutes: i))),
        if (dia.isEven) _entrega('f$dia', DeliveryStatus.failed, _ahora.subtract(Duration(days: dia, hours: 1))),
      ],
    ];
    operacion = OperacionHoy.de(entregas, _ahora);
    calificaciones = ReporteCalificaciones.fromJson({
      'days': 7,
      'count': 25,
      'average': 4.2,
      'distribution': {'1': 2, '2': 1, '3': 2, '4': 6, '5': 14},
      'drivers': [],
      'lowRatings': [],
      'truncated': false,
    });
    usuarios = const UsuariosResumen(total: 128, repartidores: 14);
    notifyListeners();
  }
}

class _SinToken implements AccessTokenSource {
  @override
  Future<String?> currentAccessToken({bool forceRefresh = false}) async => null;
}
