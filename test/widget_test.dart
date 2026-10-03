// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:farma_go/pages/auth_pages.dart';
import 'package:farma_go/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('landing leads a visitor to sign in', (tester) async {
    var openedLogin = false;
    await tester.pumpWidget(MaterialApp(
      home: LandingPage(onLogin: () => openedLogin = true, onRegister: () {}),
    ));
    expect(
        find.text('Medicamentos a tiempo,\ncon trazabilidad.'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    final signIn = find.widgetWithText(FilledButton, 'Iniciar sesión');
    await tester.tap(signIn);
    expect(openedLogin, isTrue);
  });

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
}
