import 'package:farma_go/app/app_routes.dart';
import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/app/titulos.dart';
import 'package:farma_go/components/farmago/banda_sin_conexion.dart';
import 'package:farma_go/components/farmago/feedback.dart';
import 'package:farma_go/notifications/notification_controller.dart';
import 'package:farma_go/notifications/notification_item.dart';
import 'package:farma_go/notifications/notification_repository.dart';
import 'package:farma_go/notifications/vigia_domicilios.dart';
import 'package:farma_go/pages/notifications_page.dart';
import 'package:farma_go/services/delivery_service.dart';
import 'package:farma_go/services/estado_conexion.dart';
import 'package:farma_go/services/order_service.dart';
import 'package:farma_go/types/delivery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'delivery_test.dart' show clientWith, deliveryJson, patientOrderJson, respond;

FotoDomicilios _foto(Map<String, DeliveryStatus> estados, {Map<String, String> disponibles = const {}}) => FotoDomicilios(
      estados: estados,
      farmacias: {for (final id in estados.keys) id: 'Farmacia 72'},
      pedidos: {for (final id in estados.keys) id: 'o-$id'},
      disponibles: disponibles,
    );

class _Memoria implements NotificationRepository {
  final datos = <String, List<NotificationItem>>{};

  @override
  bool get persistent => true;

  @override
  Future<List<NotificationItem>> read(String userId) async => datos[userId] ?? const [];

  @override
  Future<void> write(String userId, List<NotificationItem> items) async => datos[userId] = [...items];
}

