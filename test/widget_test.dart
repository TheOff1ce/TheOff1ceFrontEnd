import 'package:farma_go/app/theme/farmago_tokens.dart';
import 'package:farma_go/components/farmago/buttons.dart';
import 'package:farma_go/pages/home_page.dart';
import 'package:farma_go/pages/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Las pruebas usan la fuente Ahem (cada carácter mide el tamaño de la fuente), así que una medida
/// de desbordamiento sin la fuente real del proyecto no dice nada. Se carga Atkinson para medir.
Future<void> _cargarAtkinson() async {
  final cargador = FontLoader(FgText.family);
  for (final peso in [400, 500, 600, 700]) {
    cargador.addFont(rootBundle
        .load('assets/fonts/atkinson/AtkinsonHyperlegibleNext-$peso.ttf'));
  }
  await cargador.load();
}

void main() {
  testWidgets('landing leads a visitor to sign in', (tester) async {
    var openedLogin = false;
    await tester.pumpWidget(MaterialApp(
      home: LandingPage(onLogin: () => openedLogin = true, onRegister: () {}),
    ));
    expect(find.text('Tu medicamento, de la farmacia a tu puerta.'),
        findsOneWidget);
    // El botón del hero queda bajo el pliegue de 600 px: como un usuario, se desplaza hasta él.
    final boton = find.widgetWithText(FgButton, 'Iniciar sesión').first;
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    expect(openedLogin, isTrue);
  });

  for (final ancho in [360.0, 768.0, 1024.0, 1280.0, 1440.0]) {
    testWidgets('landing renders without overflow at ${ancho.toInt()} px',
        (tester) async {
      await tester.runAsync(_cargarAtkinson);
      tester.view.physicalSize = Size(ancho, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: LandingPage(onLogin: () {}, onRegister: () {}),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(FgButton, 'Crear cuenta'), findsWidgets);
    });
  }

  testWidgets('home action responds to an analysis selection', (tester) async {
    var openedAnalysis = false;
    await tester.pumpWidget(MaterialApp(
      home: HomeActionCard(
        featured: true,
        icon: Icons.document_scanner_outlined,
        title: 'Analizar fórmula',
        description: 'Lee tu fórmula.',
        onTap: () => openedAnalysis = true,
      ),
    ));
    await tester.tap(find.text('Analizar fórmula'));
    expect(openedAnalysis, isTrue);
  });

  testWidgets(
      'upcoming features are explained up front instead of looking clickable',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: HomeActionCard(
          icon: Icons.inventory_2_outlined,
          title: 'Mis medicamentos',
          description: 'Historial.'),
    ));
    expect(find.text('Pronto'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets(
      'landing actions keep the 48 px minimum touch target at phone and desktop widths',
      (tester) async {
    await tester.runAsync(_cargarAtkinson);
    for (final ancho in [360.0, 1280.0]) {
      tester.view.physicalSize = Size(ancho, 900);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
          MaterialApp(home: LandingPage(onLogin: () {}, onRegister: () {})));
      await tester.pumpAndSettle();
      for (final etiqueta in ['Iniciar sesión', 'Crear cuenta']) {
        final boton = find.widgetWithText(FgButton, etiqueta).first;
        expect(
            tester.getSize(boton).height, greaterThanOrEqualTo(FgSize.tapMin),
            reason: '$etiqueta a $ancho px');
      }
    }
    addTearDown(tester.view.reset);
  });

  for (final ancho in [360.0, 1280.0]) {
    testWidgets(
        'landing keeps layout at 150% text scale at ${ancho.toInt()} px',
        (tester) async {
      await tester.runAsync(_cargarAtkinson);
      tester.view.physicalSize = Size(ancho * 3, 1800);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: LandingPage(onLogin: () {}, onRegister: () {}),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('keyboard focus follows the reading order of the hero actions',
      (tester) async {
    await tester.runAsync(_cargarAtkinson);
    await tester.pumpWidget(MaterialApp(
      home: LandingPage(onLogin: () {}, onRegister: () {}),
    ));
    await tester.pumpAndSettle();
    String? etiquetaEnFoco() => FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<FgButton>()
        ?.label;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(etiquetaEnFoco(), 'Iniciar sesión');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(etiquetaEnFoco(), 'Crear cuenta');
  });

  testWidgets('the delivery selector switches the flow and its details',
      (tester) async {
    await tester.runAsync(_cargarAtkinson);
    tester.view.physicalSize = const Size(1280 * 3, 1800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        MaterialApp(home: LandingPage(onLogin: () {}, onRegister: () {})));
    await tester.pumpAndSettle();
    expect(find.text('Pendiente registrado'), findsOneWidget);
    expect(find.text('Tú, con una tarifa de conveniencia.'), findsNothing);
    final domicilio = find.widgetWithText(FgChip, 'Domicilio voluntario');
    await tester.ensureVisible(domicilio);
    await tester.pumpAndSettle();
    await tester.tap(domicilio);
    await tester.pumpAndSettle();
    expect(find.text('Pendiente registrado'), findsNothing);
    expect(find.text('Tú, con una tarifa de conveniencia.'), findsOneWidget);
  });

  for (final ancho in [360.0, 768.0, 1024.0, 1280.0, 1440.0]) {
    testWidgets('sections keep their reading order at ${ancho.toInt()} px',
        (tester) async {
      await tester.runAsync(_cargarAtkinson);
      tester.view.physicalSize = Size(ancho, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: LandingPage(onLogin: () {}, onRegister: () {}),
      ));
      await tester.pumpAndSettle();
      // Los títulos en el orden en que deben leerse. Cada uno debe quedar más abajo que el anterior.
      const titulos = [
        'Dos caminos, una misma red',
        'Así avanza un pendiente',
        'Pendiente OM-1042',
        'Quién participa',
        '¿Tu medicamento quedó pendiente?',
        'Lo que FarmaGo no decide',
      ];
      final alturas = [
        for (final titulo in titulos) tester.getTopLeft(find.text(titulo)).dy,
      ];
      for (var i = 1; i < alturas.length; i++) {
        expect(alturas[i], greaterThan(alturas[i - 1]),
            reason:
                '"${titulos[i]}" debe quedar debajo de "${titulos[i - 1]}" a $ancho px');
      }
    });
  }
}
