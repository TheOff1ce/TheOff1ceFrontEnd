import '../errors/error_mapper.dart';
import '../types/ordenes.dart';
import 'authorized_json_client.dart';

/// Cliente del servicio de órdenes y autorizaciones. Consulta a la EPS en vivo en cada llamada.
///
/// Sin reintentos ni caché: una consulta fallida nunca se reemplaza por datos anteriores (AC-22).
/// La identidad sale de la sesión; el cliente no envía documento, tipo de documento ni EPS.
/// Este servicio no tiene relación con `OrderService` (domicilios) ni con `/orders`.
class OrdenesService {
  OrdenesService(this._client);

  final AuthorizedJsonClient _client;

  Future<RespuestaOrdenes> listar() async => _convertir(await _client.get('/v1/ordenes'), RespuestaOrdenes.fromJson);

  Future<Orden> detalle(String ordenId) async =>
      _convertir(await _client.get('/v1/ordenes/${Uri.encodeComponent(ordenId)}'), Orden.fromJson);

  /// Vuelve a consultar a la EPS si los medicamentos elegidos siguen disponibles. No envía nada.
  Future<VerificacionDomicilio> verificarDomicilio(String ordenId, List<String> medicamentoIds) async => _convertir(
        await _client.post(
          '/v1/ordenes/${Uri.encodeComponent(ordenId)}/domicilio/verificacion',
          {'medicamentoIds': medicamentoIds},
        ),
        VerificacionDomicilio.fromJson,
      );

  /// Envía el pedido a Domicilios. `solicitudId` es idempotente: se reutiliza en cada reintento.
  Future<DomicilioAceptado> enviarDomicilio(String ordenId, String solicitudId, List<String> medicamentoIds) async =>
      _convertir(
        await _client.post(
          '/v1/ordenes/${Uri.encodeComponent(ordenId)}/domicilio',
          {'solicitudId': solicitudId, 'medicamentoIds': medicamentoIds},
        ),
        DomicilioAceptado.fromJson,
      );

  /// Una respuesta con forma inesperada se vuelve un error de «respuesta inesperada», no un cierre.
  static T _convertir<T>(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    try {
      return fromJson(json);
    } on FormatException catch (error) {
      throw ErrorMapper.fromException(error);
    } on TypeError catch (error) {
      throw ErrorMapper.fromException(FormatException('Respuesta de órdenes inesperada: $error'));
    }
  }
}
