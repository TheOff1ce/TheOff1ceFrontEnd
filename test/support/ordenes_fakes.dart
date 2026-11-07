import 'dart:convert';

import 'package:farma_go/errors/error_mapper.dart';
import 'package:farma_go/services/access_token_source.dart';
import 'package:farma_go/services/authorized_json_client.dart';
import 'package:farma_go/services/ordenes_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Hora de la consulta de las capturas: 6 nov 2026, 10:27 p. m. en Bogotá.
const consultadoEnPrueba = '2026-11-07T03:27:00Z';

class FakeTokens implements AccessTokenSource {
  @override
  Future<String?> currentAccessToken({bool forceRefresh = false}) async => 'token-1';
}

Map<String, dynamic> medicamentoJson({
  String id = 'MED-METFORMINA-850',
  String dci = 'Metformina',
  String concentracion = '850 mg',
  String forma = 'Tableta',
  int cantidad = 60,
  String unidad = 'unidades',
  String laboratorio = 'Laboratorio Simulado',
  String autorizacion = 'AUTORIZADO',
  String reclamacion = 'PENDIENTE_DE_RECLAMAR',
  bool elegible = true,
  List<String> motivos = const [],
}) =>
    {
      'medicamentoId': id,
      'dci': dci,
      'concentracion': concentracion,
      'formaFarmaceutica': forma,
      'cantidad': cantidad,
      'unidad': unidad,
      'laboratorioFabricante': laboratorio,
      'autorizacion': autorizacion,
      'reclamacion': reclamacion,
      'elegibleParaDomicilio': elegible,
      'motivosNoElegible': motivos,
    };

Map<String, dynamic> ordenJson({
  String id = 'PED-2026-000200',
  String fechaOrden = '2026-10-22T15:00:00Z',
  String? vencimiento = '2026-11-13T06:47:00Z',
  String vigencia = 'VIGENTE',
  bool permiteDomicilio = true,
  bool soloLectura = false,
  List<Map<String, dynamic>>? medicamentos,
}) =>
    {
      'ordenId': id,
      'fechaOrden': fechaOrden,
      'vencimiento': vencimiento,
      'vigencia': vigencia,
      'permiteDomicilio': permiteDomicilio,
      'soloLectura': soloLectura,
      'medicamentos': medicamentos ??
          [
            medicamentoJson(),
            medicamentoJson(
              id: 'MED-LOSARTAN-50',
              dci: 'Losartán',
              concentracion: '50 mg',
              cantidad: 30,
              autorizacion: 'NO_REQUIERE',
            ),
            medicamentoJson(
              id: 'MED-INSULINA-100',
              dci: 'Insulina glargina',
              concentracion: '100 UI/mL',
              forma: 'Solución inyectable',
              cantidad: 3,
              autorizacion: 'POR_AUTORIZAR',
              elegible: false,
              motivos: ['AUTORIZACION_PENDIENTE'],
            ),
          ],
    };

Map<String, dynamic> ordenVencidaJson() => ordenJson(
      id: 'PED-2026-000187',
      fechaOrden: '2026-09-02T15:00:00Z',
      vencimiento: '2026-10-30T15:00:00Z',
      vigencia: 'VENCIDA',
      permiteDomicilio: false,
      soloLectura: true,
      medicamentos: [
        medicamentoJson(
          id: 'MED-ATORVASTATINA-20',
          dci: 'Atorvastatina',
          concentracion: '20 mg',
          reclamacion: 'RECLAMADO',
          elegible: false,
          motivos: ['ORDEN_VENCIDA'],
        ),
      ],
    );

Map<String, dynamic> ordenSinVencimientoJson() => ordenJson(
      id: 'PED-2026-000150',
      vencimiento: null,
      vigencia: 'SIN_INFORMACION',
      permiteDomicilio: false,
      medicamentos: [
        medicamentoJson(
          id: 'MED-OMEPRAZOL-20',
          dci: 'Omeprazol',
          concentracion: '20 mg',
          forma: 'Cápsula',
          autorizacion: 'SIN_INFORMACION',
          reclamacion: 'SIN_INFORMACION',
          elegible: false,
          motivos: ['ORDEN_SIN_VENCIMIENTO', 'AUTORIZACION_SIN_INFORMACION'],
        ),
      ],
    );

Map<String, dynamic> respuestaJson({List<Map<String, dynamic>>? ordenes, String? eps = 'EPS Demo'}) => {
      'consultadoEn': consultadoEnPrueba,
      'eps': eps == null ? null : {'nombre': eps},
      'documentoEnmascarado': 'CC •••• 0099',
      'ordenes': ordenes ?? [ordenJson(), ordenVencidaJson(), ordenSinVencimientoJson()],
    };

http.Response ok(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

OrdenesService servicioCon(MockClientHandler handler) => OrdenesService(AuthorizedJsonClient(
      'https://ordenes.example',
      tokens: FakeTokens(),
      client: MockClient(handler),
      timeout: const Duration(seconds: 5),
      errorMapper: ErrorMapper.fromOrdenes,
    ));

/// Servicio con las respuestas felices de la lista, la verificación y el envío.
OrdenesService servicioFeliz({
  Map<String, dynamic>? lista,
  void Function(http.Request)? alVer,
}) =>
    servicioCon((request) async {
      alVer?.call(request);
      final ruta = request.url.path;
      if (request.method == 'GET' && ruta == '/v1/ordenes') return ok(lista ?? respuestaJson());
      if (ruta.endsWith('/domicilio/verificacion')) {
        final ids = (jsonDecode(request.body)['medicamentoIds'] as List).cast<String>();
        return ok({
          'medicamentos': [for (final id in ids) {'medicamentoId': id, 'elegible': true, 'motivos': <String>[]}],
        });
      }
      if (ruta.endsWith('/domicilio')) return ok({'referencia': 'DOM-3f1c'}, 202);
      return http.Response('{}', 404);
    });
