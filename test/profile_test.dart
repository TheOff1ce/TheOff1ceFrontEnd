import 'dart:convert';

import 'package:farma_go/app/app_router.dart';
import 'package:farma_go/app/app_routes.dart';
import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/auth/auth_controller.dart';
import 'package:farma_go/auth/auth_repository.dart';
import 'package:farma_go/components/account/profile_form.dart';
import 'package:farma_go/components/farmago/inputs.dart';
import 'package:farma_go/errors/error_messages.dart';
import 'package:farma_go/pages/account_page.dart';
import 'package:farma_go/pages/complete_profile_page.dart';
import 'package:farma_go/types/auth_models.dart';
import 'package:farma_go/types/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

const _emptyProfile = <String, dynamic>{
  'documentType': null,
  'documentNumber': null,
  'phone': null,
  'birthDate': null,
  'eps': null,
  'address': null,
  'vehicleType': null,
  'vehiclePlate': null,
  'organization': null,
  'position': null,
  'dataConsentAt': null,
};

Map<String, dynamic> _me({
  String role = 'PATIENT',
  Map<String, dynamic> profile = const {},
  bool complete = false,
}) =>
    {
      'id': 'p-1',
      'email': 'ana@x.co',
      'name': 'Ana Pérez',
      'role': role,
      'provider': 'GOOGLE',
      'emailVerified': true,
      'createdAt': '2026-10-01T15:00:00.000Z',
      'lastLoginAt': null,
      'profile': {..._emptyProfile, ...profile},
      'profileComplete': complete,
      'profileMissing': complete ? <String>[] : ['documentType'],
    };

const _completePatient = {
  'documentType': 'CC',
  'documentNumber': '1020304050',
  'phone': '3001234567',
  'birthDate': '1990-05-10',
  'eps': 'Sanitas',
  'dataConsentAt': '2026-11-07T10:00:00.000Z',
};

class _Server {
  _Server(this.me);

  Map<String, dynamic> me;
  final patches = <Map<String, dynamic>>[];
  http.Response Function(Map<String, dynamic> body)? onPatch;

  MockClient get client => MockClient((request) async {
        switch (request.url.path) {
          case '/auth/refresh':
            return _json({'accessToken': 't', 'expiresIn': 600});
          case '/auth/me':
            return _json(me);
          case '/auth/profile':
            expect(request.method, 'PATCH');
            expect(request.headers['Authorization'], 'Bearer t');
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            patches.add(body);
            final custom = onPatch?.call(body);
            if (custom != null) return custom;
            me = _me(role: me['role'] as String, profile: {..._completePatient, ...body}, complete: true);
            return _json(me);
          default:
            return _json({}, 404);
        }
      });
}

Future<(AuthController, _Server)> _pump(WidgetTester tester, Widget Function(AuthController) page,
    {Map<String, dynamic>? me}) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final server = _Server(me ?? _me());
  final auth = AuthController(AuthRepository('https://auth.x', client: server.client, usesBrowserCookies: true));
  await tester.runAsync(auth.restore);
  await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: Scaffold(body: page(auth))));
  await tester.pump();
  return (auth, server);
}

Future<void> _type(WidgetTester tester, String label, String text) async {
  final wrapper = find.byWidgetPredicate((w) => w is FgTextField && w.label == label);
  await tester.enterText(find.descendant(of: wrapper, matching: find.byType(TextField)), text);
}

