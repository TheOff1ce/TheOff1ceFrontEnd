import 'dart:convert';

import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/hooks/patient_orders_controller.dart';
import 'package:farma_go/pages/request_delivery_page.dart';
import 'package:farma_go/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'delivery_test.dart' show clientWith, patientOrderJson, respond;

void main() {
  Future<({List<Map<String, dynamic>> sent, List<String> events})> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sent = <Map<String, dynamic>>[];
    final events = <String>[];
    final orders = OrderService(clientWith((request) async {
      sent.add(jsonDecode(request.body) as Map<String, dynamic>);
      return respond(patientOrderJson(), 201);
    }));
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: RequestDeliveryPage(
        controller: PatientOrdersController(orders),
        defaultAddress: 'Calle 92 # 15-30, Bogotá',
        onCreated: (_) => events.add('created'),
        onBack: () => events.add('back'),
      ),
    ));
    return (sent: sent, events: events);
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testWidgets('prefills the profile address and counts with the stepper', (tester) async {
    final r = await pump(tester);
    expect(find.text('Calle 92 # 15-30, Bogotá'), findsOneWidget);

    await tester.tap(find.byTooltip('Agregar uno'));
    await tester.tap(find.byTooltip('Agregar uno'));
    await tester.tap(find.byTooltip('Quitar uno'));
    await tester.pump();
    await tester.enterText(field('Nombre de la farmacia'), 'Farmacia 72');
    await tester.enterText(field('Dirección de la farmacia'), 'Calle 72 # 10-20');
    await tester.enterText(field('Medicamento o producto'), 'Acetaminofén 500 mg');
    await tester.tap(find.text('Pedir domicilio').last);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();

    expect(r.sent.single['deliveryAddress'], 'Calle 92 # 15-30, Bogotá');
    expect(r.sent.single['items'], [
      {'name': 'Acetaminofén 500 mg', 'quantity': 2},
    ]);
    expect(r.events, ['created']);
  });

  testWidgets('an incomplete form marks the fields and sends nothing', (tester) async {
    final r = await pump(tester);
    await tester.tap(find.text('Pedir domicilio').last);
    await tester.pump();
    expect(find.text('Escribe al menos 2 caracteres.'), findsWidgets);
    expect(find.text('Revisa los campos marcados en rojo.'), findsOneWidget);
    expect(r.sent, isEmpty);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('leaving with typed data asks first; an untouched form leaves at once', (tester) async {
    final r = await pump(tester);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(r.events, ['back']);

    await tester.enterText(field('Nombre de la farmacia'), 'Farmacia 72');
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('¿Salir sin pedir el domicilio?'), findsOneWidget);
    await tester.tap(find.text('Seguir editando'));
    await tester.pumpAndSettle();
    expect(r.events, ['back']);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    expect(r.events, ['back', 'back']);
  });
}