void main() {
  group('cambios del paciente', () {
    test('avisa cuando el domicilio avanza, con la farmacia', () {
      final eventos = cambiosDelPaciente(
        _foto({'d1': DeliveryStatus.created, 'd2': DeliveryStatus.pickedUp}),
        _foto({'d1': DeliveryStatus.assigned, 'd2': DeliveryStatus.arriving}),
        AppRoutes.tracking,
      );
      expect(eventos.map((e) => e.titulo), ['Un repartidor tomó tu pedido', 'Tu repartidor está llegando']);
      expect(eventos.first.mensaje, 'Va a recoger tu pedido de Farmacia 72.');
      expect(eventos.first.ruta, '/orders/tracking/d1');
    });

    test('no avisa lo que el paciente hizo ni retrocesos; sí cuando no se pudo entregar', () {
      expect(
        cambiosDelPaciente(
          _foto({'d1': DeliveryStatus.arriving, 'd2': DeliveryStatus.created, 'd3': DeliveryStatus.inTransit}),
          _foto({'d1': DeliveryStatus.delivered, 'd2': DeliveryStatus.cancelled, 'd3': DeliveryStatus.pickedUp}),
          AppRoutes.tracking,
        ),
        isEmpty,
      );
      final fallo = cambiosDelPaciente(
          _foto({'d1': DeliveryStatus.inTransit}), _foto({'d1': DeliveryStatus.failed}), AppRoutes.tracking);
      expect(fallo.single.titulo, 'No se pudo entregar tu pedido');
      expect(fallo.single.tono, TonoEvento.problema);
    });
  });

  group('cambios del repartidor', () {
    test('cancelado, confirmado y pedidos nuevos para tomar', () {
      final eventos = cambiosDelRepartidor(
        _foto({'d1': DeliveryStatus.assigned, 'd2': DeliveryStatus.arriving}, disponibles: {'o-9': 'Droguería Central'}),
        _foto({'d1': DeliveryStatus.cancelled, 'd2': DeliveryStatus.delivered},
            disponibles: {'o-9': 'Droguería Central', 'o-10': 'Farmacia 72'}),
        rutaEntrega: AppRoutes.driverDelivery,
        rutaTablero: AppRoutes.driverBoard,
      );
      expect(eventos.map((e) => e.titulo), [
        'El paciente canceló un pedido',
        'Entrega confirmada',
        'Hay un pedido nuevo para tomar',
      ]);
      expect(eventos[1].ruta, '/driver/orders/o-d2');
      expect(eventos.last.mensaje, 'Recógelo en Farmacia 72.');
    });
  });

  group('vigía', () {
    test('la primera revisión no avisa; las siguientes sí, una sola vez por cambio', () async {
      var estado = 'CREATED';
      final eventos = <EventoDomicilio>[];
      final vigia = VigiaDomicilios(
        orders: OrderService(clientWith((_) async => respond({'orders': [patientOrderJson()]}, 200))),
        deliveries: DeliveryService(clientWith((_) async => respond({
              'deliveries': [
                {...deliveryJson(status: estado), 'id': 'd-1'}
              ]
            }, 200))),
        onEvento: eventos.add,
        rutaSeguimiento: AppRoutes.tracking,
        rutaEntrega: AppRoutes.driverDelivery,
        rutaTablero: AppRoutes.driverBoard,
        intervalo: const Duration(hours: 1),
      );
      vigia.iniciar(RolVigilado.paciente);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(eventos, isEmpty);

      estado = 'ASSIGNED';
      await vigia.revisarAhora();
      await vigia.revisarAhora();
      expect(eventos.map((e) => e.titulo), ['Un repartidor tomó tu pedido']);
      expect(eventos.single.mensaje, contains('Farmacia 72'));

      // Al cerrar sesión no queda nada pendiente ni se avisa más.
      vigia.detener();
      estado = 'IN_TRANSIT';
      await vigia.revisarAhora();
      expect(eventos, hasLength(1));
    });

    test('sin señal conserva la foto anterior y avisa cuando vuelve', () async {
      var estado = 'ASSIGNED';
      var conSenal = true;
      final eventos = <EventoDomicilio>[];
      final vigia = VigiaDomicilios(
        orders: OrderService(clientWith((_) async => respond({'orders': [patientOrderJson()]}, 200))),
        deliveries: DeliveryService(clientWith((_) async {
          if (!conSenal) throw http.ClientException('sin red');
          return respond({
            'deliveries': [
              {...deliveryJson(status: estado), 'id': 'd-1'}
            ]
          }, 200);
        })),
        onEvento: eventos.add,
        rutaSeguimiento: AppRoutes.tracking,
        rutaEntrega: AppRoutes.driverDelivery,
        rutaTablero: AppRoutes.driverBoard,
        intervalo: const Duration(hours: 1),
      );
      vigia.iniciar(RolVigilado.paciente);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      conSenal = false;
      estado = 'IN_TRANSIT';
      await vigia.revisarAhora();
      expect(eventos, isEmpty);
      conSenal = true;
      await vigia.revisarAhora();
      expect(eventos.single.titulo, 'Tu pedido va en camino');
      vigia.detener();
      EstadoConexion.instancia.reiniciar();
    });
  });

  group('notificaciones de domicilio', () {
    testWidgets('quedan en la campana y abren el seguimiento', (tester) async {
      final notificaciones = NotificationController(_Memoria());
      await notificaciones.loadForUser('u-1');
      await notificaciones.addDomicilio(const EventoDomicilio(
        clave: 'd-1:ASSIGNED',
        titulo: 'Un repartidor tomó tu pedido',
        mensaje: 'Va a recoger tu pedido de Farmacia 72.',
        ruta: '/orders/tracking/d-1',
      ));
      final abiertas = <String>[];
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: NotificationsPage(notifications: notificaciones, onBack: () {}, onAbrir: abiertas.add),
      ));
      expect(find.textContaining('Un repartidor tomó tu pedido'), findsOneWidget);
      expect(find.byIcon(Icons.delivery_dining_outlined), findsOneWidget);
      await tester.tap(find.textContaining('Va a recoger tu pedido'));
      await tester.pump();
      expect(abiertas, ['/orders/tracking/d-1']);
      expect(notificaciones.unreadCount, 0);

      // La ruta sobrevive al guardado.
      final copia = NotificationItem.fromJson(notificaciones.items.single.toJson());
      expect(copia.ruta, '/orders/tracking/d-1');
      expect(copia.kind, NotificationKind.delivery);
      expect(NotificationItem.fromJson({...copia.toJson(), 'ruta': 'https://otro.sitio'}).ruta, isNull);
    });
  });

  group('título de la pestaña', () {
    test('cada pantalla con su nombre', () {
      expect(TitulosDePantalla.paraRuta('/'), 'FarmaGo');
      expect(TitulosDePantalla.paraRuta(AppRoutes.home), 'Inicio · FarmaGo');
      expect(TitulosDePantalla.paraRuta(AppRoutes.tracking('d-1')), 'Seguimiento del domicilio · FarmaGo');
      expect(TitulosDePantalla.paraRuta(AppRoutes.driverDelivery('o-1')), 'Entrega · FarmaGo');
      expect(TitulosDePantalla.paraRuta(AppRoutes.myOrders), 'Mis domicilios · FarmaGo');
      expect(TitulosDePantalla.paraRuta('/no-existe'), 'Página no encontrada · FarmaGo');
    });
  });

  group('sin conexión', () {
    setUp(EstadoConexion.instancia.reiniciar);

    test('un fallo de red la marca; dos demoras también; cualquier respuesta la quita', () {
      final e = EstadoConexion.instancia;
      e.demora();
      expect(e.sinConexion, isFalse);
      e.demora();
      expect(e.sinConexion, isTrue);
      e.respuesta();
      expect(e.sinConexion, isFalse);
      e.falloDeRed();
      expect(e.sinConexion, isTrue);
    });

    testWidgets('la banda aparece arriba, prueba sola y se recoge al volver la conexión', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var hayRed = false;
      var pruebas = 0;
      final cliente = MockClient((_) async {
        pruebas++;
        if (!hayRed) throw http.ClientException('sin red');
        return http.Response('{}', 200);
      });
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => FgCapaAvisos(
          child: BandaSinConexion(
            cliente: cliente,
            sonda: Uri.parse('https://farmago.test/version.json'),
            cada: const Duration(seconds: 8),
            child: child!,
          ),
        ),
        home: Scaffold(appBar: AppBar(title: const Text('Inicio'))),
      ));
      expect(find.text('Reintentar'), findsNothing);

      EstadoConexion.instancia.falloDeRed();
      await tester.pumpAndSettle();
      expect(find.textContaining('Sin conexión.'), findsOneWidget);
      // Empuja la app: la barra superior queda debajo de la banda, no tapada.
      expect(tester.getTopLeft(find.byType(AppBar)).dy, greaterThan(0));

      await tester.tap(find.text('Reintentar'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
      expect(pruebas, 1);
      expect(find.textContaining('Sin conexión.'), findsOneWidget);

      hayRed = true;
      await tester.pump(const Duration(seconds: 8));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();
      expect(pruebas, 2);
      expect(find.textContaining('Sin conexión.'), findsNothing);
      expect(find.text('Conexión recuperada'), findsOneWidget);
      expect(tester.getTopLeft(find.byType(AppBar)).dy, 0);
      await tester.pump(const Duration(seconds: 7));
    });
  });
}
