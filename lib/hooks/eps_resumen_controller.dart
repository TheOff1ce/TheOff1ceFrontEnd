import 'dart:async';

import 'package:flutter/foundation.dart';

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../services/pendientes_service.dart';
import '../types/pendiente.dart';

/// Cifras del plazo de 48 h para la EPS, calculadas sobre lo que devuelve el backend.
///
/// El estado y la fecha límite siguen siendo del backend; aquí solo se cuentan. El tiempo restante
/// se mide contra la hora del servidor (`evaluadoEn`), como en el resto de pendientes.
@immutable
class ResumenEps {
  const ResumenEps({
    required this.porVencer,
    required this.vencidosSinEntregar,
    required this.vigentes,
    required this.entregadosATiempo,
    required this.entregadosFueraDePlazo,
    required this.urgentes,
    required this.totalPendientes,
    required this.totalEntregados,
    required this.parcial,
  });

  /// Vigentes a los que les quedan [ventana] o menos.
  final int porVencer;

  /// Siguen sin entregar y el backend ya los marcó incumplidos.
  final int vencidosSinEntregar;

  /// Todos los pendientes vigentes (incluye los por vencer).
  final int vigentes;
  final int entregadosATiempo, entregadosFueraDePlazo;

  /// Los por vencer, del que vence primero al último (máximo 3).
  final List<PendienteResumen> urgentes;

  /// Totales del backend (pueden ser más que los contados, ver [parcial]).
  final int totalPendientes, totalEntregados;

  /// `true` si hay más registros de los que se contaron (se cuentan los 100 más recientes).
  final bool parcial;

  int get entregados => entregadosATiempo + entregadosFueraDePlazo;

  /// Porcentaje entregado a tiempo, o `null` si aún no hay entregas.
  int? get porcentajeATiempo => entregados == 0 ? null : (entregadosATiempo * 100 / entregados).round();

  static const ventana = Duration(hours: 12);

  factory ResumenEps.de({
    required PaginaPendientes pendientes,
    required PaginaPendientes entregados,
    Duration desdeCarga = Duration.zero,
  }) {
    var porVencer = 0, vencidos = 0, vigentes = 0, aTiempo = 0, fuera = 0;
    final urgentes = <PendienteResumen>[];
    for (final p in pendientes.items.where((p) => p.estadoEntrega == EstadoEntrega.pendiente)) {
      switch (p.cumplimientoPlazo) {
        case CumplimientoPlazo.vigente:
          vigentes++;
          final restante = p.restante(desdeCarga);
          if (restante > Duration.zero && restante <= ventana) {
            porVencer++;
            urgentes.add(p);
          }
        case CumplimientoPlazo.incumplido:
          vencidos++;
        case CumplimientoPlazo.cumplido:
          break;
      }
    }
    for (final p in entregados.items.where((p) => p.estadoEntrega == EstadoEntrega.entregado)) {
      if (p.cumplimientoPlazo == CumplimientoPlazo.cumplido) {
        aTiempo++;
      } else if (p.cumplimientoPlazo == CumplimientoPlazo.incumplido) {
        fuera++;
      }
    }
    urgentes.sort((a, b) => a.restante(desdeCarga).compareTo(b.restante(desdeCarga)));
    return ResumenEps(
      porVencer: porVencer,
      vencidosSinEntregar: vencidos,
      vigentes: vigentes,
      entregadosATiempo: aTiempo,
      entregadosFueraDePlazo: fuera,
      urgentes: List.unmodifiable(urgentes.take(3)),
      totalPendientes: pendientes.total,
      totalEntregados: entregados.total,
      parcial: pendientes.total > pendientes.items.length || entregados.total > entregados.items.length,
    );
  }
}

/// Carga el resumen de la EPS para el inicio (dos consultas: pendientes y entregados).
class EpsResumenController extends ChangeNotifier {
  EpsResumenController(this._service);

  final PendientesService _service;

  /// Máximo que admite el backend por página.
  static const limite = 100;

  ResumenEps? resumen;
  bool loading = false;
  AppError? error;
  final Stopwatch _desdeCarga = Stopwatch();
  bool _disposed = false;
  int _secuencia = 0;

  /// Tiempo desde la última carga: el restante se descuenta sin volver a consultar.
  Duration get desdeCarga => _desdeCarga.elapsed;

  Future<void> load() async {
    final turno = ++_secuencia;
    loading = true;
    error = null;
    _notify();
    try {
      final (pendientes, entregados) = await (
        _service.listar(estado: EstadoEntrega.pendiente, limite: limite),
        _service.listar(estado: EstadoEntrega.entregado, limite: limite),
      ).wait;
      if (turno != _secuencia) return;
      resumen = ResumenEps.de(pendientes: pendientes, entregados: entregados);
      _desdeCarga
        ..reset()
        ..start();
    } on ParallelWaitError<(PaginaPendientes?, PaginaPendientes?), (AsyncError?, AsyncError?)> catch (e) {
      if (turno == _secuencia) error = ErrorMapper.fromException(e.errors.$1?.error ?? e.errors.$2?.error ?? e);
    } catch (e) {
      if (turno == _secuencia) error = ErrorMapper.fromException(e);
    } finally {
      if (turno == _secuencia) {
        loading = false;
        _notify();
      }
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
