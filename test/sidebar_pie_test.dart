import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/components/farmago/shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// «Cerrar sesión» al pie de la barra lateral y la cuenta en la barra superior.
void main() {
  void tamano(WidgetTester tester, double ancho) {
    tester.view.physicalSize = Size(ancho, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<List<String>> montarBarra(WidgetTester tester, double ancho) async {
    tamano(tester, ancho);
    final eventos = <String>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: FgNavLateral(
        destinos: [FgDestino(icono: Icons.home_outlined, etiqueta: 'Inicio', seleccionado: true, onTap: () {})],
        pie: FgPieLateral(onCerrarSesion: () async => eventos.add('salir')),
        child: const Scaffold(body: SizedBox.shrink()),
      ),
    ));
    return eventos;
  }

  testWidgets('en escritorio «Cerrar sesión» queda al fondo de la barra, lejos de la navegación', (tester) async {
    final eventos = await montarBarra(tester, 1280);
    final salir = tester.getCenter(find.text('Cerrar sesión'));
    expect(salir.dy, greaterThan(tester.getCenter(find.text('Inicio')).dy + 400));
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pump();
    expect(eventos, ['salir']);
  });

  testWidgets('colapsada (tablet) deja el icono, con su nombre para lectores', (tester) async {
    final eventos = await montarBarra(tester, 900);
    expect(find.text('Cerrar sesión'), findsNothing);
    expect(find.byTooltip('Cerrar sesión'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pump();
    expect(eventos, ['salir']);
  });

  testWidgets('en móvil no hay barra lateral (la sesión se cierra desde Cuenta)', (tester) async {
    await montarBarra(tester, 390);
    expect(find.text('Cerrar sesión'), findsNothing);
  });

  Future<List<String>> montarChip(WidgetTester tester, double ancho) async {
    tamano(tester, ancho);
    final eventos = <String>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(child: FgCuentaChip(nombre: 'Julian Lopez', rol: 'Paciente', onTap: () => eventos.add('cuenta'))),
      ),
    ));
    return eventos;
  }

  testWidgets('la cuenta muestra inicial, nombre y rol, y abre «Mi cuenta»', (tester) async {
    final eventos = await montarChip(tester, 1280);
    expect(find.text('J'), findsOneWidget);
    expect(find.text('Julian Lopez'), findsOneWidget);
    expect(find.text('Paciente'), findsOneWidget);
    expect(find.bySemanticsLabel('Mi cuenta. Julian Lopez, Paciente'), findsOneWidget);
    await tester.tap(find.text('Julian Lopez'));
    expect(eventos, ['cuenta']);
  });

  testWidgets('en pantallas angostas la cuenta queda solo con la inicial', (tester) async {
    final eventos = await montarChip(tester, 900);
    expect(find.text('J'), findsOneWidget);
    expect(find.text('Julian Lopez'), findsNothing);
    await tester.tap(find.text('J'));
    expect(eventos, ['cuenta']);
  });
}
