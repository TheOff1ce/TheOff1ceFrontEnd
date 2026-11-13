import 'package:farma_go/app/theme/app_theme.dart';
import 'dart:async';
import 'dart:io';

import 'package:farma_go/app/theme/farmago_tokens.dart';
import 'package:farma_go/hooks/ordenes_controller.dart';
import 'package:farma_go/pages/ordenes_page.dart';
import 'package:farma_go/services/ordenes_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support/fuentes_reales.dart';
import 'support/ordenes_fakes.dart';

/// Capturas de «Órdenes y autorizaciones» en cada estado y ancho, y auditorías de accesibilidad.
/// Las capturas son deterministas: sin animaciones (movimiento reducido), fechas y foco fijos.
///
/// Las capturas dependen de la plataforma que rasteriza el texto: las de otra plataforma fallarían en
/// el CI de Ubuntu. Por eso solo se comparan (o se regeneran) con `ORDENES_GOLDENS=1`, p. ej.
/// `ORDENES_GOLDENS=1 flutter test test/ordenes_visual_test.dart --update-goldens`. Sin la variable,
/// cada prueba sigue verificando estados, desbordes y accesibilidad.
Future<void> capturar(String nombre) async {
  if (Platform.environment['ORDENES_GOLDENS'] != '1') return;
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$nombre.png'));
}

