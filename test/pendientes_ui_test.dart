import 'dart:convert';

import 'package:farma_go/app/theme/farmago_tokens.dart';
import 'package:farma_go/components/farmago/status_badge.dart';
import 'package:farma_go/components/pendientes/novedad_form.dart';
import 'package:farma_go/components/pendientes/pendiente_card.dart';
import 'package:farma_go/components/pendientes/pendiente_detalle_view.dart';
import 'package:farma_go/components/pendientes/pendientes_table.dart';
import 'package:farma_go/errors/error_mapper.dart';
import 'package:farma_go/hooks/pendiente_detail_controller.dart';
import 'package:farma_go/hooks/pendientes_list_controller.dart';
import 'package:farma_go/pages/pendientes_page.dart';
import 'package:farma_go/services/access_token_source.dart';
import 'package:farma_go/services/authorized_json_client.dart';
import 'package:farma_go/services/pendientes_service.dart';
import 'package:farma_go/types/pendiente.dart';
import 'package:farma_go/utils/pendientes_rol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// En las pruebas Flutter usa una fuente de ancho completo (Ahem): los anchos aquí son mucho
// mayores que con Atkinson, así que los tamaños de pantalla de estas pruebas son generosos.

class FakeTokens implements AccessTokenSource {
  @override
  Future<String?> currentAccessToken({bool forceRefresh = false}) async => 'token-1';
}

Map<String, dynamic> resumenJson({
  String id = '3f2b8f0e-5b1e-4f57-9d58-1c6a1f0a0001',
  String orden = 'PED-2026-000123',
  String cumplimiento = 'VIGENTE',
}) =>
    {
      'id': id,
      'ordenMedicamentoId': orden,
      'pacienteId': '7c9e6679-7425-40de-944b-e07fc1f90ae7',
      'epsUserId': 'eps-1',
      'dispensarioId': 'dispensario',
      'fechaEvento': '2026-10-24T15:15:00.000Z',
      'fechaRegistro': '2026-10-24T15:20:00.000Z',
      'fechaLimite': '2026-10-26T15:15:00.000Z',
      'estadoEntrega': 'PENDIENTE',
      'fechaEntrega': null,
      'cumplimientoPlazo': cumplimiento,
      'evaluadoEn': '2026-10-25T00:00:00.000Z',
      'medicamentosTotal': 3,
      'medicamentosEntregados': 1,
      'cantidadNovedades': 1,
    };

Map<String, dynamic> detalleJson() => {
      ...resumenJson(),
      'medicamentos': [
        {'medicamentoId': 'MED-ATORVASTATINA-20MG', 'fechaHabilitacion': null, 'fechaEntrega': null, 'estadoEntrega': 'PENDIENTE'},
        {
          'medicamentoId': 'MED-METFORMINA-850MG',
          'fechaHabilitacion': '2026-10-24T20:00:00.000Z',
          'fechaEntrega': '2026-10-25T14:30:00.000Z',
          'estadoEntrega': 'ENTREGADO',
        },
      ],
      'novedades': [
        {
          'id': 'n-1',
          'fechaHora': '2026-10-24T22:00:00.000Z',
          'tipo': 'CONTACTO_PACIENTE',
          'detalle': 'Se informó al paciente del punto alterno.',
        },
      ],
    };

http.Response ok(Object body, [int status = 200]) => http.Response(jsonEncode(body), status);

PendientesService serviceWith(MockClientHandler handler) => PendientesService(AuthorizedJsonClient(
      'https://pendientes.example',
      tokens: FakeTokens(),
      client: MockClient(handler),
      timeout: const Duration(seconds: 5),
      errorMapper: ErrorMapper.fromPendientes,
    ));

Widget app(Widget child) => MaterialApp(theme: FarmaGoTheme.light, home: Scaffold(body: child));

void useScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Deja pasar la carga asíncrona sin esperar animaciones infinitas (esqueletos).
Future<void> pasar(WidgetTester tester, [int veces = 4]) async {
  for (var i = 0; i < veces; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Desmonta el árbol: cancela los temporizadores de minuto de los relojes.
Future<void> cerrar(WidgetTester tester) => tester.pumpWidget(const SizedBox());

void main() {
  group('componentes', () {
    testWidgets('cada estado se muestra con su palabra (nunca solo color)', (tester) async {
      useScreen(tester, const Size(600, 600));
      for (final estado in CumplimientoPlazo.values) {
        await tester.pumpWidget(app(Column(children: [StatusBadge(estado: estado), StatusBadge(estado: estado, destacado: true)])));
        expect(find.text(estado.etiqueta), findsNWidgets(2));
      }
      await cerrar(tester);
    });

    testWidgets('la tarjeta muestra orden, tiempo restante y estado, y se abre al tocarla', (tester) async {
      useScreen(tester, const Size(500, 900));
      var abierta = 0;
      await tester.pumpWidget(app(SingleChildScrollView(
        child: PendienteCard(
          pendiente: PendienteResumen.fromJson(resumenJson()),
          desdeCarga: Duration.zero,
          onOpen: () => abierta++,
        ),
      )));
      expect(find.text('Orden PED-2026-000123'), findsOneWidget);
      expect(find.text('39 h 15 min'), findsOneWidget);
      expect(find.text('Vigente'), findsOneWidget);
      expect(find.text('1 de 3 medicamentos entregados'), findsOneWidget);
      await tester.tap(find.byType(PendienteCard));
      expect(abierta, 1);
      await cerrar(tester);
    });

    testWidgets('el detalle muestra medicamentos, pasos y novedades; el paciente no ve el dato de otros', (tester) async {
      useScreen(tester, const Size(900, 2400));
      final detalle = PendienteDetalle.fromJson(detalleJson());
      Widget vista(PendientesRol rol) => app(SingleChildScrollView(
            child: PendienteDetalleVista(detalle: detalle, desdeCarga: Duration.zero, rol: rol),
          ));

      await tester.pumpWidget(vista(PendientesRol.paciente));
      expect(find.text('MED-ATORVASTATINA-20MG'), findsOneWidget);
      expect(find.text('Sin habilitar'), findsOneWidget);
      expect(find.text('Por entregar'), findsOneWidget);
      expect(find.text('Contacto paciente'), findsOneWidget);
      expect(find.text('Paciente'), findsNothing);

      await tester.pumpWidget(vista(PendientesRol.eps));
      expect(find.text('Paciente'), findsOneWidget);
      expect(find.text('•••• 0ae7'), findsOneWidget);
      await cerrar(tester);
    });
  });

  group('formulario de novedad', () {
    testWidgets('valida antes de enviar y manda los textos sin espacios sobrantes', (tester) async {
      useScreen(tester, const Size(1000, 1400));
      final enviados = <(String, String)>[];
      await tester.pumpWidget(app(SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: NovedadForm(
          enviando: false,
          onEnviar: (tipo, detalle) async {
            enviados.add((tipo, detalle));
            return null;
          },
          onCancelar: () {},
          onCambiosSinGuardar: (_) {},
        ),
      )));

      await tester.tap(find.text('Registrar novedad'));
      await tester.pump();
      expect(find.text('Escribe el tipo de novedad.'), findsOneWidget);
      expect(find.text('Describe la novedad.'), findsOneWidget);
      expect(find.text('Revisa los campos marcados e inténtalo de nuevo.'), findsOneWidget);
      expect(enviados, isEmpty);

      await tester.enterText(find.byType(TextField).first, 'a' * (novedadTipoMaximo + 1));
      await tester.enterText(find.byType(TextField).last, 'x');
      await tester.tap(find.text('Registrar novedad'));
      await tester.pump();
      expect(find.text('El tipo no puede superar $novedadTipoMaximo caracteres.'), findsOneWidget);
      expect(enviados, isEmpty);

      await tester.enterText(find.byType(TextField).first, '  Llamada  ');
      await tester.enterText(find.byType(TextField).last, 'Contestó el paciente');
      await tester.tap(find.text('Registrar novedad'));
      await tester.pump();
      expect(enviados, [('Llamada', 'Contestó el paciente')]);
      await cerrar(tester);
    });
  });

  group('lista de pendientes', () {
    PendientesService servicio({List<Map<String, dynamic>>? items, int estado = 200}) => serviceWith((request) async {
          if (estado != 200) return ok({'statusCode': estado, 'error': 'Error', 'message': 'x'}, estado);
          if (request.url.path == '/pendientes') {
            final lista = items ?? [resumenJson(id: 'id-a', orden: 'PED-A'), resumenJson(id: 'id-b', orden: 'PED-B', cumplimiento: 'INCUMPLIDO')];
            return ok({'items': lista, 'pagina': 1, 'limite': 25, 'total': lista.length});
          }
          return ok(detalleJson());
        });

    Widget pagina(PendientesService s, PendientesRol rol, {List<String>? abiertos}) => MaterialApp(
          home: PendientesPage(
            controller: PendientesListController(s),
            rol: rol,
            createDetailController: (id) => PendienteDetailController(s, id),
            onOpen: (p) => abiertos?.add(p.id),
            onBack: () {},
          ),
        );

    testWidgets('en móvil son tarjetas y tocar una pide abrir su pantalla de detalle', (tester) async {
      useScreen(tester, const Size(600, 2400));
      final abiertos = <String>[];
      await tester.pumpWidget(pagina(servicio(), PendientesRol.paciente, abiertos: abiertos));
      await pasar(tester);
      expect(find.byType(PendienteCard), findsNWidgets(2));
      expect(find.byType(PendientesTable), findsNothing);
      expect(find.text('Esta información no reemplaza a tu médico ni a tu EPS.'), findsOneWidget);
      expect(find.text('Mostrando 1–2 de 2'), findsOneWidget);
      await tester.tap(find.byType(PendienteCard).last);
      expect(abiertos, ['id-b']);
      await cerrar(tester);
    });

    testWidgets('en pantallas anchas es una tabla y el detalle se abre en un panel lateral', (tester) async {
      useScreen(tester, const Size(1500, 1000));
      final s = servicio();
      await tester.pumpWidget(pagina(s, PendientesRol.eps));
      await pasar(tester);
      expect(find.byType(PendientesTable), findsOneWidget);
      expect(find.byType(PendienteCard), findsNothing);
      expect(find.text('Fecha límite'), findsOneWidget); // encabezado de columna
      expect(find.text('PED-A'), findsOneWidget);

      await tester.tap(find.text('PED-A'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await pasar(tester);
      expect(find.text('Orden PED-2026-000123'), findsOneWidget); // título del panel
      expect(find.text('MED-ATORVASTATINA-20MG'), findsOneWidget);
      expect(find.text('Registrar novedad'), findsOneWidget); // la EPS puede registrar novedades
      await cerrar(tester);
    });

    testWidgets('el paciente consulta pero no registra novedades', (tester) async {
      useScreen(tester, const Size(1500, 1000));
      await tester.pumpWidget(pagina(servicio(), PendientesRol.paciente));
      await pasar(tester);
      await tester.tap(find.text('PED-A'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await pasar(tester);
      expect(find.text('MED-ATORVASTATINA-20MG'), findsOneWidget);
      expect(find.text('Registrar novedad'), findsNothing);
      await cerrar(tester);
    });

    testWidgets('sin pendientes explica qué pasará y qué hacer', (tester) async {
      useScreen(tester, const Size(600, 1200));
      await tester.pumpWidget(pagina(servicio(items: []), PendientesRol.paciente));
      await pasar(tester);
      expect(find.text('No tienes pendientes'), findsOneWidget);
      expect(find.text('Cuando una entrega quede incompleta, la verás aquí.'), findsOneWidget);
      await cerrar(tester);
    });

    testWidgets('si el servicio falla muestra el error en lenguaje claro con la opción de reintentar', (tester) async {
      useScreen(tester, const Size(600, 1200));
      await tester.pumpWidget(pagina(servicio(estado: 500), PendientesRol.eps));
      await pasar(tester);
      expect(find.text('No pudimos cargar los pendientes'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.textContaining('Código de referencia'), findsOneWidget);
      await cerrar(tester);
    });
  });
}
