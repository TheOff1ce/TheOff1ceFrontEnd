import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/components/delivery_code.dart';
import 'package:farma_go/components/farmago/code_input.dart';
import 'package:farma_go/errors/app_error.dart';
import 'package:farma_go/errors/error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(theme: AppTheme.light, home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  test('formats the code in two groups for dictating', () {
    expect(formatDeliveryCode('482913'), '482 913');
    expect(formatDeliveryCode('12'), '12');
  });

  testWidgets('the driver sees the code big and what to do with it', (tester) async {
    await tester.pumpWidget(_app(const DriverDeliveryCodeCard(code: '482913', awaitingPatient: true)));
    expect(find.text('Código de entrega'), findsOneWidget);
    // Una casilla por dígito.
    expect(find.byType(FgCodeBoxes), findsOneWidget);
    expect(find.descendant(of: find.byType(FgCodeBoxes), matching: find.byType(Text)), findsNWidgets(6));
    expect(find.text('4'), findsOneWidget);
    expect(find.textContaining('lo escriba en su app'), findsOneWidget);
  });

  testWidgets('the patient must type 6 digits; a wrong code is marked on the field', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sent = <String>[];
    await tester.pumpWidget(_app(PatientConfirmDelivery(
      busy: false,
      onConfirm: (code) async {
        sent.add(code);
        return code == '482913'
            ? null
            : AppError(
                kind: AppErrorKind.validation,
                userMessage: ErrorMessages.deliveryCodeInvalid,
                retryable: false,
                code: 'DELIVERY_CODE_INVALID',
              );
      },
    )));
    final field = find.descendant(of: find.byType(FgCodeInput), matching: find.byType(TextField));

    await tester.enterText(field, '123');
    await tester.tap(find.text('Confirmar entrega'));
    await tester.pump();
    expect(find.text('Escribe los 6 dígitos que te dice el repartidor.'), findsOneWidget);
    expect(sent, isEmpty);

    await tester.enterText(field, '11a1111');
    expect(tester.widget<TextField>(field).controller!.text, '111111'); // digits only, max 6
    await tester.tap(find.text('Confirmar entrega'));
    await tester.pump();
    expect(sent, ['111111']);
    expect(find.text(ErrorMessages.deliveryCodeInvalid), findsOneWidget);

    await tester.enterText(field, '482913');
    await tester.tap(find.text('Confirmar entrega'));
    await tester.pump();
    expect(sent.last, '482913');
    expect(find.text(ErrorMessages.deliveryCodeInvalid), findsNothing);
  });
}
