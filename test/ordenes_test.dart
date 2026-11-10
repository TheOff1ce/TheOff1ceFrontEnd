import 'dart:convert';
import 'dart:io';

import 'package:farma_go/components/farmago/ordenes/orden_sellos.dart';
import 'package:farma_go/errors/app_error.dart';
import 'package:farma_go/errors/error_mapper.dart';
import 'package:farma_go/hooks/domicilio_orden_controller.dart';
import 'package:farma_go/hooks/ordenes_controller.dart';
import 'package:farma_go/types/ordenes.dart';
import 'package:farma_go/utils/pendiente_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support/ordenes_fakes.dart';

void main() {
  group('modelos tolerantes', () {
    test('un valor desconocido no lanza: pasa a sin información o desconocido', () {
      final m = MedicamentoOrden.fromJson(medicamentoJson(
        autorizacion: 'ALGO_NUEVO',
        reclamacion: 'OTRA_COSA',
        elegible: false,
        motivos: ['MOTIVO_FUTURO', 'YA_RECLAMADO'],
      ));
      expect(m.autorizacion, Autorizacion.sinInformacion);
      expect(m.reclamacion, Reclamacion.sinInformacion);
      expect(m.motivosNoElegible, [MotivoNoElegible.desconocido, MotivoNoElegible.yaReclamado]);
      expect(Orden.fromJson(ordenJson(vigencia: 'RARA')).vigencia, Vigencia.sinInformacion);
    });

    test('lee los estados con los nombres del contrato del backend', () {
      // Claves literales de docs/contratos/openapi.json de ordenes-service, no del fake.
      final m = MedicamentoOrden.fromJson({
        'medicamentoId': 'MED-1',
        'dci': 'Losartán',
        'concentracion': '50 mg',
        'estadoAutorizacion': 'AUTORIZADO',
        'estadoReclamacion': 'PENDIENTE_DE_RECLAMAR',
        'elegibleParaDomicilio': true,
      });
      expect(m.autorizacion, Autorizacion.autorizado);
      expect(m.reclamacion, Reclamacion.pendienteDeReclamar);
    });

    test('eps nula y orden sin vencimiento se leen sin error', () {
      final r = RespuestaOrdenes.fromJson(respuestaJson(eps: null, ordenes: [ordenSinVencimientoJson()]));
      expect(r.eps, isNull);
      expect(r.ordenes.single.vencimiento, isNull);
      expect(r.proximoVencimiento, isNull);
    });

    test('las cifras salen solo de banderas del backend', () {
      final r = RespuestaOrdenes.fromJson(respuestaJson());
      expect(r.totalElegibles, 2);
      expect(r.totalPorAutorizar, 1);
      // Solo cuenta VIGENTE: la vencida y la «sin información» quedan fuera.
      expect(r.vigentes.length, 1);
    });

    test('un cuerpo sin fecha de consulta es una respuesta inválida', () {
      expect(() => RespuestaOrdenes.fromJson({'ordenes': <Object>[]}), throwsFormatException);
    });
  });

  group('ErrorMapper.fromOrdenes', () {
    test('mapea por code y conserva los detalles', () {
      final e = ErrorMapper.fromOrdenes(409, {
        'code': 'ELEGIBILIDAD_CAMBIADA',
        'detalles': {'cambios': <Object>[]},
      });
      expect(e.kind, AppErrorKind.conflict);
      expect(e.code, 'ELEGIBILIDAD_CAMBIADA');
      expect(e.detalles, isNotNull);
    });

    test('lee el code anidado en error', () {
      final e = ErrorMapper.fromOrdenes(403, {
        'error': {'code': 'AFILIACION_SUSPENDIDA'},
      });
      expect(e.kind, AppErrorKind.forbidden);
      expect(e.retryable, isFalse);
    });

    test('429, 503 y 504 sin code caen por estado HTTP y se pueden reintentar', () {
      expect(ErrorMapper.fromOrdenes(429, const {}).kind, AppErrorKind.rateLimit);
      expect(ErrorMapper.fromOrdenes(503, const {}).kind, AppErrorKind.server);
      expect(ErrorMapper.fromOrdenes(504, const {}).kind, AppErrorKind.timeout);
      expect(ErrorMapper.fromOrdenes(503, const {}).retryable, isTrue);
    });

    test('los códigos EPS_* son errores con reintento y nunca muestran el mensaje del backend', () {
      final e = ErrorMapper.fromOrdenes(502, {'code': 'EPS_TIMEOUT', 'message': 'detalle técnico'});
      expect(e.retryable, isTrue);
      expect(e.userMessage, isNot(contains('técnico')));
    });
  });

  test('el módulo de órdenes no escribe nada en almacenamiento local', () {
    final archivos = [
      'lib/types/ordenes.dart',
      'lib/services/ordenes_service.dart',
      'lib/hooks/ordenes_controller.dart',
      'lib/hooks/domicilio_orden_controller.dart',
      'lib/pages/ordenes_page.dart',
    ];
    for (final ruta in archivos) {
      final texto = File(ruta).readAsStringSync();
      expect(texto, isNot(contains('shared_preferences')), reason: ruta);
      expect(texto, isNot(contains('flutter_secure_storage')), reason: ruta);
      expect(texto, isNot(contains('RestorationMixin')), reason: ruta);
      expect(texto, isNot(contains('dart:io')), reason: ruta);
    }
  });

  group('fechas en Bogotá', () {
    test('12:xx a. m. y 12:xx p. m. no se convierten en 0:xx', () {
      expect(PendienteFormat.hora(DateTime.utc(2026, 11, 7, 5, 5)), '12:05 a. m.');
      expect(PendienteFormat.hora(DateTime.utc(2026, 11, 7, 17, 30)), '12:30 p. m.');
      expect(PendienteFormat.fechaHora(DateTime.parse(consultadoEnPrueba)), '6 nov 2026, 10:27 p. m.');
    });
  });

  group('arco de vigencia', () {
    test('se calcula contra consultadoEn y no contra el reloj del dispositivo', () {
      final orden = Orden.fromJson(ordenJson(fechaOrden: '2026-10-20T00:00:00Z', vencimiento: '2026-11-20T00:00:00Z'));
      final arco = ArcoOrden.de(orden, DateTime.utc(2026, 11, 10));
      expect(arco.fraccion, closeTo(10 / 31, 1e-9));
      expect(arco.principal, '10');
      expect(arco.titulo, 'Vence en 10 días');
    });

    test('con menos de un día muestra horas y con menos de una hora, minutos', () {
      final orden = Orden.fromJson(ordenJson(fechaOrden: '2026-10-20T00:00:00Z', vencimiento: '2026-11-20T12:00:00Z'));
      expect(ArcoOrden.de(orden, DateTime.utc(2026, 11, 20, 0)).titulo, 'Vence en 12 h');
      expect(ArcoOrden.de(orden, DateTime.utc(2026, 11, 20, 11, 20)).titulo, 'Vence en 40 min');
    });
  });

  group('OrdenesController', () {
    test('carga y entrega la respuesta; el filtro es local y no consulta otra vez', () async {
      var consultas = 0;
      final c = OrdenesController(servicioFeliz(alVer: (r) {
        if (r.url.path == '/ordenes') consultas++;
      }));
      await c.recargar();
      expect(c.vista, isA<ConOrdenes>());
      final entrada = c.entradaId;
      c.cambiarFiltro(FiltroOrdenes.vencidas);
      expect(c.visibles.map((o) => o.id), ['PED-2026-000187']);
      expect(consultas, 1);
      expect(c.entradaId, entrada, reason: 'el filtro no reproduce la entrada del panel');
      expect(c.conteo(FiltroOrdenes.porAutorizar), 1);
    });

    test('una orden vacía produce el estado Vacío', () async {
      final c = OrdenesController(servicioFeliz(lista: respuestaJson(ordenes: [])));
      await c.recargar();
      expect(c.vista, isA<Vacio>());
    });

    test('la selección nunca mezcla órdenes', () async {
      final c = OrdenesController(servicioFeliz(lista: respuestaJson(ordenes: [
        ordenJson(),
        ordenJson(id: 'PED-2026-000201', medicamentos: [medicamentoJson(id: 'MED-OTRO')]),
      ])));
      await c.recargar();
      final a = c.respuesta!.ordenes[0];
      final b = c.respuesta!.ordenes[1];
      c.alternar(a, a.medicamentos[0]);
      c.alternar(a, a.medicamentos[1]);
      expect(c.seleccion!.ids.length, 2);
      c.alternar(b, b.medicamentos[0]);
      expect(c.seleccion!.ordenId, b.id);
      expect(c.seleccion!.ids, {'MED-OTRO'});
    });

    test('no se pueden marcar medicamentos no elegibles ni de órdenes de solo lectura', () async {
      final c = OrdenesController(servicioFeliz());
      await c.recargar();
      final orden = c.respuesta!.ordenes.first;
      c.alternar(orden, orden.medicamentos[2]); // por autorizar
      expect(c.seleccion, isNull);
      final vencida = c.respuesta!.ordenes[1];
      c.alternar(vencida, vencida.medicamentos.first);
      expect(c.seleccion, isNull);
    });

    test('recargar vacía la selección, el filtro y el aviso de éxito', () async {
      final c = OrdenesController(servicioFeliz());
      await c.recargar();
      final orden = c.respuesta!.ordenes.first;
      c.alternar(orden, orden.medicamentos.first);
      c.cambiarFiltro(FiltroOrdenes.domicilio);
      await c.recargar();
      expect(c.seleccion, isNull);
      expect(c.filtro, FiltroOrdenes.todas);
      expect(c.exito, isNull);
    });

    test('un error vacía la vista: no queda ningún dato de la consulta anterior', () async {
      var falla = false;
      final c = OrdenesController(servicioCon((r) async => falla ? http.Response('{}', 503) : ok(respuestaJson())));
      await c.recargar();
      expect(c.respuesta, isNotNull);
      falla = true;
      await c.recargar();
      expect(c.vista, isA<ErrorConsulta>());
      expect(c.respuesta, isNull);
    });

    test('los bloqueos de afiliación se leen del code y no del mensaje', () async {
      Future<OrdenesVista> con(String code, [Map<String, dynamic>? detalles]) async {
        final c = OrdenesController(servicioCon((r) async => ok({'code': code, 'detalles': detalles}, 403)));
        await c.recargar();
        return c.vista;
      }

      final rectificar = await con('AFILIACION_NO_ENCONTRADA', {'documentoEnmascarado': 'CC •••• 0099'}) as Bloqueado;
      expect(rectificar.tipo, BloqueoTipo.rectificar);
      expect(rectificar.documento, 'CC •••• 0099');
      expect((await con('AFILIACION_RETIRADA')) as Bloqueado, isA<Bloqueado>());
      expect(((await con('DOCUMENTO_NO_REGISTRADO')) as Bloqueado).tipo, BloqueoTipo.sinDocumento);
    });

    test('avisa a los 10 s con un reloj corto de prueba', () async {
      final c = OrdenesController(
        servicioCon((r) => Future.delayed(const Duration(milliseconds: 80), () => ok(respuestaJson()))),
        avisoLento: const Duration(milliseconds: 10),
      );
      final carga = c.recargar();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(c.vista, isA<Cargando>());
      expect((c.vista as Cargando).lento, isTrue);
      await carga;
      expect(c.vista, isA<ConOrdenes>());
    });
  });

  group('DomicilioOrdenController', () {
    test('verifica, envía y entrega la referencia sin recargar la lista', () async {
      var listas = 0;
      final service = servicioFeliz(alVer: (r) {
        if (r.method == 'GET') listas++;
      });
      final orden = Orden.fromJson(ordenJson());
      final d = DomicilioOrdenController(
        service: service,
        orden: orden,
        medicamentoIds: ['MED-METFORMINA-850', 'MED-LOSARTAN-50'],
        escalon: Duration.zero,
      );
      await d.verificar();
      expect(d.fase, FaseDomicilio.listo);
      expect(d.revelados, 2);
      await d.confirmar();
      expect(d.fase, FaseDomicilio.exito);
      expect(d.referencia, 'DOM-3f1c');
      expect(listas, 0);
      d.dispose();
    });

    test('la verificación solo juzga los medicamentos elegidos, aunque el backend devuelva toda la orden', () async {
      // El backend responde la elegibilidad de todos los medicamentos de la orden.
      final service = servicioCon((r) async {
        if (r.url.path.endsWith('/domicilio/verificacion')) {
          return ok({
            'medicamentos': [
              {'medicamentoId': 'MED-METFORMINA', 'elegible': false, 'motivos': ['YA_RECLAMADO']},
              {'medicamentoId': 'MED-LOSARTAN', 'elegible': true, 'motivos': <String>[]},
            ],
          });
        }
        return ok({});
      });
      final d = DomicilioOrdenController(
        service: service,
        orden: Orden.fromJson(ordenJson()),
        medicamentoIds: ['MED-LOSARTAN'],
        escalon: Duration.zero,
      );
      await d.verificar();
      expect(d.fase, FaseDomicilio.listo);
      expect(d.cambios, isEmpty);
      d.dispose();
    });

    test('un medicamento elegido que no vuelve en la verificación cuenta como cambio', () async {
      final service = servicioCon((r) async {
        if (r.url.path.endsWith('/domicilio/verificacion')) {
          return ok({
            'medicamentos': [
              {'medicamentoId': 'MED-LOSARTAN', 'elegible': true, 'motivos': <String>[]},
            ],
          });
        }
        return ok({});
      });
      final d = DomicilioOrdenController(
        service: service,
        orden: Orden.fromJson(ordenJson()),
        medicamentoIds: ['MED-LOSARTAN', 'MED-OTRO'],
        escalon: Duration.zero,
      );
      await d.verificar();
      expect(d.fase, FaseDomicilio.listoConCambios);
      expect(d.cambios.map((c) => c.id), ['MED-OTRO']);
      expect(d.cambios.single.motivos, [MotivoNoElegible.noPerteneceALaOrden]);
      d.dispose();
    });

    test('el reintento reutiliza el solicitudId y una selección nueva genera otro', () async {
      final ids = <String>[];
      var intentos = 0;
      final service = servicioCon((r) async {
        if (r.url.path.endsWith('/domicilio') && r.method == 'POST') {
          ids.add(jsonDecode(r.body)['solicitudId'] as String);
          intentos++;
          return intentos == 1 ? ok({'code': 'DOMICILIO_NO_DISPONIBLE'}, 503) : ok({'referencia': 'DOM-1'}, 202);
        }
        return ok({});
      });
      final orden = Orden.fromJson(ordenJson());
      final d = DomicilioOrdenController(service: service, orden: orden, medicamentoIds: ['MED-METFORMINA-850']);
      await d.confirmar();
      expect(d.fase, FaseDomicilio.errorEnvio);
      await d.confirmar();
      expect(d.fase, FaseDomicilio.exito);
      expect(ids.length, 2);
      expect(ids[0], ids[1]);
      expect(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(ids[0]), isTrue);
      final otro = DomicilioOrdenController(service: service, orden: orden, medicamentoIds: ['MED-METFORMINA-850']);
      await otro.confirmar();
      expect(ids.last, isNot(ids.first));
      d.dispose();
      otro.dispose();
    });

    test('un 409 de elegibilidad reemplaza la orden en su lugar y ajusta la selección', () async {
      final cambiada = ordenJson(medicamentos: [
        medicamentoJson(elegible: false, reclamacion: 'RECLAMADO', motivos: ['YA_RECLAMADO']),
        medicamentoJson(id: 'MED-LOSARTAN-50', dci: 'Losartán', concentracion: '50 mg', autorizacion: 'NO_REQUIERE'),
      ]);
      final service = servicioCon((r) async {
        if (r.method == 'GET') return ok(respuestaJson());
        if (r.url.path.endsWith('/verificacion')) {
          return ok({
            'medicamentos': [
              {'medicamentoId': 'MED-METFORMINA-850', 'elegible': true},
              {'medicamentoId': 'MED-LOSARTAN-50', 'elegible': true},
            ],
          });
        }
        return ok({
          'code': 'ELEGIBILIDAD_CAMBIADA',
          'detalles': {
            'orden': cambiada,
            'cambios': [
              {'medicamentoId': 'MED-METFORMINA-850', 'motivos': ['YA_RECLAMADO']},
            ],
          },
        }, 409);
      });
      final c = OrdenesController(service);
      await c.recargar();
      final primera = c.respuesta!.ordenes.first;
      c.alternar(primera, primera.medicamentos[0]);
      c.alternar(primera, primera.medicamentos[1]);
      final posicion = c.respuesta!.ordenes.indexWhere((o) => o.id == primera.id);
      final d = c.nuevoDomicilio();
      await d.verificar();
      await d.confirmar();
      expect(d.fase, FaseDomicilio.cambio);
      c.aplicarResultado(d);
      expect(c.respuesta!.ordenes.indexWhere((o) => o.id == primera.id), posicion);
      expect(c.respuesta!.ordenes[posicion].medicamentos.first.elegibleParaDomicilio, isFalse);
      expect(c.seleccion!.ids, {'MED-LOSARTAN-50'});
      expect(c.actualizados, contains('MED-METFORMINA-850'));
      d.dispose();
    });

    test('un 409 por vencimiento deja la orden en solo lectura y vacía la selección', () async {
      final service = servicioCon((r) async {
        if (r.method == 'GET') return ok(respuestaJson());
        if (r.url.path.endsWith('/verificacion')) {
          return ok({
            'medicamentos': [
              {'medicamentoId': 'MED-METFORMINA-850', 'elegible': true},
            ],
          });
        }
        return ok({'code': 'ORDEN_VENCIDA'}, 409);
      });
      final c = OrdenesController(service);
      await c.recargar();
      final primera = c.respuesta!.ordenes.first;
      c.alternar(primera, primera.medicamentos[0]);
      final d = c.nuevoDomicilio();
      await d.verificar();
      await d.confirmar();
      expect(d.fase, FaseDomicilio.vencida);
      c.aplicarResultado(d);
      final actual = c.respuesta!.ordenes.firstWhere((o) => o.id == primera.id);
      expect(actual.vigencia, Vigencia.vencida);
      expect(actual.admiteSeleccion, isFalse);
      expect(c.seleccion, isNull);
      d.dispose();
    });

    test('con el envío aceptado la lista no se recarga sola y queda el aviso con la referencia', () async {
      final c = OrdenesController(servicioFeliz());
      await c.recargar();
      final primera = c.respuesta!.ordenes.first;
      c.alternar(primera, primera.medicamentos[0]);
      final antes = c.entradaId;
      final d = c.nuevoDomicilio();
      await d.verificar();
      await d.confirmar();
      c.aplicarResultado(d);
      expect(c.exito!.referencia, 'DOM-3f1c');
      expect(c.seleccion, isNull);
      expect(c.entradaId, antes);
      d.dispose();
    });
  });
}
