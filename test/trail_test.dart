import 'dart:io';

import 'package:farma_go/components/farmago/trail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Carga la fuente real del proyecto y, si existe en esta máquina, la fuente de iconos de Material
/// del SDK, para que las capturas muestren checks y no cuadros.
Future<void> _cargarFuentes() async {
  final cargador = FontLoader('Atkinson Hyperlegible Next');
  for (final peso in [400, 500, 600, 700]) {
    cargador.addFont(rootBundle.load('assets/fonts/atkinson/AtkinsonHyperlegibleNext-$peso.ttf'));
  }
  await cargador.load();

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final iconos = <String>[
    if (flutterRoot != null) '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    if (flutterRoot != null) '$flutterRoot/bin/cache/dart-sdk/bin/resources/devtools/assets/fonts/MaterialIcons-Regular.otf',
    r'C:\Users\NIKOL\Downloads\flutter\bin\cache\dart-sdk\bin\resources\devtools\assets\fonts\MaterialIcons-Regular.otf',
  ].map(File.new).firstWhere(
        (archivo) => archivo.existsSync(),
        orElse: () => File(''),
      );
  if (iconos.path.isNotEmpty) {
    final cargadorIconos = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(iconos.readAsBytesSync().buffer)));
    await cargadorIconos.load();
  }
}

const _etiquetas = ['Buscando repartidor', 'Repartidor asignado', 'Pedido recogido', 'En camino', 'Llegando', 'Entregado'];

void main() {
  testWidgets('trayecto en camino, capturado con la fuente real', (tester) async {
    await tester.runAsync(_cargarFuentes);
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
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
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FgTrail(etiquetas: _etiquetas, actual: 3)),
    ));
    expect(find.text('Completado'), findsNWidgets(3));
    expect(find.text('En curso'), findsOneWidget);
    expect(find.text('Pendiente'), findsNWidgets(2));
  });

  testWidgets('el paso en curso es el único con su palabra destacada', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FgTrail(etiquetas: _etiquetas, actual: 3)),
    ));
    final enCurso = tester.widget<Text>(find.text('En camino'));
    final pendiente = tester.widget<Text>(find.text('Llegando'));
    final completado = tester.widget<Text>(find.text('Buscando repartidor'));
    expect(enCurso.style?.fontWeight, FontWeight.w700);
    expect(pendiente.style?.fontWeight, isNot(FontWeight.w700));
    expect(completado.style?.fontWeight, FontWeight.w600);
  });

  testWidgets('un estado fuera de rango deja todos los pasos pendientes', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FgTrail(etiquetas: _etiquetas, actual: -1)),
    ));
    expect(find.text('Pendiente'), findsNWidgets(6));
    expect(find.text('Completado'), findsNothing);
    expect(find.text('En curso'), findsNothing);
  });

  testWidgets('el trayecto anuncia cada paso con su estado para lectores de pantalla', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FgTrail(etiquetas: _etiquetas, actual: 3)),
    ));
    expect(find.bySemanticsLabel('En camino. En curso'), findsOneWidget);
    expect(find.bySemanticsLabel('Buscando repartidor. Completado'), findsOneWidget);
    expect(find.bySemanticsLabel('Entregado. Pendiente'), findsOneWidget);
    semantics.dispose();
  });
}
