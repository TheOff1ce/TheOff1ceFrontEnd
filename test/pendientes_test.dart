import 'dart:async';
import 'dart:convert';

import 'package:farma_go/errors/app_error.dart';
import 'package:farma_go/errors/error_mapper.dart';
import 'package:farma_go/errors/error_messages.dart';
import 'package:farma_go/hooks/pendiente_detail_controller.dart';
import 'package:farma_go/hooks/pendientes_list_controller.dart';
import 'package:farma_go/services/access_token_source.dart';
import 'package:farma_go/services/authorized_json_client.dart';
import 'package:farma_go/services/pendientes_service.dart';
import 'package:farma_go/types/pendiente.dart';
import 'package:farma_go/utils/pendiente_format.dart';
import 'package:farma_go/utils/pendientes_rol.dart';
import 'package:farma_go/utils/plazo_vista.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeTokens implements AccessTokenSource {
  @override
  Future<String?> currentAccessToken({bool forceRefresh = false}) async => 'token-1';
}

/// 24 oct 2026 10:15 (Bogotá) -> límite 26 oct 2026 10:15 (Bogotá).
const _evento = '2026-10-24T15:15:00.000Z';
const _limite = '2026-10-26T15:15:00.000Z';

Map<String, dynamic> resumenJson({
  String id = '3f2b8f0e-5b1e-4f57-9d58-1c6a1f0a0001',
  String orden = 'PED-2026-000123',
  String estadoEntrega = 'PENDIENTE',
  String cumplimiento = 'VIGENTE',
  String? fechaEntrega,
  String evaluadoEn = '2026-10-25T00:00:00.000Z', // 19:00 del 24 oct en Bogotá -> quedan 39 h 15 min
  int total = 3,
  int entregados = 1,
  int novedades = 1,
}) =>
    {
      'id': id,
      'ordenMedicamentoId': orden,
      'pacienteId': '7c9e6679-7425-40de-944b-e07fc1f90ae7',
      'epsUserId': 'eps-1',
      'dispensarioId': 'dispensario',
      'fechaEvento': _evento,
      'fechaRegistro': '2026-10-24T15:20:00.000Z',
      'fechaLimite': _limite,
      'estadoEntrega': estadoEntrega,
      'fechaEntrega': fechaEntrega,
      'cumplimientoPlazo': cumplimiento,
      'evaluadoEn': evaluadoEn,
      'medicamentosTotal': total,
      'medicamentosEntregados': entregados,
      'cantidadNovedades': novedades,
    };

