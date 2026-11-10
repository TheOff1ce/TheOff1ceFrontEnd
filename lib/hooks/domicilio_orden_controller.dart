import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../services/ordenes_service.dart';
import '../types/ordenes.dart';

/// Fases del diálogo «Pedir a domicilio» (manual §7.1, regla 2: un solo modal con pasos).
enum FaseDomicilio {
  verificando,
  listo,
  listoConCambios,
  enviando,
  exito,
  cambio,
  vencida,
  errorEnvio,
  errorVerificar,
}

/// Estado del diálogo de domicilio de una orden con una selección fija.
///
/// Una selección nueva (cerrar y volver a abrir, o cambiar los marcados) crea otro controlador y,
/// con él, otro `solicitudId`. El reintento reutiliza el mismo, así el backend no duplica el pedido.
class DomicilioOrdenController extends ChangeNotifier {
  DomicilioOrdenController({
    required OrdenesService service,
    required this.orden,
    required List<String> medicamentoIds,
    this.escalon = const Duration(milliseconds: 140),
    String Function()? generarSolicitudId,
  })  : _service = service,
        medicamentoIds = List.unmodifiable(medicamentoIds),
        _generarId = generarSolicitudId ?? uuidV4;

  final OrdenesService _service;
  final Orden orden;
  final List<String> medicamentoIds;

  /// Retraso entre cada ✓ de la verificación: solo presentación, la respuesta llega una vez.
  final Duration escalon;
  final String Function() _generarId;

  FaseDomicilio fase = FaseDomicilio.verificando;
  VerificacionDomicilio? verificacion;
  List<CambioElegibilidad> cambios = const [];

  /// Orden que devolvió el backend en un 409 de elegibilidad (reemplaza a la de la lista).
  Orden? ordenActualizada;
  String? referencia;
  AppError? error;

  /// Cuántos medicamentos ya muestran su ✓ (revelado escalonado).
  int revelados = 0;

  /// `null` hasta la primera vez que se pulsa «Confirmar pedido».
  String? solicitudId;

  Timer? _temporizador;
  bool _disposed = false;
  bool _enCurso = false;

  /// En `enviando`, `cambio` y `vencida` no hay X: se sale con el botón del pie.
  bool get sePuedeCerrar =>
      fase == FaseDomicilio.verificando ||
      fase == FaseDomicilio.listo ||
      fase == FaseDomicilio.errorEnvio ||
      fase == FaseDomicilio.errorVerificar ||
      fase == FaseDomicilio.listoConCambios ||
      fase == FaseDomicilio.exito;

  Future<void> verificar() async {
    if (_enCurso) return;
    _enCurso = true;
    _poner(FaseDomicilio.verificando);
    try {
      final resultado = await _service.verificarDomicilio(orden.id, medicamentoIds);
      if (_disposed) return;
      verificacion = resultado;
      // El backend responde por toda la orden: solo cuentan los medicamentos elegidos. Uno elegido
      // que no vuelve en la respuesta ya no está en la orden según la EPS.
      final porId = {for (final m in resultado.medicamentos) m.id: m};
      final nuevosCambios = [
        for (final id in medicamentoIds)
          if (porId[id] == null)
            CambioElegibilidad(id: id, motivos: const [MotivoNoElegible.noPerteneceALaOrden])
          else if (!porId[id]!.elegible)
            CambioElegibilidad(id: id, motivos: porId[id]!.motivos),
      ];
      if (nuevosCambios.isEmpty) {
        revelados = 0;
        _poner(FaseDomicilio.listo);
        _revelar();
      } else {
        cambios = nuevosCambios;
        _poner(FaseDomicilio.listoConCambios);
      }
    } catch (e) {
      if (_disposed) return;
      error = ErrorMapper.fromException(e);
      _poner(FaseDomicilio.errorVerificar);
    } finally {
      _enCurso = false;
    }
  }

  /// «Confirmar pedido» y «Reintentar»: el `solicitudId` se genera una sola vez por intento.
  Future<void> confirmar() async {
    if (_enCurso) return;
    _enCurso = true;
    solicitudId ??= _generarId();
    _temporizador?.cancel();
    _poner(FaseDomicilio.enviando);
    try {
      final aceptado = await _service.enviarDomicilio(orden.id, solicitudId!, medicamentoIds);
      if (_disposed) return;
      referencia = aceptado.referencia;
      _poner(FaseDomicilio.exito);
    } catch (e) {
      if (_disposed) return;
      final appError = ErrorMapper.fromException(e);
      error = appError;
      switch (appError.code) {
        case 'ELEGIBILIDAD_CAMBIADA':
          cambios = CambioElegibilidad.listaDe(appError.detalles);
          ordenActualizada = CambioElegibilidad.ordenDe(appError.detalles);
          _poner(FaseDomicilio.cambio);
        case 'ORDEN_VENCIDA':
          ordenActualizada = CambioElegibilidad.ordenDe(appError.detalles);
          _poner(FaseDomicilio.vencida);
        default:
          _poner(FaseDomicilio.errorEnvio);
      }
    } finally {
      _enCurso = false;
    }
  }

  void _revelar() {
    final total = medicamentoIds.length;
    if (escalon == Duration.zero) {
      revelados = total;
      _notificar();
      return;
    }
    _temporizador?.cancel();
    _temporizador = Timer.periodic(escalon, (timer) {
      revelados++;
      if (revelados >= total) timer.cancel();
      _notificar();
    });
  }

  void _poner(FaseDomicilio nueva) {
    fase = nueva;
    _notificar();
  }

  void _notificar() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _temporizador?.cancel();
    super.dispose();
  }

  /// UUID v4 sin dependencias nuevas.
  static String uuidV4() {
    final azar = Random.secure();
    final bytes = List<int>.generate(16, (_) => azar.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int desde, int hasta) =>
        bytes.sublist(desde, hasta).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
