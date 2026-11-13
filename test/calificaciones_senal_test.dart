import 'dart:convert';

import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/hooks/admin_ratings_controller.dart';
import 'package:farma_go/hooks/driver_delivery_controller.dart';
import 'package:farma_go/hooks/patient_home_controller.dart';
import 'package:farma_go/pages/admin_ratings_page.dart';
import 'package:farma_go/services/admin_service.dart';
import 'package:farma_go/services/delivery_service.dart';
import 'package:farma_go/services/location_source.dart';
import 'package:farma_go/types/calificaciones.dart';
import 'package:farma_go/types/delivery.dart';
import 'package:farma_go/types/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'delivery_test.dart' show clientWith, deliveryJson, patientOrderJson, respond;
import 'support/home_fakes.dart';

const _driverA = '33333333-3333-4333-8333-333333333333';
const _driverB = '44444444-4444-4444-8444-444444444444';

Map<String, dynamic> _reporteJson({int count = 4}) => {
      'days': 30,
      'since': '2026-10-14T12:00:00.000Z',
      'count': count,
      'average': count == 0 ? null : 3.5,
      'distribution': {'1': 1, '2': 0, '3': 1, '4': 0, '5': count == 0 ? 0 : 2},
      'drivers': count == 0
          ? []
          : [
              {'driverId': _driverB, 'count': 2, 'average': 2, 'low': 1, 'lastRatedAt': '2026-11-12T10:00:00.000Z'},
              {'driverId': _driverA, 'count': 2, 'average': 5, 'low': 0, 'lastRatedAt': '2026-11-11T10:00:00.000Z'},
            ],
      'lowRatings': count == 0
          ? []
          : [
              {
                'deliveryId': 'd-9',
                'orderId': 'o-9',
                'driverId': _driverB,
                'stars': 1,
                'comment': 'Llegó abierto el paquete',
                'ratedAt': '2026-11-12T10:00:00.000Z',
              },
            ],
      'truncated': false,
    };

Map<String, dynamic> _usuarios() => {
      'users': [
        {
          'id': _driverB,
          'name': 'Luis Peña',
          'email': 'luis@correo.co',
          'role': 'DELIVERY_DRIVER',
          'provider': 'local',
          'emailVerified': true
        },
      ],
      'total': 1,
      'page': 1,
      'pageSize': 20,
    };

AdminRatingsController _controlador({int count = 4, bool nombresFallan = false, List<Uri>? pedidos}) =>
    AdminRatingsController(
      deliveries: DeliveryService(clientWith((r) async {
        pedidos?.add(r.url);
        return respond(_reporteJson(count: count), 200);
      })),
      admin: AdminService(
        auth: clientWith((r) async => nombresFallan ? respond({'message': 'x'}, 500) : respond(_usuarios(), 200)),
        orders: clientWith((_) async => respond({}, 200)),
      ),
    );

/// GPS con reloj manual.
class _GpsManual implements LocationSource {
  _GpsManual(this.reloj);

  final DateTime Function() reloj;

  @override
  Future<void> ensureReady() async {}

  @override
  Future<GpsFix> currentFix() async => GpsFix(point: const GeoPoint(4.665, -74.06), accuracy: 8, recordedAt: reloj());
}

