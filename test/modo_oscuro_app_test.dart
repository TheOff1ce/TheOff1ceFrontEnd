import 'package:farma_go/app/app.dart';
import 'package:farma_go/app/theme/farmago_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => FgModo.oscuro = false);

  testWidgets('la app sigue al sistema: claro, oscuro y de vuelta', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;

    await tester.pumpWidget(const FarmaGoApp());
    await tester.pump();
    final pantalla = find.byType(Scaffold).first;
    ThemeData tema() => Theme.of(tester.element(pantalla));
    expect(FgModo.oscuro, isFalse);
    expect(tema().brightness, Brightness.light);
    expect(tema().scaffoldBackgroundColor, const Color(0xFFF3F8FA));

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pump();
    expect(FgModo.oscuro, isTrue);
    expect(tema().brightness, Brightness.dark);
    expect(tema().scaffoldBackgroundColor, const Color(0xFF0C171D));

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pump();
    expect(tema().scaffoldBackgroundColor, const Color(0xFFF3F8FA));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });
}
