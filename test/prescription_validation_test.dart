import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/components/analysis_widgets.dart';
import 'package:farma_go/pages/result_page.dart';
import 'package:farma_go/types/analysis_response.dart';
import 'package:farma_go/utils/pendiente_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void _alto(WidgetTester tester, {double ancho = 360}) {
  tester.view.physicalSize = Size(ancho, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

AnalysisResponse _analisis({Map<String, dynamic>? validation, Map<String, dynamic>? prescription}) =>
    AnalysisResponse.fromJson({
      'patient': {'name': 'Ana Pérez', 'document_type': 'CC', 'document_number': '1020304050'},
      if (prescription != null) 'prescription': prescription,
      if (validation != null) 'validation': validation,
      'medications': [
        {'name': 'Metformina', 'concentration': '850 mg', 'quantity': '60', 'confidence': 0.94},
      ],
    });

Future<void> _mostrar(WidgetTester tester, AnalysisResponse result) async {
  _alto(tester);
  await tester.pumpWidget(_app(ResultPage(result: result, onHome: () {}, onAnalyzeAnother: () {})));
}

void main() {
  test('los campos que faltan se dicen en lenguaje humano', () {
    expect(missingPrescriptionField('patient.name'), 'El nombre del paciente');
    expect(missingPrescriptionField('patient.document_number'), 'El número de documento del paciente');
    expect(missingPrescriptionField('prescription.issue_date'), 'La fecha en que se hizo la fórmula');
    expect(missingPrescriptionField('medications'), 'Los medicamentos recetados');
    expect(missingPrescriptionField('algo.nuevo'), isNot(contains('.')));
    // Un día de calendario no cambia de fecha por la zona horaria.
    expect(PendienteFormat.fechaDia(DateTime.parse('2026-11-30')), '30 nov 2026');
  });

  testWidgets('fórmula vigente: dice hasta cuándo se puede usar', (tester) async {
    await _mostrar(
        tester,
        _analisis(validation: {
          'status': 'VALID',
          'missing_fields': [],
          'issue_date': '2026-11-20',
          'expires_on': '2026-12-20',
        }));
    expect(find.text('Fórmula vigente'), findsOneWidget);
    expect(find.text('Puedes usarla hasta el 20 dic 2026.'), findsOneWidget);
  });

  testWidgets('fórmula incompleta: lista lo que falta y qué hacer, sin nombres técnicos', (tester) async {
    await _mostrar(
        tester,
        _analisis(validation: {
          'status': 'INCOMPLETE',
          'missing_fields': ['patient.document_number', 'prescription.issue_date'],
          'issue_date': null,
          'expires_on': null,
        }));
    expect(find.text('A la fórmula le faltan datos'), findsOneWidget);
    expect(find.textContaining('• El número de documento del paciente'), findsOneWidget);
    expect(find.textContaining('• La fecha en que se hizo la fórmula'), findsOneWidget);
    expect(find.textContaining('toma otra foto'), findsOneWidget);
    expect(find.textContaining('prescription.issue_date'), findsNothing);
  });

  testWidgets('fórmula vencida: la fecha y pedir una nueva al médico', (tester) async {
    await _mostrar(
        tester,
        _analisis(validation: {
          'status': 'EXPIRED',
          'missing_fields': [],
          'issue_date': '2026-08-01',
          'expires_on': '2026-10-01',
        }));
    expect(find.text('La fórmula está vencida'), findsOneWidget);
    expect(find.textContaining('Venció el 1 oct 2026.'), findsOneWidget);
    expect(find.textContaining('Pide una fórmula nueva a tu médico'), findsOneWidget);
  });

  testWidgets('muestra los datos de la fórmula que se leyeron', (tester) async {
    await _mostrar(
        tester,
        _analisis(
          validation: {'status': 'VALID', 'missing_fields': [], 'expires_on': '2026-12-20'},
          prescription: {
            'issue_date': '2026-11-20',
            'authorization_number': 'AUT-778812',
            'prescriber_name': 'Dra. Laura Ríos',
            'prescriber_license': 'RM 55231',
            'eps_name': null,
          },
        ));
    expect(find.text('Datos de la fórmula'), findsOneWidget);
    expect(find.text('20 nov 2026'), findsOneWidget);
    expect(find.text('AUT-778812'), findsOneWidget);
    expect(find.text('Dra. Laura Ríos · Registro RM 55231'), findsOneWidget);
    expect(find.text('EPS'), findsNothing); // solo los datos que existen
  });

  testWidgets('con un servicio antiguo (sin validación) no aparece nada nuevo', (tester) async {
    await _mostrar(
        tester,
        _analisis(prescription: {'issue_date': '2026-11-20', 'eps_name': 'Sanitas'}));
    expect(find.byType(PrescriptionValidationNotice), findsNothing);
    expect(find.byType(PrescriptionInfoCard), findsNothing);
    expect(find.text('Encontramos 1 medicamento'), findsOneWidget);
  });
}