void main() {
  group('calificaciones para el administrador', () {
    test('lee el reporte', () {
      final r = ReporteCalificaciones.fromJson(_reporteJson());
      expect(r.total, 4);
      expect(r.promedio, 3.5);
      expect(r.distribucion, [1, 0, 1, 0, 2]);
      expect(r.repartidores.first.repartidorId, _driverB);
      expect(r.malas.single.comentario, 'Llegó abierto el paquete');
      expect(ReporteCalificaciones.fromJson(_reporteJson(count: 0)).promedio, isNull);
    });

    test('el controlador pide la ventana elegida y pone nombres; sin Auth usa el id abreviado', () async {
      final pedidos = <Uri>[];
      final c = _controlador(pedidos: pedidos);
      await c.load();
      expect(c.error, isNull);
      expect(c.nombreDe(_driverB), 'Luis Peña');
      expect(c.nombreDe(_driverA), 'Repartidor •••• 3333');
      await c.setDias(7);
      expect(pedidos.map((u) => u.queryParameters['days']), ['30', '7']);

      final sinNombres = _controlador(nombresFallan: true);
      await sinNombres.load();
      expect(sinNombres.reporte, isNotNull);
      expect(sinNombres.nombreDe(_driverB), 'Repartidor •••• 4444');
    });

    testWidgets('muestra promedio, repartidores (peor primero) y las malas con su comentario', (tester) async {
      tester.view.physicalSize = const Size(600, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final vistas = <String>[];
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: AdminRatingsPage(controller: _controlador(), onVerEntrega: vistas.add, onBack: () {}),
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(find.text('3,5'), findsOneWidget);
      expect(find.text('Luis Peña'), findsWidgets);
      expect(find.text('1 mala'), findsOneWidget);
      expect(find.text('«Llegó abierto el paquete»'), findsOneWidget);
      // El peor promedio va primero.
      expect(tester.getTopLeft(find.text('2,0')).dy, lessThan(tester.getTopLeft(find.text('5,0')).dy));
      await tester.tap(find.text('Ver entrega'));
      expect(vistas, ['d-9']);
    });

    testWidgets('sin calificaciones lo dice', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: AdminRatingsPage(controller: _controlador(count: 0), onVerEntrega: (_) {}, onBack: () {}),
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(find.text('Aún no hay calificaciones'), findsOneWidget);
    });
  });

  group('ubicación del repartidor sin señal', () {
    test('guarda las que no salen y las envía en orden al volver; descarta las muy viejas', () async {
      var ahora = DateTime.utc(2026, 11, 13, 12);
      var conSenal = true;
      final enviadas = <String>[];
      final service = DeliveryService(clientWith((request) async {
        if (request.url.path.endsWith('/locations')) {
          if (!conSenal) throw http.ClientException('sin red');
          enviadas.add((jsonDecode(request.body) as Map)['recordedAt'] as String);
          return respond(
              {'accepted': true, 'reason': null, 'status': 'IN_TRANSIT', 'eta': '2026-11-13T12:30:00Z'}, 200);
        }
        return respond(deliveryJson(), 200);
      }));
      final c = DriverDeliveryController(
        deliveryId: 'd-1',
        deliveries: service,
        location: _GpsManual(() => ahora),
        interval: const Duration(hours: 1),
        now: () => ahora,
      );
      await c.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(enviadas, hasLength(1));

      // Se pierde la señal: tres ubicaciones quedan guardadas, sin error rojo.
      conSenal = false;
      for (var i = 0; i < 3; i++) {
        ahora = ahora.add(const Duration(seconds: 10));
        await c.sendNow();
      }
      expect(c.sinSenal, isTrue);
      expect(c.pendientesSinEnviar, 3);
      expect(c.locationError, isNull);
      expect(c.sharing, isTrue);

      // Vuelve la señal: salen las guardadas en orden y luego la actual.
      conSenal = true;
      ahora = ahora.add(const Duration(seconds: 10));
      await c.sendNow();
      expect(c.sinSenal, isFalse);
      expect(c.pendientesSinEnviar, 0);
      expect(enviadas, hasLength(5));
      expect(enviadas.skip(1).toList(), [...enviadas.skip(1)]..sort());

      // Tras un corte largo, las de más de 110 s ya no se intentan (el servidor las rechazaría).
      conSenal = false;
      ahora = ahora.add(const Duration(seconds: 10));
      await c.sendNow();
      ahora = ahora.add(const Duration(minutes: 5));
      conSenal = true;
      await c.sendNow();
      expect(enviadas, hasLength(6));
      expect(enviadas.last, ahora.toIso8601String());
      c.dispose();
    });

    test('no guarda más de 30', () async {
      var ahora = DateTime.utc(2026, 11, 13, 12);
      final c = DriverDeliveryController(
        deliveryId: 'd-1',
        deliveries: DeliveryService(clientWith((request) async {
          if (request.url.path.endsWith('/locations')) throw http.ClientException('sin red');
          return respond(deliveryJson(), 200);
        })),
        location: _GpsManual(() => ahora),
        interval: const Duration(hours: 1),
        now: () => ahora,
      );
      await c.start();
      for (var i = 0; i < 40; i++) {
        ahora = ahora.add(const Duration(seconds: 1));
        await c.sendNow();
      }
      expect(c.pendientesSinEnviar, DriverDeliveryController.maxPendientes);
      c.dispose();
    });
  });

  group('recordatorio para calificar', () {
    final ahora = DateTime.utc(2026, 11, 13, 12);
    Delivery entrega(String id, {String status = 'DELIVERED', int diasAtras = 1, bool calificada = false}) =>
        Delivery.fromJson({
          ...deliveryJson(status: status),
          'id': id,
          'statusTimestamps': {'DELIVERED': ahora.subtract(Duration(days: diasAtras)).toIso8601String()},
          'rating': calificada ? {'stars': 5, 'ratedAt': ahora.toIso8601String()} : null,
        });
    final pedido = PatientOrder.fromJson({...patientOrderJson(status: 'DELIVERED'), 'deliveryId': 'd-2'});

    test('elige la entrega recibida más reciente sin calificar, de los últimos 7 días', () {
      final r = elegirPorCalificar(
        entregas: [
          entrega('d-1', diasAtras: 3),
          entrega('d-2', diasAtras: 1),
          entrega('d-3', diasAtras: 0, calificada: true),
          entrega('d-4', status: 'IN_TRANSIT'),
          entrega('d-5', diasAtras: 9),
        ],
        pedidos: [pedido],
        ahora: ahora,
      );
      expect(r?.deliveryId, 'd-2');
      expect(r?.farmacia, 'Farmacia 72');
      expect(
        elegirPorCalificar(entregas: [entrega('d-5', diasAtras: 9)], pedidos: const [], ahora: ahora),
        isNull,
      );
    });

    testWidgets('el inicio del paciente lo muestra y abre la entrega', (tester) async {
      final abiertas = <String>[];
      await montarInicio(
        tester,
        role: 'PATIENT',
        name: 'Ana',
        ancho: 390,
        foco: const FocoVacio(),
        porCalificar: const PorCalificar(deliveryId: 'd-2', farmacia: 'Farmacia 72'),
        onCalificar: abiertas.add,
      );
      expect(find.text('¿Cómo estuvo tu entrega?'), findsOneWidget);
      expect(find.textContaining('Farmacia 72'), findsOneWidget);
      await tester.tap(find.text('Calificar'));
      expect(abiertas, ['d-2']);
    });
  });
}
