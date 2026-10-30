import '../errors/error_mapper.dart';
import '../types/pendiente.dart';
import 'authorized_json_client.dart';

/// Cliente de `pendientes-service`: consulta pendientes y registra novedades.
///
/// Las llamadas llevan el access token de Auth (`Authorization: Bearer`). El backend decide qué
/// ve cada rol (paciente: los suyos; EPS: los asignados; repartidor: todos), así que el cliente
/// no envía filtros de dueño. Los mensajes de integración (creación, habilitación, entrega) no
/// pertenecen a esta pantalla y no se exponen aquí.
class PendientesService {
  PendientesService(this._client);

  final AuthorizedJsonClient _client;

  Future<PaginaPendientes> listar({
    EstadoEntrega? estado,
    String? ordenMedicamentoId,
    int pagina = 1,
    int limite = 25,
  }) async {
    final consulta = <String, String>{
      'pagina': '$pagina',
      'limite': '$limite',
      if (estado != null) 'estadoEntrega': estado.wire,
      if (ordenMedicamentoId != null && ordenMedicamentoId.trim().isNotEmpty)
        'ordenMedicamentoId': ordenMedicamentoId.trim(),
    };
    final ruta = Uri(path: '/pendientes', queryParameters: consulta).toString();
    return _convertir(await _client.get(ruta), PaginaPendientes.fromJson);
  }

  Future<PendienteDetalle> detalle(String id) async =>
      _convertir(await _client.get('/pendientes/${Uri.encodeComponent(id)}'), PendienteDetalle.fromJson);

  /// Registra una novedad (roles EPS y repartidor). `tipo` es texto libre provisional.
  Future<Novedad> registrarNovedad(String id, {required String tipo, required String detalle}) async =>
      _convertir(
        await _client.post('/pendientes/${Uri.encodeComponent(id)}/novedades', {'tipo': tipo, 'detalle': detalle}),
        Novedad.fromJson,
      );

  /// Una respuesta con forma inesperada se vuelve un error de "respuesta inesperada", no un cierre.
  static T _convertir<T>(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    try {
      return fromJson(json);
    } on FormatException catch (error) {
      throw ErrorMapper.fromException(error);
    } on TypeError catch (error) {
      throw ErrorMapper.fromException(FormatException('Respuesta de pendientes inesperada: $error'));
    }
  }
}
