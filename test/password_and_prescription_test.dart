import 'dart:convert';

import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/auth/auth_controller.dart';
import 'package:farma_go/auth/auth_repository.dart';
import 'package:farma_go/errors/error_mapper.dart';
import 'package:farma_go/errors/error_messages.dart';
import 'package:farma_go/pages/account_page.dart';
import 'package:farma_go/types/analysis_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

const _meJson = <String, dynamic>{
  'id': 'p-1',
  'email': 'ana@x.co',
  'name': 'Ana Pérez',
  'role': 'PATIENT',
  'provider': 'LOCAL',
  'emailVerified': true,
  'createdAt': '2026-10-01T15:00:00.000Z',
  'lastLoginAt': '2026-11-05T20:30:00.000Z',
};

class _Server {
  final requests = <http.Request>[];
  Map<String, dynamic>? me;
  http.Response Function(http.Request) changePassword = (_) => _json({'status': 'password_changed', 'accessToken': 'token-2', 'expiresIn': 600});

  MockClient get client => MockClient((request) async {
        requests.add(request);
        return switch (request.url.path) {
          '/auth/refresh' => _json({'accessToken': 'token-1', 'expiresIn': 600}),
          '/auth/me' => _json(me ?? _meJson),
          '/auth/change-password' => changePassword(request),
          _ => _json({}, 404),
        };
      });
}

Future<AuthController> _signedIn(_Server server) async {
  final auth = AuthController(AuthRepository('https://auth.x', client: server.client, usesBrowserCookies: true));
  await auth.restore();
  return auth;
}

