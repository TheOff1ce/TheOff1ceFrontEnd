import 'dart:convert';

import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/auth/auth_controller.dart';
import 'package:farma_go/auth/auth_repository.dart';
import 'package:farma_go/auth/password_reset_controller.dart';
import 'package:farma_go/components/farmago/feedback.dart';
import 'package:farma_go/hooks/driver_board_controller.dart';
import 'package:farma_go/hooks/driver_delivery_controller.dart';
import 'package:farma_go/pages/driver_board_page.dart';
import 'package:farma_go/pages/driver_delivery_page.dart';
import 'package:farma_go/pages/reset_password_page.dart';
import 'package:farma_go/pages/verify_email_page.dart';
import 'package:farma_go/services/delivery_service.dart';
import 'package:farma_go/services/location_source.dart';
import 'package:farma_go/services/order_service.dart';
import 'package:farma_go/types/delivery.dart';
import 'package:farma_go/types/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'delivery_test.dart' show clientWith, deliveryJson, patientOrderJson, respond;

/// La app real: los avisos viven en la capa de encima de todas las pantallas.
Widget _app(Widget home) => MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => FgCapaAvisos(child: child!),
      home: home,
    );

void _pantalla(WidgetTester tester, [Size size = const Size(420, 900)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

Map<String, dynamic> _me({bool complete = false}) => {
      'id': 'p-1',
      'email': 'ana@x.co',
      'name': 'Ana Pérez',
      'role': 'PATIENT',
      'provider': 'LOCAL',
      'emailVerified': true,
      'createdAt': '2026-10-01T15:00:00.000Z',
      'lastLoginAt': null,
      'profile': const <String, dynamic>{},
      'profileComplete': complete,
      'profileMissing': complete ? <String>[] : ['documentType'],
    };

class _GpsQuieto implements LocationSource {
  @override
  Future<void> ensureReady() async {}

  @override
  Future<GpsFix> currentFix() async =>
      GpsFix(point: const GeoPoint(4.665, -74.06), accuracy: 8, recordedAt: DateTime.now().toUtc());
}

Future<void> _red(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
  await tester.pump();
}

void main() {
  group('capa de avisos', () {
    testWidgets('un aviso sin contexto se ve con título y lo que sigue, y se cierra solo', (tester) async {
      _pantalla(tester);
      await tester.pumpWidget(_app(const Scaffold(body: Text('Inicio'))));
      avisar('Pedido confirmado', detalle: 'Te avisamos cuando un repartidor lo tome.');
      await tester.pump();
      expect(find.text('Pedido confirmado'), findsOneWidget);
      expect(find.text('Te avisamos cuando un repartidor lo tome.'), findsOneWidget);
      // Lectores de pantalla: título y detalle en un solo anuncio.
      expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.liveRegion == true &&
            w.properties.label == 'Pedido confirmado Te avisamos cuando un repartidor lo tome.'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 7));
      expect(find.text('Pedido confirmado'), findsNothing);
    });

    testWidgets('sobrevive al cambio de pantalla', (tester) async {
      _pantalla(tester);
      await tester.pumpWidget(_app(const Scaffold(body: Text('Código'))));
      avisar('Tu cuenta quedó creada');
      await tester.pump();
      // El enrutador cambia la pantalla de abajo: el aviso sigue ahí.
      await tester.pumpWidget(_app(const Scaffold(body: Text('Completa tus datos'))));
      await tester.pump();
      expect(find.text('Completa tus datos'), findsOneWidget);
      expect(find.text('Tu cuenta quedó creada'), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar aviso'));
      await tester.pump();
      expect(find.text('Tu cuenta quedó creada'), findsNothing);
    });

    testWidgets('el check se dibuja y termina; con movimiento reducido no hay animación pendiente', (tester) async {
      _pantalla(tester);
      await tester.pumpWidget(_app(const Scaffold(body: SizedBox())));
      avisar('Datos guardados');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Datos guardados'), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar aviso'));
      await tester.pump();

      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(size: Size(420, 900), disableAnimations: true),
        child: _app(const Scaffold(body: SizedBox())),
      ));
      avisar('Datos guardados');
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      await tester.tap(find.byTooltip('Cerrar aviso'));
      await tester.pump();
    });

    testWidgets('uno nuevo reemplaza al anterior', (tester) async {
      _pantalla(tester);
      await tester.pumpWidget(_app(const Scaffold(body: SizedBox())));
      avisar('Pedido recogido');
      await tester.pump();
      avisar('Viaje iniciado');
      await tester.pump();
      expect(find.text('Pedido recogido'), findsNothing);
      expect(find.text('Viaje iniciado'), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
    });
  });

  group('momentos', () {
    testWidgets('cuenta creada al verificar el código del registro (no al iniciar sesión)', (tester) async {
      _pantalla(tester);
      final auth = AuthController(AuthRepository('https://auth.x',
          usesBrowserCookies: true,
          client: MockClient((request) async => switch (request.url.path) {
                '/auth/signup' || '/auth/login' => _json({'success': true}, 201),
                '/auth/verify-code' => _json({'accessToken': 't', 'expiresIn': 600}),
                '/auth/me' => _json(_me()),
                _ => _json({}, 404),
              })));
      await tester.runAsync(() => auth.signUp(name: 'Ana Pérez', email: 'ana@x.co', password: 'Clave12345!'));
      await tester.pumpWidget(_app(VerifyEmailPage(auth: auth, onBack: () {})));
      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();
      await tester.tap(find.text('Verificar código'));
      await _red(tester);
      expect(find.text('Tu cuenta quedó creada'), findsOneWidget);
      expect(find.text('Completa tus datos para empezar a usar FarmaGo.'), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar aviso'));
      await tester.pump();

      await tester.runAsync(auth.logout);
      await tester.runAsync(() => auth.login(email: 'ana@x.co', password: 'Clave12345!'));
      await tester.pumpWidget(_app(VerifyEmailPage(key: UniqueKey(), auth: auth, onBack: () {})));
      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();
      await tester.tap(find.text('Verificar código'));
      await _red(tester);
      expect(find.text('Tu cuenta quedó creada'), findsNothing);
      auth.dispose();
    });

    testWidgets('contraseña restablecida: avisa y lleva a iniciar sesión', (tester) async {
      _pantalla(tester, const Size(420, 1200));
      final reset = PasswordResetController(AuthRepository('https://auth.x',
          usesBrowserCookies: true, client: MockClient((_) async => _json({'success': true}))));
      await tester.runAsync(() async {
        await reset.requestCode('ana@x.co');
        await reset.verifyCode('123456');
      });
      var aLogin = 0;
      await tester.pumpWidget(_app(ResetPasswordPage(reset: reset, onLogin: () => aLogin++, onBack: () {})));
      await tester.pump();
      final campos = find.byType(TextField);
      await tester.enterText(campos.at(0), 'NuevaClave123!');
      await tester.enterText(campos.at(1), 'NuevaClave123!');
      await tester.tap(find.text('Restablecer contraseña'));
      await _red(tester);
      expect(aLogin, 1);
      expect(find.text('Contraseña actualizada'), findsOneWidget);
      expect(find.text('Inicia sesión con tu nueva contraseña.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
    });

    testWidgets('el repartidor toma un pedido', (tester) async {
      _pantalla(tester, const Size(420, 1400));
      final board = DriverBoardController(
        OrderService(clientWith((request) async {
          if (request.url.path.endsWith('/take')) return respond({...patientOrderJson(status: 'TAKEN')}, 200);
          if (request.url.path.endsWith('/taken')) return respond({'orders': []}, 200);
          return respond({
            'orders': [
              {
                'id': 'o-1',
                'pharmacy': {'name': 'Farmacia 72', 'address': 'Calle 72 # 10-20'},
                'itemCount': 1,
                'routeSummary': {'distanceMeters': 2300, 'durationSeconds': 615},
              }
            ],
          }, 200);
        })),
      );
      final abiertos = <String>[];
      await tester.pumpWidget(_app(DriverBoardPage(controller: board, onOpen: (o) => abiertos.add(o.id), onBack: () {})));
      await _red(tester);
      final tomar = find.text('Tomar pedido').first;
      await tester.ensureVisible(tomar);
      await tester.tap(tomar);
      await _red(tester);
      expect(abiertos, ['o-1']);
      expect(find.text('Tomaste el pedido'), findsOneWidget);
      expect(find.text('Recógelo en Farmacia 72.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
    });

    testWidgets('el repartidor recoge, sale y se entera cuando el paciente confirma', (tester) async {
      _pantalla(tester, const Size(420, 1600));
      var estado = 'ASSIGNED';
      late DriverDeliveryController controlador;
      final deliveries = DeliveryService(clientWith((request) async {
        if (request.method == 'PATCH' && request.url.path.endsWith('/status')) {
          estado = (jsonDecode(request.body) as Map)['status'] as String;
        }
        if (request.url.path.endsWith('/locations')) {
          return respond({'accepted': true, 'reason': null, 'status': estado, 'eta': null}, 200);
        }
        return respond({...deliveryJson(status: estado), 'id': 'd-1'}, 200);
      }));
      final pedido = DriverOrder.fromJson({...patientOrderJson(status: 'TAKEN'), 'deliveryId': 'd-1'});
      await tester.pumpWidget(_app(DriverDeliveryPage(
        order: pedido,
        onBack: () {},
        createController: (id) => controlador = DriverDeliveryController(
          deliveryId: id,
          deliveries: deliveries,
          location: _GpsQuieto(),
          interval: const Duration(hours: 1),
        ),
      )));
      await _red(tester);

      await tester.tap(find.text('Ya recogí el pedido'));
      await _red(tester);
      expect(find.text('Cuando salgas hacia el paciente, toca «Empezar viaje».'), findsOneWidget);

      await tester.tap(find.text('Empezar viaje'));
      await _red(tester);
      expect(find.text('Viaje iniciado'), findsOneWidget);
      expect(find.text('El paciente ya puede seguirte en el mapa.'), findsOneWidget);

      // El paciente confirma con el código desde su celular.
      estado = 'DELIVERED';
      await tester.runAsync(controlador.start);
      await tester.pump();
      expect(find.text('Entrega confirmada'), findsOneWidget);
      expect(find.text('El paciente confirmó con tu código.'), findsOneWidget);
      expect(controlador.delivery?.status, DeliveryStatus.delivered);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
