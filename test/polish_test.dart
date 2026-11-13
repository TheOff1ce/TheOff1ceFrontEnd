import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/app/theme/farmago_tokens.dart';
import 'package:farma_go/components/farmago/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:farma_go/hooks/patient_home_controller.dart';
import 'support/home_fakes.dart';

void main() {
  testWidgets('el botón se reduce a 0.98 mientras se presiona y vuelve a 1 al soltar', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, 
      home: Scaffold(body: Center(child: FgButton(label: 'Guardar', onPressed: () {}))),
    ));
    AnimatedScale escala() => tester.widget<AnimatedScale>(find.byType(AnimatedScale).first);

    expect(escala().scale, 1);
    final gesto = await tester.startGesture(tester.getCenter(find.byType(FgButton)));
    await tester.pump();
    expect(escala().scale, FgMotion.escalaPresion);
    await gesto.up();
    await tester.pump();
    expect(escala().scale, 1);
  });

  testWidgets('un botón deshabilitado no se reduce al presionar', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, 
      home: const Scaffold(body: Center(child: FgButton(label: 'Guardar', onPressed: null))),
    ));
    final gesto = await tester.startGesture(tester.getCenter(find.byType(FgButton)));
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale).first).scale, 1);
    await gesto.up();
  });

  testWidgets('un destino de la barra lateral se reduce a 0.98 al presionarlo', (tester) async {
    await montarInicio(tester, role: 'PATIENT', name: 'Ana', ancho: 1280, foco: const FocoVacio());
    final destino = find.ancestor(of: find.text('Mis domicilios'), matching: find.byType(AnimatedScale));
    final gesto = await tester.startGesture(tester.getCenter(find.text('Mis domicilios')));
    await tester.pump();
    expect(tester.widget<AnimatedScale>(destino.first).scale, FgMotion.escalaPresion);
    await gesto.up();
    await tester.pump();
    expect(tester.widget<AnimatedScale>(destino.first).scale, 1);
  });
}
