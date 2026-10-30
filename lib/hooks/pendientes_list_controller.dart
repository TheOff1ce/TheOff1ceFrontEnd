import 'package:flutter/foundation.dart';

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../services/pendientes_service.dart';
import '../types/pendiente.dart';

/// Estado de la lista de pendientes: filtros, paginación y carga.
///
/// El orden es el que entrega el backend (más reciente primero). Filtrar por cumplimiento del plazo
/// no existe en la API todavía, así que solo se filtra por estado de entrega y por orden.
class PendientesListController extends ChangeNotifier {
  PendientesListController(this._service);

  final PendientesService _service;

  /// Filas por página permitidas en la tabla (el backend admite de 1 a 100).
  static const limitesPermitidos = [25, 50, 100];

  PaginaPendientes? pagina;
  EstadoEntrega? estado;
  String orden = '';
  int limite = limitesPermitidos.first;
  bool loading = false;
  AppError? error;
  bool _loadedOnce = false;

  final Stopwatch _desdeCarga = Stopwatch();
  int _secuencia = 0;
  bool _disposed = false;

  /// Tiempo transcurrido desde que llegaron los datos (se suma a `evaluadoEn` para el reloj).
  Duration get desdeCarga => _desdeCarga.elapsed;

  bool get filtrosActivos => estado != null || orden.isNotEmpty;

  /// Carga inicial: no repite la consulta si la pantalla se reconstruye con datos ya cargados.
  Future<void> loadIfNeeded() => _loadedOnce ? Future.value() : load();

  Future<void> load({int page = 1}) async {
    final mia = ++_secuencia;
    loading = true;
    error = null;
    _notify();
    try {
      final resultado = await _service.listar(
        estado: estado,
        ordenMedicamentoId: orden,
        pagina: page,
        limite: limite,
      );
      if (mia != _secuencia) return; // llegó otra consulta más nueva
      if (resultado.items.isEmpty && resultado.pagina > 1) {
        // La lista se acortó y esta página ya no existe: vuelve a la primera.
        await load();
        return;
      }
      pagina = resultado;
      _loadedOnce = true;
      _desdeCarga
        ..reset()
        ..start();
    } catch (e) {
      if (mia != _secuencia) return;
      error = ErrorMapper.fromException(e);
    } finally {
      if (mia == _secuencia) {
        loading = false;
        _notify();
      }
    }
  }

  Future<void> recargar() => load(page: pagina?.pagina ?? 1);

  Future<void> cambiarEstado(EstadoEntrega? nuevo) {
    if (nuevo == estado) return Future.value();
    estado = nuevo;
    return load();
  }

  Future<void> buscar(String texto) {
    final limpio = texto.trim();
    if (limpio == orden) return Future.value();
    orden = limpio;
    return load();
  }

  Future<void> cambiarLimite(int nuevo) {
    if (nuevo == limite) return Future.value();
    limite = nuevo;
    return load();
  }

  Future<void> siguiente() {
    final actual = pagina;
    if (actual == null || !actual.haySiguiente) return Future.value();
    return load(page: actual.pagina + 1);
  }

  Future<void> anterior() {
    final actual = pagina;
    if (actual == null || !actual.hayAnterior) return Future.value();
    return load(page: actual.pagina - 1);
  }

  Future<void> quitarFiltros() {
    estado = null;
    orden = '';
    return load();
  }

  /// Olvida todo cuando cambia la sesión: otra persona nunca ve los datos de la anterior.
  void clear() {
    _secuencia++; // descarta respuestas en vuelo
    pagina = null;
    estado = null;
    orden = '';
    limite = limitesPermitidos.first;
    loading = false;
    error = null;
    _loadedOnce = false;
    _desdeCarga.reset();
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
