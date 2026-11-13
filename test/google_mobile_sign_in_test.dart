import 'package:farma_go/auth/auth_controller.dart';
import 'package:farma_go/auth/google_mobile_sign_in.dart';
import 'package:farma_go/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_controller_test.dart' show FakeAuthServer, controllerFor, me, session;

/// Google en la app móvil: deep link farmago://auth/callback y canje del código de un solo uso.
void main() {
  final code = 'a' * 43;

  group('lectura del deep link', () {
    test('toma el código del fragmento', () {
      expect(GoogleMobileSignIn.parse('farmago://auth/callback#code=$code').code, code);
    });

    test('un error de Auth llega como código de error', () {
      expect(GoogleMobileSignIn.parse('farmago://auth/callback?error=google_account_conflict').error,
          'google_account_conflict');
    });

    test('un código mal formado o de otro esquema cuenta como fallo', () {
      expect(GoogleMobileSignIn.parse('farmago://auth/callback#code=corto').error, 'google_failed');
      expect(GoogleMobileSignIn.parse('https://evil.example/auth/callback#code=$code').error, 'google_failed');
    });

    test('la URL de inicio pide el flujo de la app', () {
      expect(GoogleMobileSignIn.startUrl('https://auth.x').toString(), 'https://auth.x/auth/google?platform=app');
    });

    test('cerrar la pestaña no es un error', () async {
      final result = await GoogleMobileSignIn.authenticate('https://auth.x',
          open: ({required url, required callbackUrlScheme}) async =>
              throw PlatformException(code: 'CANCELED'));
      expect(result, isNull);
    });
  });

  testWidgets('el botón de Google sale en la app y el código abre la sesión', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final server = FakeAuthServer()
      ..on('google/exchange', session)
      ..on('me', me);
    final auth = controllerFor(server);
    await tester.pumpWidget(MaterialApp(
      home: LoginPage(
        auth: auth,
        onRegister: () {},
        onForgotPassword: () {},
        onBack: () {},
        googleMobile: () async => GoogleCallback.code(code),
      ),
    ));
    expect(find.text('Continuar con Google'), findsOneWidget);
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    expect(server.calls, containsAllInOrder(['google/exchange', 'me']));
    expect(auth.status, AuthStatus.authenticated);
    auth.dispose();
  });

  testWidgets('si Google falla se explica en la pantalla de acceso', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final auth = controllerFor(FakeAuthServer());
    await tester.pumpWidget(MaterialApp(
      home: LoginPage(
        auth: auth,
        onRegister: () {},
        onForgotPassword: () {},
        onBack: () {},
        googleMobile: () async => const GoogleCallback.error('google_failed'),
      ),
    ));
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    expect(auth.status, isNot(AuthStatus.authenticated));
    expect(find.byType(LoginPage), findsOneWidget);
    auth.dispose();
  });
}