void main() {
  group('AuthUser profile', () {
    test('reads the profile and what is missing', () {
      final user = AuthUser.fromJson(_me(profile: {'documentType': 'CC', 'documentNumber': '123456'}));
      expect(user.profileComplete, isFalse);
      expect(user.profileMissing, ['documentType']);
      expect(user.profile.documentType, DocumentType.cc);
      expect(user.profile.hasDocument, isTrue);
    });

    test('older Auth versions without profile data never block anyone', () {
      final user = AuthUser.fromJson({'id': 'x', 'email': 'a@b.co', 'name': 'A', 'role': 'PATIENT'});
      expect(user.profileComplete, isTrue);
      expect(user.profile.hasDocument, isFalse);
    });

    test('ProfileInput sends only present fields and dates as YYYY-MM-DD', () {
      expect(
        ProfileInput(phone: '3001234567', birthDate: DateTime(1990, 5, 1), acceptDataPolicy: true).toJson(),
        {'phone': '3001234567', 'birthDate': '1990-05-01', 'acceptDataPolicy': true},
      );
    });
  });

  group('profile rules', () {
    test('documents, phones, plates and dates', () {
      expect(ProfileRules.normalizeDocument(DocumentType.cc, '1.020.304.050'), '1020304050');
      expect(ProfileRules.document(DocumentType.cc, '12'), isNotNull);
      expect(ProfileRules.document(DocumentType.pa, 'ab12345'), isNull);
      expect(ProfileRules.normalizePhone('+57 300 123 4567'), '3001234567');
      expect(ProfileRules.normalizePhone('6011234567'), isNull);
      expect(ProfileRules.normalizePlate('abc-12d'), 'ABC12D');
      final now = DateTime(2026, 11, 7);
      expect(ProfileRules.parseBirthDate('10/05/1990', now: now), DateTime(1990, 5, 10));
      expect(ProfileRules.parseBirthDate('31/02/1990', now: now), isNull);
      expect(ProfileRules.parseBirthDate('01/01/2030', now: now), isNull);
    });
  });

  group('router gate', () {
    test('an incomplete profile always leads to the profile screen', () {
      for (final path in [AppRoutes.home, AppRoutes.ordenes, AppRoutes.account, AppRoutes.completeProfile]) {
        expect(
          AppRouter.profileGate(complete: false, path: path, takeReturnTo: () => null),
          AppRoutes.completeProfile,
        );
      }
    });

    test('once complete, the profile screen sends to the saved place or home', () {
      expect(AppRouter.profileGate(complete: true, path: AppRoutes.completeProfile, takeReturnTo: () => '/ordenes'),
          '/ordenes');
      expect(AppRouter.profileGate(complete: true, path: AppRoutes.completeProfile, takeReturnTo: () => null),
          AppRoutes.home);
      expect(AppRouter.profileGate(complete: true, path: AppRoutes.home, takeReturnTo: () => null), isNull);
    });
  });

  group('complete profile page', () {
    testWidgets('a patient must fill everything and accept the data policy', (tester) async {
      final (auth, server) = await _pump(tester, (auth) => CompleteProfilePage(auth: auth));
      expect(find.text('Hola, Ana. Completa tu perfil'), findsOneWidget);
      expect(find.text('Placa'), findsNothing);

      await tester.tap(find.text('Guardar y continuar'));
      await tester.pump();
      expect(find.text('Elige el tipo de documento.'), findsOneWidget);
      expect(find.text('Escribe tu EPS.'), findsOneWidget);
      expect(find.text('Debes aceptar para continuar.'), findsOneWidget);
      expect(server.patches, isEmpty);

      await tester.tap(find.text('Cédula de ciudadanía'));
      await tester.pump();
      await _type(tester, 'Número de documento', '1.020.304.050');
      await _type(tester, 'Celular', '300 123 4567');
      await _type(tester, 'Fecha de nacimiento', '10051990');
      expect(find.text('10/05/1990'), findsOneWidget);
      await _type(tester, 'EPS', 'Sanitas');
      await tester.tap(find.byType(Checkbox));
      await tester.tap(find.text('Guardar y continuar'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();

      expect(server.patches.single, {
        'documentType': 'CC',
        'documentNumber': '1020304050',
        'phone': '3001234567',
        'birthDate': '1990-05-10',
        'eps': 'Sanitas',
        'address': '',
        'acceptDataPolicy': true,
      });
      expect(auth.user!.profileComplete, isTrue);
    });

    testWidgets('a document of another account is marked on its field', (tester) async {
      final (_, server) = await _pump(tester, (auth) => CompleteProfilePage(auth: auth));
      server.onPatch = (_) => _json({
            'success': false,
            'error': {'code': 'DOCUMENT_IN_USE', 'message': 'x'}
          }, 409);
      await tester.tap(find.text('Cédula de ciudadanía'));
      await tester.pump();
      await _type(tester, 'Número de documento', '1020304050');
      await _type(tester, 'Celular', '3001234567');
      await _type(tester, 'Fecha de nacimiento', '10/05/1990');
      await _type(tester, 'EPS', 'Sanitas');
      await tester.tap(find.byType(Checkbox));
      await tester.tap(find.text('Guardar y continuar'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
      expect(find.text(ErrorMessages.documentInUse), findsOneWidget);
    });

    testWidgets('drivers choose a vehicle; bicycles need no plate', (tester) async {
      final (_, server) = await _pump(tester, (auth) => CompleteProfilePage(auth: auth), me: _me(role: 'DELIVERY_DRIVER'));
      expect(find.text('EPS'), findsNothing);
      expect(find.text('Fecha de nacimiento'), findsNothing);
      await tester.tap(find.text('Moto'));
      await tester.pump();
      expect(find.text('Placa'), findsOneWidget);
      await tester.tap(find.text('Bicicleta'));
      await tester.pump();
      expect(find.text('Placa'), findsNothing);

      await tester.tap(find.text('Pasaporte'));
      await tester.pump();
      await _type(tester, 'Número de documento', 'ab12345');
      await _type(tester, 'Celular', '3109876543');
      await tester.tap(find.byType(Checkbox));
      await tester.tap(find.text('Guardar y continuar'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
      expect(server.patches.single, {
        'documentType': 'PA',
        'documentNumber': 'AB12345',
        'phone': '3109876543',
        'vehicleType': 'BICICLETA',
        'vehiclePlate': '',
        'acceptDataPolicy': true,
      });
    });

    testWidgets('EPS staff give the EPS where they work and their position', (tester) async {
      await _pump(tester, (auth) => CompleteProfilePage(auth: auth), me: _me(role: 'EPS'));
      expect(find.text('EPS donde trabajas'), findsOneWidget);
      expect(find.text('Cargo'), findsOneWidget);
      expect(find.text('Vehículo'), findsNothing);
    });
  });

  group('Mi cuenta', () {
    testWidgets('shows the profile and edits it without touching the document', (tester) async {
      final (_, server) = await _pump(
        tester,
        (auth) => AccountPage(auth: auth, onBack: () {}),
        me: _me(profile: _completePatient, complete: true),
      );
      expect(find.text('CC 1020304050'), findsOneWidget);
      expect(find.text('Sanitas'), findsOneWidget);
      expect(find.text('3001234567'), findsOneWidget);

      await tester.tap(find.text('Editar datos'));
      await tester.pumpAndSettle();
      expect(find.text('Número de documento'), findsNothing);
      expect(find.text('Para corregirlo, pide ayuda a un administrador.'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);

      await _type(tester, 'EPS', 'Nueva EPS');
      await tester.tap(find.text('Guardar datos'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();
      final body = server.patches.single;
      expect(body['eps'], 'Nueva EPS');
      expect(body.containsKey('documentNumber'), isFalse);
      expect(body.containsKey('acceptDataPolicy'), isFalse);
      expect(find.text('Guardamos tus datos.'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 10));
    });
  });
}
