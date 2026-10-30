import 'package:flutter/foundation.dart';

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../services/pendientes_service.dart';
import '../types/pendiente.dart';

/// Estado del detalle de un pendiente y del registro de novedades.
class PendienteDetailController extends ChangeNotifier {
  PendienteDetailController(this._service, this.id);

  final PendientesService _service;
  final String id;

  PendienteDetalle? detalle;
  bool loading = false;
  bool submitting = false;
  AppError? error;

  final Stopwatch _desdeCarga = Stopwatch();
  bool _actualizadoPorVencimiento = false;
  bool _disposed = false;

  Duration get desdeCarga => _desdeCarga.elapsed;

  /// Carga el detalle. Con [silencioso] conserva el contenido en pantalla mientras se actualiza.
  Future<void> load({bool silencioso = false}) async {
    if (!silencioso) loading = true;
    error = null;
    _notify();
    try {
      detalle = await _service.detalle(id);
      _desdeCarga
        ..reset()
        ..start();
    } catch (e) {
      error = ErrorMapper.fromException(e);
    } finally {
      loading = false;
      _notify();
    }
  }

  /// Si la fecha límite ya pasó pero el backend aún dice "vigente", consulta de nuevo (una sola
  /// vez por pantalla, para no entrar en un ciclo) y muestra el estado real. El frontend no decide
  /// el incumplimiento.
  Future<void> actualizarSiVencio() async {
    final actual = detalle;
    if (actual == null || loading || _actualizadoPorVencimiento) return;
    if (actual.resumen.vencioSinActualizar(desdeCarga)) {
      _actualizadoPorVencimiento = true;
      await load(silencioso: true);
    }
  }

  /// Registra una novedad. Devuelve el error o `null` si salió bien.
  Future<AppError?> registrarNovedad({required String tipo, required String detalleNovedad}) async {
    submitting = true;
    _notify();
    try {
      final novedad = await _service.registrarNovedad(id, tipo: tipo, detalle: detalleNovedad);
      final actual = detalle;
      if (actual != null) detalle = actual.conNovedad(novedad);
      return null;
    } catch (e) {
      return ErrorMapper.fromException(e);
    } finally {
      submitting = false;
      _notify();
    }
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
