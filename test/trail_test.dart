import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/components/farmago/trail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fuentes_reales.dart';

const _etiquetas = ['Buscando repartidor', 'Repartidor asignado', 'Pedido recogido', 'En camino', 'Llegando', 'Entregado'];

void main() {
  testWidgets('trayecto en camino, capturado con la fuente real', (tester) async {
    await tester.runAsync(cargarFuentesReales);
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, 
      home: const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(24),
          child: FgTrail(etiquetas: _etiquetas, actual: 3),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await expectLater(find.byType(FgTrail), matchesGoldenFile('goldens/trail_en_camino.png'));
  });

  testWidgets('cada paso dice su estado con palabras, no solo con color', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, 
      home: const Scaffold(body: FgTrail(etiquetas: _etiquetas, actual: 3)),
    ));
    expect(find.text('Completado'), findsNWidgets(3));
    expect(find.text('En curso'), findsOneWidget);
    expect(find.text('Pendiente'), findsNWidgets(2));
  });

  testWidgets('el paso en curso es el único con su palabra destacada', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, 
      home: const Scaffold(body: FgTrail(etiquetas: _etiquetas, actual: 3)),
    ));
    final enCurso = tester.widget<Text>(find.text('En camino'));
    final pendiente = tester.widget<Text>(find.text('Llegando'));
    final completado = tester.widget<Text>(find.text('Buscando repartidor'));
    expect(enCurso.style?.fontWeight, FontWeight.w700);
    expect(pendiente.style?.fontWeight, isNot(FontWeight.w700));
    expect(completado.style?.fontWeight, FontWeight.w600);
  });

  testWidgets('un estado fuera de rango deja todos los pasos pendientes', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, 
      home: const Scaffold(body: FgTrail(etiquetas: _etiquetas, actual: -1)),
    ));
    expect(find.text('Pendiente'), findsNWidgets(6));
    expect(find.text('Completado'), findsNothing);
    expect(find.text('En curso'), findsNothing);
  });

  testWidgets('el trayecto anuncia cada paso con su estado para lectores de pantalla', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, 
      home: const Scaffold(body: FgTrail(etiquetas: _etiquetas, actual: 3)),
    ));
    expect(find.bySemanticsLabel('En camino. En curso'), findsOneWidget);
    expect(find.bySemanticsLabel('Buscando repartidor. Completado'), findsOneWidget);
    expect(find.bySemanticsLabel('Entregado. Pendiente'), findsOneWidget);
    semantics.dispose();
  });
}
