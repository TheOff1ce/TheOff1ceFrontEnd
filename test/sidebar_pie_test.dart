import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/components/farmago/shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pie de la barra lateral (web y tablet): quién tiene la sesión y «Cerrar sesión».
void main() {
  Future<({List<String> eventos})> montar(WidgetTester tester, double ancho, {bool cuentaActiva = false}) async {
    tester.view.physicalSize = Size(ancho, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final eventos = <String>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: FgNavLateral(
        destinos: [FgDestino(icono: Icons.home_outlined, etiqueta: 'Inicio', seleccionado: true, onTap: () {})],
        pie: FgPieLateral(
          nombre: 'Ana Gómez',
          rol: 'Paciente',
          cuentaActiva: cuentaActiva,
          onCuenta: () => eventos.add('cuenta'),
          onCerrarSesion: () async => eventos.add('salir'),
        ),
        child: const Scaffold(body: SizedBox.shrink()),
      ),
    ));
    return (eventos: eventos);
  }

  testWidgets('en escritorio muestra nombre, rol y «Cerrar sesión» al fondo de la barra', (tester) async {
    final r = await montar(tester, 1280);
    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(find.text('Paciente'), findsOneWidget);
    // El pie queda abajo, separado de la navegación.
    final salir = tester.getCenter(find.text('Cerrar sesión'));
    expect(salir.dy, greaterThan(tester.getCenter(find.text('Inicio')).dy + 400));

    await tester.tap(find.text('Ana Gómez'));
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pump();
    expect(r.eventos, ['cuenta', 'salir']);
  });

  testWidgets('colapsada (tablet) deja la inicial y el icono, con su nombre para lectores', (tester) async {
    final r = await montar(tester, 900);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsNothing);
    expect(find.byTooltip('Cerrar sesión'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pump();
    expect(r.eventos, ['salir']);
  });

  testWidgets('en móvil no hay barra lateral (la sesión se cierra desde Cuenta)', (tester) async {
    await montar(tester, 390);
    expect(find.text('Cerrar sesión'), findsNothing);
    expect(find.text('Ana Gómez'), findsNothing);
  });
}
