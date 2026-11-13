import 'dart:convert';

import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/components/abrir_navegacion.dart';
import 'package:farma_go/components/calificar_entrega.dart';
import 'package:farma_go/errors/app_error.dart';
import 'package:farma_go/errors/error_messages.dart';
import 'package:farma_go/hooks/eps_resumen_controller.dart';
import 'package:farma_go/hooks/patient_orders_controller.dart';
import 'package:farma_go/pages/request_delivery_page.dart';
import 'package:farma_go/pages/result_page.dart';
import 'package:farma_go/services/delivery_service.dart';
import 'package:farma_go/services/order_service.dart';
import 'package:farma_go/types/analysis_response.dart';
import 'package:farma_go/types/delivery.dart';
import 'package:farma_go/types/order.dart';
import 'package:farma_go/types/pendiente.dart';
import 'package:farma_go/utils/pedido_desde_formula.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'delivery_test.dart' show clientWith, deliveryJson, patientOrderJson, respond;
import 'pendientes_test.dart' show ok, paginaJson, resumenJson, serviceWith;

Widget _app(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void _alto(WidgetTester tester, {double ancho = 600}) {
  tester.view.physicalSize = Size(ancho, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

AnalysisResponse _analisis() => AnalysisResponse.fromJson({
      'medications': [
        {'name': 'Metformina', 'concentration': '850 mg', 'quantity': '60', 'confidence': 0.94},
        {'name': null, 'confidence': 0.3, 'requires_review': true},
        {'name': 'Losartán <b>', 'concentration': '50 mg', 'confidence': 0.6},
        {'name': 'metformina', 'concentration': '850 MG', 'confidence': 0.9},
      ],
    });

void main() {
  group('del análisis a «Pedir a casa»', () {
    test('solo los legibles, con concentración, cantidad 1, sin repetidos ni caracteres no válidos', () {
      final items = pedidoDesdeFormula(_analisis());
      expect([for (final i in items) i.name], ['Metformina 850 mg', 'Losartán b 50 mg']);
      expect(items.every((i) => i.quantity == 1), isTrue);
      expect(pedidoDesdeFormula(AnalysisResponse.fromJson({'medications': []})), isEmpty);
    });

    testWidgets('el resultado ofrece pedirlos a casa como acción principal y los envía', (tester) async {
      _alto(tester);
      List<OrderItem>? enviados;
      await tester.pumpWidget(_app(ResultPage(
        result: _analisis(),
        onHome: () {},
        onAnalyzeAnother: () {},
        onRequestDelivery: (items) => enviados = items,
      )));
      await tester.tap(find.text('Pedir estos medicamentos a casa'));
      expect(enviados?.map((i) => i.name), ['Metformina 850 mg', 'Losartán b 50 mg']);
    });

    testWidgets('sin el callback (otros roles) no aparece', (tester) async {
      _alto(tester);
      await tester.pumpWidget(_app(ResultPage(result: _analisis(), onHome: () {}, onAnalyzeAnother: () {})));
      expect(find.textContaining('a casa'), findsNothing);
      expect(find.text('Analizar otra fórmula'), findsOneWidget);
    });

    testWidgets('el formulario llega con los productos escritos y avisa que se revisen', (tester) async {
      _alto(tester, ancho: 900);
      final enviados = <Map<String, dynamic>>[];
      final orders = OrderService(clientWith((request) async {
        enviados.add(jsonDecode(request.body) as Map<String, dynamic>);
        return respond(patientOrderJson(), 201);
      }));
      await tester.pumpWidget(_app(RequestDeliveryPage(
        controller: PatientOrdersController(orders),
        defaultAddress: 'Calle 92 # 15-30, Bogotá',
        initialItems: const [
          OrderItem(name: 'Metformina 850 mg', quantity: 1),
          OrderItem(name: 'Losartán 50 mg', quantity: 2)
        ],
        onCreated: (_) {},
        onBack: () {},
      )));
      expect(find.text('Agregamos los medicamentos de tu fórmula'), findsOneWidget);
      expect(find.text('Metformina 850 mg'), findsOneWidget);
      expect(find.text('Losartán 50 mg'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Nombre de la farmacia'), 'Farmacia 72');
      await tester.enterText(find.widgetWithText(TextFormField, 'Dirección de la farmacia'), 'Calle 72 # 10-20');
      await tester.tap(find.text('Pedir domicilio').last);
      await tester.pumpAndSettle();
      expect(enviados.single['items'], [
        {'name': 'Metformina 850 mg', 'quantity': 1},
        {'name': 'Losartán 50 mg', 'quantity': 2},
      ]);
    });
  });

  group('abrir en Google Maps / Waze', () {
    final entrega = Delivery.fromJson(deliveryJson(status: 'ASSIGNED'));

    test('va a la farmacia hasta recoger y luego a la casa; nada si terminó', () {
      expect(NavegacionExterna.destinoActual(entrega)?.address, 'Farmacia');
      expect(NavegacionExterna.destinoActual(Delivery.fromJson(deliveryJson()))?.address, 'Casa');
      expect(NavegacionExterna.destinoActual(Delivery.fromJson(deliveryJson(status: 'DELIVERED'))), isNull);
      expect(NavegacionExterna.destinoActual(Delivery.fromJson(deliveryJson(status: 'CREATED'))), isNull);
    });

    test('arma los enlaces con las coordenadas', () {
      const p = GeoPoint(4.68, -74.06);
      expect(
        NavegacionExterna.googleMaps(p).toString(),
        'https://www.google.com/maps/dir/?api=1&destination=4.68%2C-74.06&travelmode=driving',
      );
      expect(NavegacionExterna.waze(p).toString(), 'https://waze.com/ul?ll=4.68%2C-74.06&navigate=yes');
    });

    testWidgets('cada botón abre su app; si falla, lo dice', (tester) async {
      final abiertos = <Uri>[];
      var resultado = true;
      await tester.pumpWidget(_app(Scaffold(
        body: AbrirNavegacion(
          delivery: entrega,
          abrir: (uri) async {
            abiertos.add(uri);
            return resultado;
          },
        ),
      )));
      expect(find.text('Cómo llegar a la farmacia'), findsOneWidget);
      await tester.tap(find.text('Abrir en Google Maps'));
      await tester.tap(find.text('Abrir en Waze'));
      expect(abiertos.map((u) => u.host), ['www.google.com', 'waze.com']);
      expect(abiertos.first.queryParameters['destination'], '4.66,-74.06');

      resultado = false;
      await tester.tap(find.text('Abrir en Waze'));
      await tester.pump();
      expect(find.textContaining('No pudimos abrir la app de mapas'), findsOneWidget);
    });
  });

  group('panel de la EPS', () {
    // Límite 26 oct 15:15 UTC. Evaluado 05:15 -> quedan 10 h (por vencer); 00:00 -> 39 h.
    Map<String, dynamic> vigente(String id, String evaluado) =>
        resumenJson(id: id, orden: 'PED-$id', evaluadoEn: evaluado);

    PaginaPendientes pagina(List<Map<String, dynamic>> items, {int? total}) =>
        PaginaPendientes.fromJson(paginaJson(items, limite: 100, total: total));

    test('cuenta por vencer, vencidos sin entregar, vigentes y el porcentaje a tiempo', () {
      final r = ResumenEps.de(
        pendientes: pagina([
          vigente('a', '2026-10-26T05:15:00.000Z'),
          vigente('b', '2026-10-26T13:15:00.000Z'),
          vigente('c', '2026-10-25T00:00:00.000Z'),
          resumenJson(id: 'd', cumplimiento: 'INCUMPLIDO', evaluadoEn: '2026-10-27T00:00:00.000Z'),
        ], total: 150),
        entregados: pagina([
          for (final (i, c) in ['CUMPLIDO', 'CUMPLIDO', 'CUMPLIDO', 'INCUMPLIDO'].indexed)
            resumenJson(
                id: 'e$i', estadoEntrega: 'ENTREGADO', cumplimiento: c, fechaEntrega: '2026-10-25T10:00:00.000Z'),
        ]),
      );
      expect(r.porVencer, 2);
      expect(r.vencidosSinEntregar, 1);
      expect(r.vigentes, 3);
      expect(r.porcentajeATiempo, 75);
      // El que vence primero (2 h) va arriba.
      expect(r.urgentes.map((p) => p.id), ['b', 'a']);
      expect(r.parcial, isTrue);
    });

    test('sin entregas no inventa un porcentaje', () {
      final r = ResumenEps.de(pendientes: pagina([]), entregados: pagina([]));
      expect(r.porcentajeATiempo, isNull);
      expect(r.parcial, isFalse);
    });

    test('el controlador pide pendientes y entregados (100 de cada uno)', () async {
      final pedidos = <Uri>[];
      final service = serviceWith((request) async {
        pedidos.add(request.url);
        final entregado = request.url.queryParameters['estadoEntrega'] == 'ENTREGADO';
        return ok(paginaJson([
          entregado
              ? resumenJson(
                  estadoEntrega: 'ENTREGADO', cumplimiento: 'CUMPLIDO', fechaEntrega: '2026-10-25T10:00:00.000Z')
              : vigente('a', '2026-10-26T05:15:00.000Z'),
        ], limite: 100));
      });
      final c = EpsResumenController(service);
      await c.load();
      expect(c.error, isNull);
      expect(c.resumen?.porVencer, 1);
      expect(c.resumen?.porcentajeATiempo, 100);
      expect(pedidos.map((u) => u.queryParameters['estadoEntrega']).toSet(), {'PENDIENTE', 'ENTREGADO'});
      expect(pedidos.every((u) => u.queryParameters['limite'] == '100'), isTrue);
    });

    test('si falla, guarda el error para mostrar «Reintentar»', () async {
      final c = EpsResumenController(serviceWith((_) async => http.Response('{"message":"x"}', 500)));
      await c.load();
      expect(c.resumen, isNull);
      expect(c.error, isNotNull);
      expect(c.loading, isFalse);
    });
  });

  group('calificar la entrega', () {
    test('la entrega trae la calificación (solo las estrellas)', () {
      final sin = Delivery.fromJson({...deliveryJson(status: 'DELIVERED'), 'rating': null});
      expect(sin.canBeRated, isTrue);
      final con = Delivery.fromJson({
        ...deliveryJson(status: 'DELIVERED'),
        'rating': {'stars': 4, 'ratedAt': '2026-10-23T16:00:00.000Z'},
      });
      expect(con.rating?.stars, 4);
      expect(con.canBeRated, isFalse);
      expect(Delivery.fromJson(deliveryJson()).canBeRated, isFalse);
      expect(DeliveryRating.fromJson({'stars': 9}), isNull);
    });

    test('el servicio envía estrellas y el comentario solo si hay texto', () async {
      final cuerpos = <Map<String, dynamic>>[];
      final rutas = <String>[];
      final service = DeliveryService(clientWith((request) async {
        rutas.add(request.url.path);
        cuerpos.add(jsonDecode(request.body) as Map<String, dynamic>);
        return respond({
          ...deliveryJson(status: 'DELIVERED'),
          'rating': {'stars': 5, 'ratedAt': '2026-10-23T16:00:00.000Z'},
        }, 200);
      }));
      final d = await service.rate('d-1', 5, comment: '  Muy amable ');
      await service.rate('d-1', 3, comment: '   ');
      expect(d.rating?.stars, 5);
      expect(rutas.first, endsWith('/deliveries/d-1/rating'));
      expect(cuerpos, [
        {'stars': 5, 'comment': 'Muy amable'},
        {'stars': 3},
      ]);
    });

    testWidgets('pide elegir estrellas, envía la elección y muestra el error del servicio', (tester) async {
      _alto(tester, ancho: 400);
      final llamadas = <(int, String?)>[];
      AppError? respuesta = AppError(
        kind: AppErrorKind.conflict,
        userMessage: ErrorMessages.alreadyRated,
        retryable: false,
      );
      await tester.pumpWidget(_app(Scaffold(
        body: SingleChildScrollView(
          child: CalificarEntrega(
            rating: null,
            busy: false,
            onRate: (stars, comment) async {
              llamadas.add((stars, comment));
              return respuesta;
            },
          ),
        ),
      )));
      await tester.tap(find.text('Enviar calificación'));
      await tester.pump();
      expect(find.text('Toca de 1 a 5 estrellas.'), findsOneWidget);
      expect(llamadas, isEmpty);

      await tester.tap(find.byTooltip('4 estrellas: Buena'));
      await tester.pump();
      expect(find.text('Buena'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Llegó rápido');
      await tester.tap(find.text('Enviar calificación'));
      await tester.pump();
      expect(llamadas, [(4, 'Llegó rápido')]);
      expect(find.text(ErrorMessages.alreadyRated), findsOneWidget);
      respuesta = null;
    });

    testWidgets('ya calificada: agradece y muestra sus estrellas', (tester) async {
      await tester.pumpWidget(_app(Scaffold(
        body: CalificarEntrega(
          rating: const DeliveryRating(stars: 5),
          busy: false,
          onRate: (_, __) async => null,
        ),
      )));
      expect(find.text('¡Gracias por calificar!'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == '5 de 5 estrellas'), findsOneWidget);
      expect(find.text('Enviar calificación'), findsNothing);
    });
  });
}
