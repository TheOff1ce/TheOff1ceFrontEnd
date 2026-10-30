import 'dart:convert';
import 'dart:typed_data';

import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/auth/auth_controller.dart';
import 'package:farma_go/auth/auth_repository.dart';
import 'package:farma_go/components/feedback.dart';
import 'package:farma_go/components/medication_card.dart';
import 'package:farma_go/errors/app_error.dart';
import 'package:farma_go/errors/error_messages.dart';
import 'package:farma_go/hooks/prescription_hook.dart';
import 'package:farma_go/pages/analysis_page.dart';
import 'package:farma_go/pages/login_page.dart';
import 'package:farma_go/pages/result_page.dart';
import 'package:farma_go/services/api_service.dart';
import 'package:farma_go/services/prescription_service.dart';
import 'package:farma_go/types/analysis_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';

Widget app(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

/// Tall viewport so lazily built lists render every item.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Finder liveRegions() => find.byWidgetPredicate((w) => w is Semantics && w.properties.liveRegion == true);

void main() {
  testWidgets('FE-011 / FE-017: unnamed medications are labeled and flagged for review', (tester) async {
    useTallScreen(tester);
    final result = AnalysisResponse.fromJson({
      'requires_human_review': true,
      'warnings': ['No fue posible identificar el nombre del medicamento 1.'],
      'medications': [
        {'name': null, 'confidence': 0.95, 'requires_review': true},
        {'name': 'Ibuprofeno', 'confidence': 0.9, 'requires_review': false},
      ],
    });
    await tester.pumpWidget(app(ResultPage(result: result, onHome: () {}, onAnalyzeAnother: () {})));
    expect(find.text(MedicationCard.unnamedTitle), findsOneWidget);
    expect(find.text('Revisión necesaria'), findsOneWidget);
    expect(find.textContaining('Revísalo'), findsOneWidget);
    expect(find.text('Encontramos 2 medicamentos'), findsOneWidget);
  });

  testWidgets('an empty result explains what to do next', (tester) async {
    useTallScreen(tester);
    final result = AnalysisResponse.fromJson({'medications': []});
    await tester.pumpWidget(app(ResultPage(result: result, onHome: () {}, onAnalyzeAnother: () {})));
    expect(find.text('No identificamos medicamentos'), findsOneWidget);
    expect(find.text('Analizar otra fórmula'), findsOneWidget);
  });

  testWidgets('FE-002 / FE-008: errors are human, announced and carry a support reference', (tester) async {
    useTallScreen(tester);
    final error = AppError(kind: AppErrorKind.server, userMessage: ErrorMessages.server, retryable: true);
    await tester.pumpWidget(app(Scaffold(body: ErrorBanner(error: error))));
    expect(find.text(ErrorMessages.server), findsOneWidget);
    expect(find.textContaining(error.referenceId), findsOneWidget);
    expect(liveRegions(), findsWidgets);
  });

  testWidgets('FE-005: a non-retryable analysis error offers another image instead of retrying', (tester) async {
    useTallScreen(tester);
    final api = ApiService('https://ai.example',
        client: MockClient((_) async => http.Response(
              jsonEncode({
                'success': false,
                'error': {'code': 'INVALID_FILE', 'message': 'technical'},
              }),
              400,
            )));
    final controller = PrescriptionController(PrescriptionService(api));
    var wentBack = false;
    await tester.pumpWidget(app(AnalysisPage(
      controller: controller,
      image: XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'formula.png', mimeType: 'image/png'),
      onBack: () => wentBack = true,
      onComplete: () {},
    )));
    await tester.pump();
    await tester.pump();
    expect(find.text('Elegir otra imagen'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
    expect(find.text(ErrorMessages.invalidFile), findsOneWidget);
    expect(find.textContaining('technical'), findsNothing);
    await tester.tap(find.text('Elegir otra imagen'));
    expect(wentBack, isTrue);
  });

  testWidgets('FE-008 / FE-013: login controls have accessible names and Google is explained on mobile',
      (tester) async {
    useTallScreen(tester);
    final auth = AuthController(AuthRepository('https://auth.example',
        usesBrowserCookies: true, client: MockClient((_) async => http.Response('{}', 200))));
    await tester.pumpWidget(app(LoginPage(
      auth: auth,
      onRegister: () {},
      onForgotPassword: () {},
      onBack: () {},
      googleEnabled: false,
    )));
    expect(find.byTooltip('Mostrar contraseña'), findsOneWidget);
    expect(find.byTooltip('Volver'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsNothing);
    expect(find.textContaining('versión web'), findsOneWidget);

    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
    auth.dispose();
  });

  testWidgets('FE-008: submitting an invalid login shows specific messages next to the fields', (tester) async {
    useTallScreen(tester);
    final auth = AuthController(AuthRepository('https://auth.example',
        usesBrowserCookies: true, client: MockClient((_) async => http.Response('{}', 200))));
    await tester.pumpWidget(app(LoginPage(
      auth: auth,
      onRegister: () {},
      onForgotPassword: () {},
      onBack: () {},
      googleEnabled: false,
    )));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    expect(find.text('Escribe un correo con el formato nombre@dominio.com.'), findsOneWidget);
    expect(find.text('La contraseña debe tener al menos 8 caracteres.'), findsOneWidget);
    auth.dispose();
  });

  testWidgets('FE-007: the review indicator uses text and icon, not only color', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(app(const Scaffold(body: ConfidenceIndicator(confidence: 0.6, requiresReview: true))));
    expect(find.text('Confianza de extracción: 60 % · Revísalo'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });
}
