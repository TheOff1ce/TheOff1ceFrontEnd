import 'dart:async';

import 'package:flutter/foundation.dart';

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../services/admin_service.dart';
import '../services/delivery_service.dart';
import '../types/admin.dart';
import '../types/calificaciones.dart';
import '../types/delivery.dart';

/// Resultado de un día: entregas confirmadas y las que se cancelaron o fallaron.
@immutable
class DiaOperacion {
  const DiaOperacion({required this.dia, required this.entregados, required this.noEntregados});

  /// Medianoche (hora local) del día.
  final DateTime dia;
  final int entregados, noEntregados;

  int get total => entregados + noEntregados;
}

/// Cómo va la operación ahora, a partir de las entregas que devuelve Geolocation.
@immutable
class OperacionHoy {
  const OperacionHoy({
    required this.buscandoRepartidor,
    required this.enCamino,
    required this.entregadosHoy,
    required this.noEntregadosHoy,
    required this.esperando,
    required this.leidas,
    required this.semana,
  });

  /// Creadas y sin repartidor todavía.
  final int buscandoRepartidor;

  /// Asignadas, recogidas, en camino o llegando.
  final int enCamino;
  final int entregadosHoy;

  /// Canceladas o fallidas hoy.
  final int noEntregadosHoy;

  /// Las que esperan repartidor, la más antigua primero.
  final List<Delivery> esperando;

  /// Cuántas entregas se contaron (Geolocation devuelve las más recientes).
  final int leidas;

  /// Los últimos 7 días, del más antiguo a hoy.
  final List<DiaOperacion> semana;

  int get entregadosSemana => semana.fold(0, (a, d) => a + d.entregados);
  int get noEntregadosSemana => semana.fold(0, (a, d) => a + d.noEntregados);

  /// Porcentaje de pedidos terminados en la semana que sí se entregaron (`null` sin datos).
  int? get efectividadSemana {
    final total = entregadosSemana + noEntregadosSemana;
    return total == 0 ? null : (entregadosSemana * 100 / total).round();
  }

  /// Pasado este tiempo sin repartidor, el pedido se marca como demorado.
  static const demora = Duration(minutes: 15);

  factory OperacionHoy.de(List<Delivery> entregas, DateTime ahora) {
    bool esHoy(DateTime? t) {
      if (t == null) return false;
      final l = t.toLocal(), a = ahora.toLocal();
      return l.year == a.year && l.month == a.month && l.day == a.day;
    }

    final hoy = DateTime(ahora.toLocal().year, ahora.toLocal().month, ahora.toLocal().day);
    final dias = [for (var i = 6; i >= 0; i--) DateTime(hoy.year, hoy.month, hoy.day - i)];
    final ok = List<int>.filled(7, 0), mal = List<int>.filled(7, 0);
    int? indice(DateTime? t) {
      if (t == null) return null;
      final l = t.toLocal();
      final i = dias.indexWhere((d) => d.year == l.year && d.month == l.month && d.day == l.day);
      return i < 0 ? null : i;
    }

    var enCamino = 0, entregados = 0, fallidos = 0;
    final esperando = <Delivery>[];
    for (final d in entregas) {
      switch (d.status) {
        case DeliveryStatus.created:
          esperando.add(d);
        case DeliveryStatus.assigned || DeliveryStatus.pickedUp || DeliveryStatus.inTransit || DeliveryStatus.arriving:
          enCamino++;
        case DeliveryStatus.delivered:
          if (esHoy(d.deliveredAt ?? d.since)) entregados++;
          final i = indice(d.deliveredAt ?? d.since);
          if (i != null) ok[i]++;
        case DeliveryStatus.cancelled || DeliveryStatus.failed:
          if (esHoy(d.since)) fallidos++;
          final i = indice(d.since);
          if (i != null) mal[i]++;
        case DeliveryStatus.unknown:
          break;
      }
    }
    // Sin hora conocida va al final: no se puede decir cuánto lleva esperando.
    esperando.sort((a, b) => (a.since ?? ahora).compareTo(b.since ?? ahora));
    return OperacionHoy(
      buscandoRepartidor: esperando.length,
      enCamino: enCamino,
      entregadosHoy: entregados,
      noEntregadosHoy: fallidos,
      esperando: List.unmodifiable(esperando),
      leidas: entregas.length,
      semana: [for (var i = 0; i < 7; i++) DiaOperacion(dia: dias[i], entregados: ok[i], noEntregados: mal[i])],
    );
  }
}

/// Usuarios registrados: total y repartidores (los que sostienen la operación).
@immutable
class UsuariosResumen {
  const UsuariosResumen({required this.total, required this.repartidores});

  final int total, repartidores;
}

/// Datos del inicio del administrador. Cada bloque carga por su lado: si un servicio falla, los
/// demás se siguen mostrando y ese bloque ofrece reintentar.
class AdminInicioController extends ChangeNotifier {
  AdminInicioController({required DeliveryService deliveries, required AdminService admin, DateTime Function()? now})
      : _deliveries = deliveries,
        _admin = admin,
        _now = now ?? DateTime.now;

  final DeliveryService _deliveries;
  final AdminService _admin;
  final DateTime Function() _now;

  OperacionHoy? operacion;
  AppError? errorOperacion;
  ReporteCalificaciones? calificaciones;
  AppError? errorCalificaciones;
  UsuariosResumen? usuarios;
  AppError? errorUsuarios;
  bool loading = false;
  DateTime? actualizado;
  bool _disposed = false;

  /// Ventana de las calificaciones que se resumen en el inicio.
  static const diasCalificaciones = 7;

  DateTime get ahora => _now();

  Future<void> load() async {
    loading = true;
    _notify();
    await Future.wait([_operacion(), _calificaciones(), _usuarios()]);
    actualizado = _now();
    loading = false;
    _notify();
  }

  Future<void> _operacion() async {
    try {
      operacion = OperacionHoy.de(await _deliveries.listMine(), _now());
      errorOperacion = null;
    } catch (e) {
      errorOperacion = ErrorMapper.fromException(e);
    }
  }

  Future<void> _calificaciones() async {
    try {
      calificaciones = await _deliveries.ratingsReport(days: diasCalificaciones);
      errorCalificaciones = null;
    } catch (e) {
      errorCalificaciones = ErrorMapper.fromException(e);
    }
  }

  Future<void> _usuarios() async {
    try {
      final (todos, repartidores) = await (_admin.users(), _admin.users(role: UserRole.driver)).wait;
      usuarios = UsuariosResumen(total: todos.total, repartidores: repartidores.total);
      errorUsuarios = null;
    } catch (e) {
      final error = e is ParallelWaitError ? (e.errors as (AsyncError?, AsyncError?)).$1?.error ?? e : e;
      errorUsuarios = ErrorMapper.fromException(error);
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
