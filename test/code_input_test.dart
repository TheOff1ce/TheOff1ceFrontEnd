import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/components/farmago/code_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child, {double width = 400}) async {
    tester.view.physicalSize = Size(width, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child))));
  }

  Finder boxText(String t) => find.descendant(of: find.byType(FgCodeInput), matching: find.text(t));

  testWidgets('shows one box per digit, digits only, and submits only when complete', (tester) async {
    final controller = TextEditingController();
    final submitted = <String>[];
    await pump(tester, FgCodeInput(controller: controller, label: 'Código', onSubmitted: submitted.add));
    final field = find.byType(TextField);

    await tester.enterText(field, '12a3');
    await tester.pump();
    expect(controller.text, '123');
    for (final d in ['1', '2', '3']) {
      expect(boxText(d), findsOneWidget);
    }
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, isEmpty); // incompleto: Enter no envía

    await tester.enterText(field, '4829137'); // pegado más largo: se queda con 6
    await tester.pump();
    expect(controller.text, '482913');
    expect(submitted, isEmpty); // no se envía solo al completar
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, ['482913']);
  });

  testWidgets('fits six boxes on a narrow phone and shows the error under them', (tester) async {
    await pump(tester, FgCodeInput(controller: TextEditingController(), label: 'Código', error: 'El código no coincide.'), width: 320);
    expect(tester.takeException(), isNull);
    expect(find.text('El código no coincide.'), findsOneWidget);
  });

  testWidgets('read-only boxes show a known code', (tester) async {
    await pump(tester, const FgCodeBoxes(code: '004213'));
    expect(find.text('0'), findsNWidgets(2));
    expect(find.bySemanticsLabel('Código 0 0 4 2 1 3'), findsOneWidget);
  });
}