void main() {
  group('HU-005 change password', () {
    test('sends both passwords with the Bearer token and keeps the session with the new token', () async {
      final server = _Server();
      final auth = await _signedIn(server);
      expect(await auth.changePassword(currentPassword: 'Actual123!', newPassword: 'Nueva456!'), isNull);
      final request = server.requests.firstWhere((r) => r.url.path == '/auth/change-password');
      expect(request.headers['Authorization'], 'Bearer token-1');
      expect(jsonDecode(request.body), {'currentPassword': 'Actual123!', 'newPassword': 'Nueva456!'});
      expect(auth.accessToken, 'token-2');
      expect(auth.isAuthenticated, isTrue);
      auth.dispose();
    });

    test('a wrong current password shows a clear message and keeps the session', () async {
      final server = _Server()
        ..changePassword = (_) => _json({'success': false, 'error': {'code': 'CURRENT_PASSWORD_INVALID', 'message': 'x'}}, 400);
      final auth = await _signedIn(server);
      final error = await auth.changePassword(currentPassword: 'mal', newPassword: 'Nueva456!');
      expect(error?.userMessage, ErrorMessages.currentPasswordInvalid);
      expect(auth.isAuthenticated, isTrue);
      auth.dispose();
    });

    test('Google accounts get an explanation', () {
      final error = ErrorMapper.fromAuth(409, const {'error': {'code': 'PASSWORD_NOT_SET'}});
      expect(error.userMessage, ErrorMessages.passwordNotSet);
    });
  });

  group('HU-039 account page with inline password change', () {
    Future<(_Server, AuthController)> pump(WidgetTester tester, {Map<String, dynamic>? me}) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final server = _Server()..me = me;
      final auth = AuthController(AuthRepository('https://auth.x', client: server.client, usesBrowserCookies: true));
      await tester.runAsync(auth.restore);
      await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: AccountPage(auth: auth, onBack: () {})));
      await tester.pump();
      return (server, auth);
    }

    testWidgets('shows the account data', (tester) async {
      await pump(tester);
      expect(find.text('Ana Pérez'), findsWidgets);
      expect(find.text('ana@x.co'), findsWidgets);
      expect(find.text('Verificado'), findsOneWidget);
      expect(find.text('Forma de ingreso'), findsNothing);
      expect(find.text('1 oct 2026'), findsOneWidget);
      expect(find.text('AP'), findsOneWidget);
      expect(find.text('Cambiar contraseña'), findsOneWidget);
    });

    testWidgets('Google accounts explain there is no password to change', (tester) async {
      await pump(tester, me: {..._meJson, 'provider': 'GOOGLE'});
      expect(find.text('Cambiar contraseña'), findsNothing);
      expect(find.textContaining('desde tu cuenta de Google'), findsOneWidget);
    });

    testWidgets('validates every field before calling the server', (tester) async {
      final (server, _) = await pump(tester);
      await tester.tap(find.text('Cambiar contraseña'));
      await tester.pumpAndSettle();
        await tester.tap(find.text('Guardar contraseña'));
      await tester.pumpAndSettle();
      expect(find.text('Escribe tu contraseña actual.'), findsOneWidget);
      expect(find.text('La contraseña debe tener al menos 8 caracteres.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Actual123!');
      await tester.enterText(find.byType(TextField).at(1), 'Actual123!');
      await tester.enterText(find.byType(TextField).at(2), 'Otra123!!');
      await tester.pumpAndSettle();
        await tester.tap(find.text('Guardar contraseña'));
      await tester.pump();
      expect(find.text('La contraseña nueva debe ser distinta de la actual.'), findsOneWidget);
      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
      expect(server.requests.where((r) => r.url.path == '/auth/change-password'), isEmpty);
    });

    testWidgets('a wrong current password is marked on that field', (tester) async {
      final (server, _) = await pump(tester);
      server.changePassword =
          (_) => _json({'success': false, 'error': {'code': 'CURRENT_PASSWORD_INVALID', 'message': 'x'}}, 400);
      await tester.tap(find.text('Cambiar contraseña'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Mala123!!');
      await tester.enterText(find.byType(TextField).at(1), 'Nueva456!');
      await tester.enterText(find.byType(TextField).at(2), 'Nueva456!');
      await tester.runAsync(() async {
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guardar contraseña'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(find.text(ErrorMessages.currentPasswordInvalid), findsOneWidget);
      expect(find.text('Guardar contraseña'), findsOneWidget, reason: 'the form stays open');
    });

    testWidgets('a valid form changes the password and closes the form', (tester) async {
      final (server, auth) = await pump(tester);
      await tester.tap(find.text('Cambiar contraseña'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Actual123!');
      await tester.enterText(find.byType(TextField).at(1), 'Nueva456!');
      await tester.enterText(find.byType(TextField).at(2), 'Nueva456!');
      await tester.runAsync(() async {
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guardar contraseña'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(server.requests.where((r) => r.url.path == '/auth/change-password'), hasLength(1));
      expect(find.text('Guardar contraseña'), findsNothing);
      expect(find.textContaining('Contraseña cambiada'), findsOneWidget);
      expect(auth.accessToken, 'token-2');
      await tester.pump(const Duration(seconds: 7));
    });
  });

  group('HU-031 prescription result', () {
    test('reads the patient and whether the document was stored', () {
      final result = AnalysisResponse.fromJson({
        'patient': {'name': 'Ana Pérez', 'document_type': 'CC', 'document_number': '1020304050'},
        'medications': [
          {'name': 'Acetaminofén', 'confidence': 0.9},
        ],
        'document': {'id': 'd1', 'path': 'prescriptions/p/2026/11/d1.jpg', 'stored_at': '2026-11-05T00:00:00Z'},
      });
      expect(result.patient?.name, 'Ana Pérez');
      expect(result.patient?.document, 'CC 1020304050');
      expect(result.documentStored, isTrue);
      final restored = AnalysisResponse.fromJson(result.toJson());
      expect(restored.patient?.name, 'Ana Pérez');
      expect(restored.documentStored, isTrue);
    });

    test('older answers without patient or document still work', () {
      final result = AnalysisResponse.fromJson({'medications': []});
      expect(result.patient, isNull);
      expect(result.documentStored, isFalse);
    });

    test('an unreadable photo asks for another one', () {
      final error = ErrorMapper.fromAi(422, const {'error': {'code': 'UNREADABLE_PRESCRIPTION'}});
      expect(error.userMessage, ErrorMessages.unreadablePrescription);
      expect(error.retryable, isFalse);
    });
  });
}