Future<OrdenesController> montarOrdenes(
  WidgetTester tester, {
  required double ancho,
  double altura = 1500,
  OrdenesService? service,
  double texto = 1,
  void Function(OrdenesController)? alCargar,
}) async {
  await tester.runAsync(cargarFuentesReales);
  tester.view.physicalSize = Size(ancho, altura);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late OrdenesController controlador;
  await tester.pumpWidget(MaterialApp(theme: AppTheme.light, 
    debugShowCheckedModeBanner: false,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true, textScaler: TextScaler.linear(texto)),
      child: child!,
    ),
    home: OrdenesPage(
      createController: () => controlador = OrdenesController(service ?? servicioFeliz()),
      onBack: () {},
      onRevisarDatos: () {},
      onSeguirEnDomicilios: () {},
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  alCargar?.call(controlador);
  await tester.pump();
  return controlador;
}

void marcarDos(OrdenesController c) {
  final orden = c.respuesta!.ordenes.first;
  c.alternar(orden, orden.medicamentos[0]);
  c.alternar(orden, orden.medicamentos[1]);
}

void main() {
  for (final ancho in [360.0, 768.0, 1280.0]) {
    testWidgets('captura: órdenes con selección a ${ancho.toInt()} px', (tester) async {
      await montarOrdenes(tester, ancho: ancho, alCargar: marcarDos);
      expect(tester.takeException(), isNull);
      await capturar('ordenes_lista_${ancho.toInt()}');
    });
  }

  testWidgets('captura: carga a 360 px', (tester) async {
    final espera = Completer<http.Response>();
    await montarOrdenes(tester, ancho: 360, altura: 900, service: servicioCon((_) => espera.future));
    expect(find.text('Consultando tu EPS en vivo…'), findsOneWidget);
    await capturar('ordenes_carga_360');
    espera.complete(ok(respuestaJson()));
    await tester.pump();
  });

  testWidgets('captura: vacío a 1280 px', (tester) async {
    await montarOrdenes(tester, ancho: 1280, altura: 900, service: servicioFeliz(lista: respuestaJson(ordenes: [])));
    expect(find.text('No tienes órdenes en este momento'), findsOneWidget);
    await capturar('ordenes_vacio_1280');
  });

  testWidgets('captura: error con reintento a 360 px', (tester) async {
    await montarOrdenes(
      tester,
      ancho: 360,
      altura: 900,
      // 504 y no 503: un error de servidor lleva un código de referencia aleatorio en el aviso.
      service: servicioCon((_) async => http.Response('{}', 504)),
    );
    expect(find.text('No pudimos consultar tu EPS en este momento'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    await capturar('ordenes_error_360');
  });

  testWidgets('captura: bloqueo por documento a 1280 px', (tester) async {
    await montarOrdenes(
      tester,
      ancho: 1280,
      altura: 700,
      service: servicioCon((_) async => ok({
            'code': 'AFILIACION_NO_ENCONTRADA',
            'detalles': {'documentoEnmascarado': 'CC •••• 0099'},
          }, 403)),
    );
    expect(find.text('Tu EPS no encuentra tu documento'), findsOneWidget);
    expect(find.textContaining('CC •••• 0099'), findsOneWidget);
    await capturar('ordenes_bloqueo_1280');
  });

  for (final ancho in [360.0, 1280.0]) {
    testWidgets('captura: diálogo de domicilio confirmado a ${ancho.toInt()} px', (tester) async {
      await montarOrdenes(tester, ancho: ancho, altura: 900, alCargar: marcarDos);
      await tester.tap(find.text('Pedir a domicilio').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Confirmar pedido'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Calle 100 # 15-20, Bogotá');
      await tester.pump();
      await capturar('ordenes_dialogo_listo_${ancho.toInt()}');
      await tester.tap(find.text('Confirmar pedido'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Referencia del pedido'), findsOneWidget);
      await capturar('ordenes_dialogo_exito_${ancho.toInt()}');
    });
  }

  group('sin desbordes', () {
    for (final (ancho, texto) in [(320.0, 1.0), (320.0, 1.5), (360.0, 2.0), (1280.0, 1.5)]) {
      testWidgets('lista a $ancho px con texto ×$texto', (tester) async {
        await montarOrdenes(tester, ancho: ancho, altura: 2600, texto: texto, alCargar: marcarDos);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('nombres largos sin espacios no desbordan a 320 px', (tester) async {
      final larga = 'Ácidodesoxirribonucleicosintéticoextralargo' * 2;
      await montarOrdenes(
        tester,
        ancho: 320,
        altura: 2000,
        service: servicioFeliz(lista: respuestaJson(ordenes: [
          ordenJson(medicamentos: [medicamentoJson(id: 'MED-LARGO', dci: larga)]),
          ordenJson(id: 'PED-2'),
        ])),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('una orden con 12 medicamentos y una con 1', (tester) async {
      await montarOrdenes(
        tester,
        ancho: 360,
        altura: 4000,
        service: servicioFeliz(lista: respuestaJson(ordenes: [
          ordenJson(medicamentos: [for (var i = 0; i < 12; i++) medicamentoJson(id: 'MED-$i', dci: 'Medicamento $i')]),
          ordenJson(id: 'PED-2', medicamentos: [medicamentoJson(id: 'MED-UNICO')]),
        ])),
      );
      expect(tester.takeException(), isNull);
    });
  });

  for (final ancho in [360.0, 1280.0]) {
    testWidgets('accesibilidad: lista a ${ancho.toInt()} px', (tester) async {
      await montarOrdenes(tester, ancho: ancho, altura: 3400, alCargar: marcarDos);
      // Que terminen las entradas escalonadas: el contraste se mide sobre los píxeles ya dibujados.
      await tester.pump(const Duration(seconds: 2));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  }

  testWidgets('la casilla se marca con el teclado y anuncia su estado', (tester) async {
    final c = await montarOrdenes(tester, ancho: 1280, altura: 1800);
    final semantica = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Pedir a domicilio Metformina 850 mg'), findsOneWidget);
    expect(c.seleccion, isNull);
    await tester.tap(find.bySemanticsLabel('Pedir a domicilio Metformina 850 mg'));
    await tester.pump();
    expect(c.seleccion?.ids, {'MED-METFORMINA-850'});
    expect(find.text('1 medicamento elegido'), findsOneWidget);
    expect(FgText.family, isNotEmpty);
    semantica.dispose();
  });
}
