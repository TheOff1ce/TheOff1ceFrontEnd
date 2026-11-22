import 'package:farma_go/app/apariencia.dart';
import 'package:farma_go/app/app.dart';
import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/app/theme/farmago_tokens.dart';
import 'package:farma_go/components/farmago/selector_apariencia.dart';
import 'package:farma_go/components/farmago/shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fuentes_reales.dart';

void main() {
  tearDown(() {
    AparienciaController.instancia.reiniciar();
    FgModo.oscuro = false;
  });

  test('automática sigue al dispositivo; clara y oscura lo ignoran', () {
    expect(Apariencia.automatica.oscuraCon(sistemaOscuro: true), isTrue);
    expect(Apariencia.automatica.oscuraCon(sistemaOscuro: false), isFalse);
    expect(Apariencia.clara.oscuraCon(sistemaOscuro: true), isFalse);
    expect(Apariencia.oscura.oscuraCon(sistemaOscuro: false), isTrue);
  });

  Future<List<String>> montarMenu(WidgetTester tester, {bool capturas = false}) async {
    if (capturas) await tester.runAsync(cargarFuentesReales);
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final eventos = <String>[];
    await tester.pumpWidget(ListenableBuilder(
      listenable: AparienciaController.instancia,
      builder: (context, _) {
        FgModo.oscuro = AparienciaController.instancia.valor == Apariencia.oscura;
        return MaterialApp(
          key: ValueKey(FgModo.oscuro),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: Scaffold(
            backgroundColor: FgColors.fondo,
            body: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FgCuentaChip(
                  nombre: 'Julian Lopez',
                  correo: 'julian@farmago.co',
                  rol: 'Administrador',
                  onTap: () => eventos.add('cuenta'),
                  onCerrarSesion: () async => eventos.add('salir'),
                ),
              ),
            ),
          ),
        );
      },
    ));
    return eventos;
  }

  testWidgets('tocar la foto abre el menú con los datos, Mi cuenta, Apariencia y Cerrar sesión', (tester) async {
    final eventos = await montarMenu(tester);
    expect(find.text('julian@farmago.co'), findsNothing);
    await tester.tap(find.text('Julian Lopez'));
    await tester.pumpAndSettle();
    expect(find.text('julian@farmago.co'), findsOneWidget);
    expect(find.text('Apariencia'), findsOneWidget);
    expect(find.text('Automática'), findsOneWidget);

    await tester.tap(find.text('Mi cuenta'));
    await tester.pumpAndSettle();
    expect(eventos, ['cuenta']);
    expect(find.text('julian@farmago.co'), findsNothing);

    await tester.tap(find.text('Julian Lopez'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(eventos, ['cuenta', 'salir']);
  });

  testWidgets('elegir Oscura cambia la app y queda marcada', (tester) async {
    await montarMenu(tester);
    await tester.tap(find.text('Julian Lopez'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oscura'));
    await tester.pumpAndSettle();
    expect(AparienciaController.instancia.valor, Apariencia.oscura);
    expect(FgModo.oscuro, isTrue);
  });

  testWidgets('el selector anuncia la opción elegida', (tester) async {
    final c = AparienciaController();
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: Scaffold(body: FgSelectorApariencia(controller: c))));
    final handle = tester.ensureSemantics();
    expect(tester.getSemantics(find.text('Automática')), matchesSemantics(
      label: 'Automática', isButton: true, isSelected: true, hasSelectedState: true,
      isInMutuallyExclusiveGroup: true, hasTapAction: true));
    await tester.tap(find.text('Clara'));
    await tester.pump();
    expect(c.valor, Apariencia.clara);
    handle.dispose();
  });

  testWidgets('la elección manda sobre el dispositivo en la app completa', (tester) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpWidget(const FarmaGoApp());
    await tester.pump();
    ThemeData tema() => Theme.of(tester.element(find.byType(Scaffold).first));
    expect(tema().brightness, Brightness.light);

    AparienciaController.instancia.elegir(Apariencia.oscura);
    await tester.pump();
    expect(tema().brightness, Brightness.dark);

    // Con «Oscura» elegida, que el dispositivo pase a claro no cambia nada.
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pump();
    expect(tema().brightness, Brightness.dark);

    AparienciaController.instancia.elegir(Apariencia.automatica);
    await tester.pump();
    expect(tema().brightness, Brightness.light);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });

  for (final oscuro in [false, true]) {
    testWidgets('captura: menú de la cuenta ${oscuro ? 'oscuro' : 'claro'}', (tester) async {
      if (oscuro) AparienciaController.instancia.elegir(Apariencia.oscura);
      await montarMenu(tester, capturas: true);
      await tester.tap(find.text('Julian Lopez'));
      await tester.pumpAndSettle();
      await expectLater(
          find.byType(MaterialApp), matchesGoldenFile('goldens/menu_cuenta_${oscuro ? 'oscuro' : 'claro'}.png'));
    });
  }
}
