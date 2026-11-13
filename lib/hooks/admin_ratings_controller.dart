import 'package:flutter/foundation.dart';

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../services/admin_service.dart';
import '../services/delivery_service.dart';
import '../types/admin.dart';
import '../types/calificaciones.dart';

/// Calificaciones de las entregas para el administrador: promedio por repartidor y las malas.
///
/// Geolocation solo conoce el id del repartidor; el nombre se busca en Auth (si falla, se
/// muestra el id abreviado: el reporte sigue siendo útil).
class AdminRatingsController extends ChangeNotifier {
  AdminRatingsController({required DeliveryService deliveries, required AdminService admin})
      : _deliveries = deliveries,
        _admin = admin;

  final DeliveryService _deliveries;
  final AdminService _admin;

  static const ventanas = [7, 30, 90];

  /// Páginas de repartidores que se leen para los nombres (20 por página).
  static const paginasNombres = 5;

  int dias = 30;
  ReporteCalificaciones? reporte;
  Map<String, String> nombres = const {};
  bool loading = false;
  AppError? error;
  int _turno = 0;
  bool _disposed = false;

  String nombreDe(String? repartidorId) {
    if (repartidorId == null || repartidorId.isEmpty) return 'Sin repartidor';
    final nombre = nombres[repartidorId];
    if (nombre != null && nombre.trim().isNotEmpty) return nombre;
    final corto = repartidorId.length > 4 ? repartidorId.substring(repartidorId.length - 4) : repartidorId;
    return 'Repartidor •••• $corto';
  }

  Future<void> setDias(int value) async {
    if (value == dias) return;
    dias = value;
    await load();
  }

  Future<void> load() async {
    final turno = ++_turno;
    loading = true;
    error = null;
    _notify();
    try {
      final nombresFuturos = nombres.isEmpty ? _nombres() : Future.value(nombres);
      final r = await _deliveries.ratingsReport(days: dias);
      final n = await nombresFuturos;
      if (turno != _turno) return;
      reporte = r;
      nombres = n;
    } catch (e) {
      if (turno == _turno) error = ErrorMapper.fromException(e);
    } finally {
      if (turno == _turno) {
        loading = false;
        _notify();
      }
    }
  }

  /// Nunca falla: sin nombres el reporte se muestra con ids abreviados.
  Future<Map<String, String>> _nombres() async {
    final mapa = <String, String>{};
    try {
      for (var pagina = 1; pagina <= paginasNombres; pagina++) {
        final page = await _admin.users(role: UserRole.driver, page: pagina);
        for (final u in page.users) {
          mapa[u.id] = u.name;
        }
        if (!page.hasMore) break;
      }
    } catch (_) {
      // Se queda con los que alcanzó a leer.
    }
    return mapa;
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