Map<String, dynamic> detalleJson({Map<String, dynamic>? resumen}) => {
      ...(resumen ?? resumenJson()),
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

Map<String, dynamic> paginaJson(List<Map<String, dynamic>> items, {int pagina = 1, int limite = 25, int? total}) => {
      'items': items,
      'pagina': pagina,
      'limite': limite,
      'total': total ?? items.length,
    };

http.Response ok(Object body, [int status = 200]) => http.Response(jsonEncode(body), status);

PendientesService serviceWith(MockClientHandler handler) => PendientesService(AuthorizedJsonClient(
      'https://pendientes.example',
      tokens: FakeTokens(),
      client: MockClient(handler),
      timeout: const Duration(seconds: 5),
      errorMapper: ErrorMapper.fromPendientes,
    ));

void main() {
  group('formatos del manual (§12)', () {
    test('las fechas se muestran en hora de Bogotá (UTC-5) con el formato del manual', () {
      final t = DateTime.utc(2026, 10, 26, 14, 15);
      expect(PendienteFormat.fecha(t), '26 oct 2026');
      expect(PendienteFormat.hora(t), '9:15 a. m.');
      expect(PendienteFormat.fechaHora(t), '26 oct 2026, 9:15 a. m.');
      expect(PendienteFormat.fechaHoraLarga(t), '26 de octubre de 2026, 9:15 a. m.');
    });

    test('medianoche, mediodía y el cambio de día/año usan la hora de Bogotá', () {
      expect(PendienteFormat.hora(DateTime.utc(2026, 10, 26, 5, 30)), '12:30 a. m.');
      expect(PendienteFormat.hora(DateTime.utc(2026, 10, 26, 17, 5)), '12:05 p. m.');
      expect(PendienteFormat.fechaHora(DateTime.utc(2026, 1, 1, 3)), '31 dic 2025, 10:00 p. m.');
    });

    test('duraciones: N h M min, N min y su versión hablada', () {
      expect(PendienteFormat.duracion(const Duration(hours: 31, minutes: 20, seconds: 40)), '31 h 20 min');
      expect(PendienteFormat.duracion(const Duration(minutes: 45)), '45 min');
      expect(PendienteFormat.duracion(const Duration(hours: -2, minutes: -5)), '2 h 5 min');
      expect(PendienteFormat.duracionLarga(const Duration(hours: 31, minutes: 20)), '31 horas y 20 minutos');
      expect(PendienteFormat.duracionLarga(const Duration(hours: 1)), '1 hora');
      expect(PendienteFormat.duracionLarga(const Duration(minutes: 1)), '1 minuto');
    });

    test('las novedades de menos de 24 h son relativas; las demás, con fecha completa', () {
      final ahora = DateTime.utc(2026, 10, 25, 12);
      expect(PendienteFormat.novedad(ahora.subtract(const Duration(hours: 3)), ahora), 'hace 3 h');
      expect(PendienteFormat.novedad(ahora.subtract(const Duration(minutes: 30)), ahora), 'hace 30 min');
      final vieja = ahora.subtract(const Duration(hours: 25));
      expect(PendienteFormat.novedad(vieja, ahora), PendienteFormat.fechaHora(vieja));
    });

    test('privacidad y texto libre', () {
      expect(PendienteFormat.pacienteEnmascarado('7c9e6679-7425-40de-944b-e07fc1f90ae7'), '•••• 0ae7');
      expect(PendienteFormat.tipoNovedad('CONTACTO_PACIENTE'), 'Contacto paciente');
      expect(PendienteFormat.tipoNovedad('Llamada al paciente'), 'Llamada al paciente');
      expect(PendienteFormat.medicamentosEntregados(1, 3), '1 de 3 medicamentos entregados');
      expect(PendienteFormat.medicamentosEntregados(0, 1), '0 de 1 medicamento entregado');
    });
  });

  group('modelos', () {
    test('un resumen válido se interpreta y el plazo total sale de las fechas del backend', () {
      final p = PendienteResumen.fromJson(resumenJson());
      expect(p.ordenMedicamentoId, 'PED-2026-000123');
      expect(p.cumplimientoPlazo, CumplimientoPlazo.vigente);
      expect(p.fechaEntrega, isNull);
      expect(p.plazoTotal, const Duration(hours: 48));
      expect(p.restante(Duration.zero), const Duration(hours: 39, minutes: 15));
      expect(p.restante(const Duration(hours: 2)), const Duration(hours: 37, minutes: 15));
    });

    test('un estado desconocido no se inventa: es una respuesta inesperada', () {
      expect(() => PendienteResumen.fromJson(resumenJson(cumplimiento: 'POR_VENCER')), throwsFormatException);
      expect(() => PendienteResumen.fromJson(resumenJson(estadoEntrega: 'EN_CAMINO')), throwsFormatException);
      expect(() => PendienteResumen.fromJson({...resumenJson(), 'fechaLimite': null}), throwsFormatException);
    });

    test('el detalle incluye medicamentos y novedades, y agregar una novedad suma una al contador', () {
      final d = PendienteDetalle.fromJson(detalleJson());
      expect(d.medicamentos.map((m) => m.medicamentoId), ['MED-ATORVASTATINA-20MG', 'MED-METFORMINA-850MG']);
      expect(d.medicamentos.first.fechaHabilitacion, isNull);
      expect(d.medicamentos.last.estadoEntrega, EstadoEntrega.entregado);
      final nueva = Novedad(id: 'n-2', fechaHora: DateTime.utc(2026, 10, 25), tipo: 'Otra', detalle: 'x');
      final con = d.conNovedad(nueva);
      expect(con.novedades.length, 2);
      expect(con.resumen.cantidadNovedades, d.resumen.cantidadNovedades + 1);
    });

    test('la paginación calcula el rango mostrado y los vecinos', () {
      final items = List.generate(25, (i) => PendienteResumen.fromJson(resumenJson(id: 'id-$i')));
      final segunda = PaginaPendientes(items: items, pagina: 2, limite: 25, total: 60);
      expect((segunda.desde, segunda.hasta), (26, 50));
      expect(segunda.hayAnterior && segunda.haySiguiente, isTrue);
      final ultima = PaginaPendientes(items: items.take(10).toList(), pagina: 3, limite: 25, total: 60);
      expect((ultima.desde, ultima.hasta), (51, 60));
      expect(ultima.haySiguiente, isFalse);
      expect(const PaginaPendientes(items: [], pagina: 1, limite: 25, total: 0).desde, 0);
    });

    test('solo EPS y repartidor registran novedades; el paciente solo consulta', () {
      expect(PendientesRol.fromCode('PATIENT')?.puedeRegistrarNovedad, isFalse);
      expect(PendientesRol.fromCode('EPS')?.puedeRegistrarNovedad, isTrue);
      expect(PendientesRol.fromCode('DELIVERY_DRIVER')?.puedeRegistrarNovedad, isTrue);
      expect(PendientesRol.fromCode('ADMIN'), isNull);
    });
  });

  group('presentación del plazo (PlazoVista)', () {
    test('vigente: tiempo restante, fracción del anillo y texto para lectores de pantalla', () {
      final v = PlazoVista.de(PendienteResumen.fromJson(resumenJson()), Duration.zero);
      expect(v.estado, CumplimientoPlazo.vigente);
      expect(v.titular, '39 h 15 min');
      expect(v.palabraEstado, 'Vigente');
      expect(v.fecha, 'Vence 26 oct 2026, 10:15 a. m.');
      expect(v.fraccion, closeTo(39.25 / 48, 0.001));
      expect((v.centroPrincipal, v.centroSecundario), ('39 h', '15 min'));
      expect(v.semantica, contains('Quedan 39 horas y 15 minutos para la fecha límite'));
      expect(v.semantica, endsWith('Estado: vigente.'));
    });

    test('el reloj avanza con el tiempo transcurrido desde la carga, no con el reloj del dispositivo', () {
      final p = PendienteResumen.fromJson(resumenJson());
      expect(PlazoVista.de(p, const Duration(hours: 2)).titular, '37 h 15 min');
    });

    test('si pasó la fecha límite pero el backend dice vigente, no se declara incumplido: se pide actualizar', () {
      final p = PendienteResumen.fromJson(resumenJson());
      expect(p.vencioSinActualizar(const Duration(hours: 40)), isTrue);
      final v = PlazoVista.de(p, const Duration(hours: 40));
      expect(v.estado, CumplimientoPlazo.vigente);
      expect(v.vencidoSinActualizar, isTrue);
      expect(v.titular, 'Pasó la fecha límite');
    });

    test('incumplido sin entrega: cuánto tiempo lleva vencido', () {
      final p = PendienteResumen.fromJson(
          resumenJson(cumplimiento: 'INCUMPLIDO', evaluadoEn: '2026-10-26T18:25:00.000Z', entregados: 0));
      final v = PlazoVista.de(p, Duration.zero);
      expect((v.titular, v.subtitulo), ('Incumplido', 'Venció hace 3 h 10 min'));
      expect(v.fecha, 'Fecha límite 26 oct 2026, 10:15 a. m.');
    });

    test('incumplido con entrega tardía conserva el incumplimiento y dice cuánto se retrasó', () {
      final p = PendienteResumen.fromJson(resumenJson(
        cumplimiento: 'INCUMPLIDO',
        estadoEntrega: 'ENTREGADO',
        fechaEntrega: '2026-10-26T17:20:00.000Z',
        entregados: 3,
      ));
      final v = PlazoVista.de(p, Duration.zero);
      expect(v.titular, 'Incumplido');
      expect(v.subtitulo, 'Entregado 2 h 5 min después del límite');
      expect(v.fecha, 'Entregado 26 oct 2026, 12:20 p. m.');
    });

    test('cumplido: entregado a tiempo', () {
      final p = PendienteResumen.fromJson(resumenJson(
        cumplimiento: 'CUMPLIDO',
        estadoEntrega: 'ENTREGADO',
        fechaEntrega: '2026-10-25T21:40:00.000Z',
        entregados: 3,
      ));
      final v = PlazoVista.de(p, Duration.zero);
      expect((v.titular, v.subtitulo), ('Cumplido', 'Entregado a tiempo'));
      expect(v.fecha, 'Entregado 25 oct 2026, 4:40 p. m.');
    });
  });

  group('PendientesService', () {
    test('listar envía el token, la paginación y los filtros por la URL', () async {
      late http.Request visto;
      final service = serviceWith((request) async {
        visto = request;
        return ok(paginaJson([resumenJson()]));
      });
      final pagina = await service.listar(
        estado: EstadoEntrega.pendiente,
        ordenMedicamentoId: ' PED-1 ',
        pagina: 2,
        limite: 50,
      );
      expect(pagina.items.single.ordenMedicamentoId, 'PED-2026-000123');
      expect(visto.method, 'GET');
      expect(visto.url.path, '/pendientes');
      expect(visto.url.queryParameters, {
        'pagina': '2',
        'limite': '50',
        'estadoEntrega': 'PENDIENTE',
        'ordenMedicamentoId': 'PED-1',
      });
      expect(visto.headers['Authorization'], 'Bearer token-1');
    });

    test('sin filtros no se envían parámetros vacíos', () async {
      late http.Request visto;
      final service = serviceWith((request) async {
        visto = request;
        return ok(paginaJson([]));
      });
      await service.listar(ordenMedicamentoId: '  ');
      expect(visto.url.queryParameters.keys, unorderedEquals(['pagina', 'limite']));
    });

    test('detalle y registro de novedad usan las rutas del contrato', () async {
      final vistos = <http.Request>[];
      final service = serviceWith((request) async {
        vistos.add(request);
        if (request.method == 'POST') {
          return ok({'id': 'n-9', 'fechaHora': '2026-10-25T01:00:00.000Z', 'tipo': 'Llamada', 'detalle': 'Contestó'}, 201);
        }
        return ok(detalleJson());
      });
      final d = await service.detalle('3f2b8f0e-5b1e-4f57-9d58-1c6a1f0a0001');
      expect(d.novedades, hasLength(1));
      final n = await service.registrarNovedad('3f2b8f0e-5b1e-4f57-9d58-1c6a1f0a0001', tipo: 'Llamada', detalle: 'Contestó');
      expect(n.id, 'n-9');
      expect(vistos.first.url.path, '/pendientes/3f2b8f0e-5b1e-4f57-9d58-1c6a1f0a0001');
      expect(vistos.last.method, 'POST');
      expect(vistos.last.url.path, '/pendientes/3f2b8f0e-5b1e-4f57-9d58-1c6a1f0a0001/novedades');
      expect(jsonDecode(vistos.last.body), {'tipo': 'Llamada', 'detalle': 'Contestó'});
    });

    Future<AppError> fallo(int status) async {
      final service = serviceWith((_) async => ok({
            'statusCode': status,
            'error': 'Error',
            'message': 'texto técnico que nunca se muestra',
            'path': '/pendientes/x',
            'timestamp': '2026-10-25T00:00:00.000Z',
          }, status));
      try {
        await service.detalle('x');
      } on AppError catch (error) {
        return error;
      }
      fail('Debía fallar');
    }

    test('los errores de NestJS se traducen por estado, sin mostrar el texto técnico', () async {
      final prohibido = await fallo(403);
      expect(prohibido.kind, AppErrorKind.forbidden);
      expect(prohibido.userMessage, ErrorMessages.pendienteForbidden);

      final noExiste = await fallo(404);
      expect(noExiste.kind, AppErrorKind.notFound);
      expect(noExiste.userMessage, ErrorMessages.pendienteNotFound);

      final sesion = await fallo(401);
      expect(sesion.endsSession, isTrue);

      final servidor = await fallo(500);
      expect(servidor.kind, AppErrorKind.server);
      expect(servidor.userMessage, isNot(contains('técnico')));
    });

    test('una respuesta con otra forma es una respuesta inesperada, no un cierre de la app', () async {
      final service = serviceWith((_) async => ok({'items': 'no es una lista', 'pagina': 1}));
      await expectLater(
        service.listar(),
        throwsA(isA<AppError>().having((e) => e.kind, 'kind', AppErrorKind.invalidResponse)),
      );
    });
  });

  group('PendientesListController', () {
    test('carga la primera página y los filtros reinician la paginación', () async {
      final consultas = <Map<String, String>>[];
      final controller = PendientesListController(serviceWith((request) async {
        consultas.add(request.url.queryParameters);
        return ok(paginaJson([resumenJson()], total: 80));
      }));
      await controller.load();
      expect(controller.pagina?.total, 80);
      await controller.siguiente();
      expect(consultas.last['pagina'], '2');
      await controller.cambiarEstado(EstadoEntrega.entregado);
      expect(consultas.last['pagina'], '1');
      expect(consultas.last['estadoEntrega'], 'ENTREGADO');
      await controller.buscar('  PED-9 ');
      expect(consultas.last['ordenMedicamentoId'], 'PED-9');
      expect(controller.filtrosActivos, isTrue);
      await controller.quitarFiltros();
      expect(consultas.last.containsKey('estadoEntrega'), isFalse);
      expect(controller.filtrosActivos, isFalse);
    });

    test('una respuesta tardía no pisa a una consulta más nueva', () async {
      final lenta = Completer<http.Response>();
      var llamadas = 0;
      final controller = PendientesListController(serviceWith((request) {
        llamadas++;
        if (llamadas == 1) return lenta.future;
        return Future.value(ok(paginaJson([resumenJson(id: 'nuevo')], pagina: 2, total: 40)));
      }));
      final primera = controller.load();
      await controller.load(page: 2);
      lenta.complete(ok(paginaJson([resumenJson(id: 'viejo')], total: 40)));
      await primera;
      expect(controller.pagina?.items.single.id, 'nuevo');
      expect(controller.loading, isFalse);
    });

    test('un error conserva la página anterior y se puede reintentar', () async {
      var falla = false;
      final controller = PendientesListController(serviceWith((_) async =>
          falla ? ok({'statusCode': 500}, 500) : ok(paginaJson([resumenJson()]))));
      await controller.load();
      falla = true;
      await controller.recargar();
      expect(controller.error?.kind, AppErrorKind.server);
      expect(controller.pagina, isNotNull);
      falla = false;
      await controller.recargar();
      expect(controller.error, isNull);
    });

    test('si la página pedida ya no existe, vuelve a la primera', () async {
      final controller = PendientesListController(serviceWith((request) async {
        final pagina = int.parse(request.url.queryParameters['pagina']!);
        return ok(pagina > 1 ? paginaJson([], pagina: pagina, total: 3) : paginaJson([resumenJson()], total: 3));
      }));
      await controller.load(page: 4);
      expect(controller.pagina?.pagina, 1);
      expect(controller.pagina?.items, hasLength(1));
    });

    test('al cambiar la sesión se olvida todo', () async {
      final controller = PendientesListController(serviceWith((_) async => ok(paginaJson([resumenJson()]))));
      await controller.load();
      controller.clear();
      expect(controller.pagina, isNull);
      expect(controller.error, isNull);
      await controller.loadIfNeeded();
      expect(controller.pagina, isNotNull);
    });
  });

  group('PendienteDetailController', () {
    const id = '3f2b8f0e-5b1e-4f57-9d58-1c6a1f0a0001';

    test('registrar una novedad la agrega sin recargar', () async {
      final controller = PendienteDetailController(
          serviceWith((request) async => request.method == 'POST'
              ? ok({'id': 'n-2', 'fechaHora': '2026-10-25T01:00:00.000Z', 'tipo': 'Llamada', 'detalle': 'ok'}, 201)
              : ok(detalleJson())),
          id);
      await controller.load();
      expect(controller.detalle?.novedades, hasLength(1));
      final error = await controller.registrarNovedad(tipo: 'Llamada', detalleNovedad: 'ok');
      expect(error, isNull);
      expect(controller.detalle?.novedades, hasLength(2));
      expect(controller.detalle?.resumen.cantidadNovedades, 2);
      expect(controller.submitting, isFalse);
    });

    test('si el registro falla, devuelve el error y conserva el detalle', () async {
      final controller = PendienteDetailController(
          serviceWith((request) async => request.method == 'POST' ? ok({'statusCode': 403}, 403) : ok(detalleJson())), id);
      await controller.load();
      final error = await controller.registrarNovedad(tipo: 'x', detalleNovedad: 'y');
      expect(error?.kind, AppErrorKind.forbidden);
      expect(controller.detalle?.novedades, hasLength(1));
    });

    test('si el plazo venció y el backend aún dice vigente, vuelve a consultar una sola vez', () async {
      var llamadas = 0;
      final controller = PendienteDetailController(
          serviceWith((_) async {
            llamadas++;
            // evaluadoEn posterior al límite pero todavía "VIGENTE": estado desactualizado.
            return ok(detalleJson(resumen: resumenJson(evaluadoEn: '2026-10-26T16:00:00.000Z')));
          }),
          id);
      await controller.load();
      expect(llamadas, 1);
      await controller.actualizarSiVencio();
      expect(llamadas, 2);
      await controller.actualizarSiVencio();
      expect(llamadas, 2, reason: 'no debe entrar en un ciclo de consultas');
    });

    test('un error al actualizar no borra el contenido que ya se mostraba', () async {
      var falla = false;
      final controller = PendienteDetailController(
          serviceWith((_) async => falla ? ok({'statusCode': 500}, 500) : ok(detalleJson())), id);
      await controller.load();
      falla = true;
      await controller.load(silencioso: true);
      expect(controller.error, isNotNull);
      expect(controller.detalle, isNotNull);
    });
  });
}
