import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/app/theme/farmago_tokens.dart';
import 'package:farma_go/components/farmago/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fuentes_reales.dart';

/// Capturas de los avisos flotantes: éxito con lo que sigue, éxito corto y error, en celular y web.
void main() {
  for (final (ancho, alto) in [(360.0, 640.0), (1280.0, 720.0)]) {
    testWidgets('captura: avisos a ${ancho.toInt()} px', (tester) async {
      await tester.runAsync(cargarFuentesReales);
      tester.view.physicalSize = Size(ancho, alto);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) => FgCapaAvisos(child: child!),
        home: Scaffold(
          backgroundColor: FgColors.fondo,
          body: Padding(padding: const EdgeInsets.all(24), child: Text('Seguimiento del domicilio', style: FgText.bodyLg)),
        ),
      ));
      avisar('Pedido confirmado', detalle: 'Te avisamos cuando un repartidor lo tome.');
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/aviso_exito_${ancho.toInt()}.png'));

      avisar('Datos guardados');
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/aviso_exito_corto_${ancho.toInt()}.png'));

      avisar('No pudimos tomar el pedido. Otro repartidor lo tomó primero.', kind: FgToastKind.error);
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/aviso_error_${ancho.toInt()}.png'));
      await tester.tap(find.byTooltip('Cerrar aviso'));
      await tester.pump();
    });
  }
}
