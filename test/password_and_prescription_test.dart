import 'dart:convert';

import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/auth/auth_controller.dart';
import 'package:farma_go/auth/auth_repository.dart';
import 'package:farma_go/errors/error_mapper.dart';
import 'package:farma_go/errors/error_messages.dart';
import 'package:farma_go/pages/change_password_page.dart';
import 'package:farma_go/types/analysis_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

class _Server {
  final requests = <http.Request>[];
  http.Response Function(http.Request) changePassword = (_) => _json({'status': 'password_changed', 'accessToken': 'token-2', 'expiresIn': 600});

  MockClient get client => MockClient((request) async {
        requests.add(request);
        return switch (request.url.path) {
          '/auth/refresh' => _json({'accessToken': 'token-1', 'expiresIn': 600}),
          '/auth/me' => _json({'id': 'p-1', 'email': 'ana@x.co', 'name': 'Ana', 'role': 'PATIENT'}),
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

  group('HU-039 change password screen', () {
    Future<_Server> pump(WidgetTester tester, {required VoidCallback onDone}) async {
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final server = _Server();
      final auth = AuthController(AuthRepository('https://auth.x', client: server.client, usesBrowserCookies: true));
      await tester.runAsync(auth.restore);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: ChangePasswordPage(auth: auth, onBack: () {}, onDone: onDone),
      ));
      return server;
    }

    testWidgets('validates every field before calling the server', (tester) async {
      final server = await pump(tester, onDone: () {});
      await tester.tap(find.text('Cambiar contraseña'));
      await tester.pump();
      expect(find.text('Escribe tu contraseña actual.'), findsOneWidget);
      expect(find.text('La contraseña debe tener al menos 8 caracteres.'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Actual123!');
      await tester.enterText(find.byType(TextFormField).at(1), 'Actual123!');
      await tester.enterText(find.byType(TextFormField).at(2), 'Otra123!!');
      await tester.tap(find.text('Cambiar contraseña'));
      await tester.pump();
      expect(find.text('La contraseña nueva debe ser distinta de la actual.'), findsOneWidget);
      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
      expect(server.requests.where((r) => r.url.path == '/auth/change-password'), isEmpty);
    });

    testWidgets('a valid form changes the password and returns', (tester) async {
      var done = false;
      final server = await pump(tester, onDone: () => done = true);
      await tester.enterText(find.byType(TextFormField).at(0), 'Actual123!');
      await tester.enterText(find.byType(TextFormField).at(1), 'Nueva456!');
      await tester.enterText(find.byType(TextFormField).at(2), 'Nueva456!');
      await tester.runAsync(() async {
        await tester.tap(find.text('Cambiar contraseña'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(server.requests.where((r) => r.url.path == '/auth/change-password'), hasLength(1));
      expect(done, isTrue);
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
