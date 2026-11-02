import 'package:farma_go/hooks/patient_home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/home_fakes.dart';

/// Capturas de la home en cada estado del paciente y en cada ancho del diseño, más las auditorías
/// de accesibilidad de Flutter. Las capturas son deterministas: las fechas y el foco son fijos.
void main() {
  const anchos = [360.0, 768.0, 1280.0];

  for (final ancho in anchos) {
    testWidgets('captura: paciente sin actividad a ${ancho.toInt()} px', (tester) async {
      await montarInicio(tester, role: 'PATIENT', name: 'Ana Gómez', ancho: ancho, foco: const FocoVacio());
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/home_paciente_vacio_${ancho.toInt()}.png'));
    });

    testWidgets('captura: domicilio en curso a ${ancho.toInt()} px', (tester) async {
      await montarInicio(
        tester,
        role: 'PATIENT',
        name: 'Ana Gómez',
        ancho: ancho,
        foco: focoDomicilio(detalle: entregaDePrueba()),
      );
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/home_paciente_domicilio_${ancho.toInt()}.png'));
    });

    testWidgets('captura: pendiente vigente a ${ancho.toInt()} px', (tester) async {
      await montarInicio(tester, role: 'PATIENT', name: 'Ana Gómez', ancho: ancho, foco: focoPendiente());
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/home_paciente_pendiente_${ancho.toInt()}.png'));
    });
  }

  for (final ancho in [360.0, 1280.0]) {
    testWidgets('captura: administrador a ${ancho.toInt()} px', (tester) async {
      await montarInicio(tester, role: 'ADMIN', name: 'Carlos Ruiz', ancho: ancho);
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/home_administrador_${ancho.toInt()}.png'));
    });

    testWidgets('captura: repartidor a ${ancho.toInt()} px', (tester) async {
      await montarInicio(tester, role: 'DELIVERY_DRIVER', name: 'Luis Peña', ancho: ancho);
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/home_repartidor_${ancho.toInt()}.png'));
    });
  }

  for (final caso in {
    'vacio': const FocoVacio(),
    'domicilio': focoDomicilio(detalle: entregaDePrueba()),
    'pendiente': focoPendiente(),
  }.entries) {
    testWidgets('accesibilidad: paciente ${caso.key} a 360 px', (tester) async {
      await montarInicio(tester, role: 'PATIENT', name: 'Ana Gómez', ancho: 360, altura: 2000, foco: caso.value);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  }
}
