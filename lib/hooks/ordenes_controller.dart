import 'dart:async';

import 'package:flutter/foundation.dart';

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../services/ordenes_service.dart';
import '../types/ordenes.dart';
import '../utils/constants.dart';
import 'domicilio_orden_controller.dart';

sealed class OrdenesVista {
  const OrdenesVista();
}

/// Consulta en curso. `lento` pasa a `true` a los 10 s.
class Cargando extends OrdenesVista {
  const Cargando({this.lento = false});
  final bool lento;
}

class ConOrdenes extends OrdenesVista {
  const ConOrdenes(this.respuesta);
  final RespuestaOrdenes respuesta;
}

class Vacio extends OrdenesVista {
  const Vacio(this.respuesta);
  final RespuestaOrdenes respuesta;
}

enum BloqueoTipo {
  /// 403 `AFILIACION_NO_ENCONTRADA`: el documento de la cuenta no coincide con la EPS.
  rectificar,

  /// 403 suspendida, retirada o no válida: solo la EPS puede cambiarlo.
  contactarEps,

  /// 403 `DOCUMENTO_NO_REGISTRADO`: la cuenta no tiene documento.
  sinDocumento,
}

class Bloqueado extends OrdenesVista {
  const Bloqueado({required this.tipo, required this.codigo, this.documento});
  final BloqueoTipo tipo;
  final String codigo;
  final String? documento;
}

class ErrorConsulta extends OrdenesVista {
  const ErrorConsulta(this.error);
  final AppError error;
}

enum FiltroOrdenes { todas, domicilio, porAutorizar, vencidas }

/// Selección para un pedido a domicilio: pertenece a una sola orden.
class Seleccion {
  const Seleccion({required this.ordenId, required this.ids});
  final String ordenId;
  final Set<String> ids;
}

/// Éxito de un 202: se muestra hasta que el paciente recarga.
class ExitoDomicilio {
  const ExitoDomicilio({required this.referencia, required this.cantidad});
  final String referencia;
  final int cantidad;
}

/// Estado de «Órdenes y autorizaciones». Todo vive en memoria: nada se guarda ni se restaura.
///
/// Los filtros son locales sobre la respuesta actual (no hacen otra consulta a la EPS ni cambian
/// `consultadoEn`). Solo se leen banderas del backend; ninguna regla se recalcula aquí.
class OrdenesController extends ChangeNotifier {
  OrdenesController(
    this._service, {
    Duration avisoLento = NetworkTimeouts.ordenesLento,
    String Function()? direccionPerfil,
  })  : _avisoLento = avisoLento,
        _direccionPerfil = direccionPerfil ?? (() => '');

  /// Dirección del perfil del paciente para precargar la entrega (vacía si no la tiene).
  final String Function() _direccionPerfil;

  final OrdenesService _service;
  final Duration _avisoLento;

  OrdenesVista vista = const Cargando();
  FiltroOrdenes filtro = FiltroOrdenes.todas;
  Seleccion? seleccion;

  /// La última marca movió la selección de una orden a otra.
  bool seleccionCambioDeOrden = false;

  /// Ids de medicamento u orden que un 409 actualizó, hasta la próxima recarga.
  final Set<String> actualizados = {};
  ExitoDomicilio? exito;

  /// Se activa cuando un enlace profundo pide una orden que ya no está en la respuesta.
  bool ordenNoDisponible = false;

  /// Cambia con cada respuesta recibida: reproduce la entrada escalonada (D11).
  int entradaId = 0;

  /// Cambia con el filtro: reproduce la entrada de grupos, tarjetas y filas.
  int filtroId = 0;

  bool _cargadoAlguna = false;
  int _secuencia = 0;
  bool _disposed = false;
  Timer? _temporizadorLento;

  Future<void> cargarSiHaceFalta() => _cargadoAlguna ? Future.value() : recargar();

  /// Vacía todo (datos, selección, filtro, `actualizados` y `exito`) y consulta de nuevo a la EPS.
  Future<void> recargar({String? ordenEnlace}) async {
    final mia = ++_secuencia;
    _cargadoAlguna = true;
    _temporizadorLento?.cancel();
    seleccion = null;
    seleccionCambioDeOrden = false;
    filtro = FiltroOrdenes.todas;
    actualizados.clear();
    exito = null;
    ordenNoDisponible = false;
    vista = const Cargando();
    _notificar();
    _temporizadorLento = Timer(_avisoLento, () {
      if (mia == _secuencia && vista is Cargando) {
        vista = const Cargando(lento: true);
        _notificar();
      }
    });
    try {
      final respuesta = await _service.listar();
      if (mia != _secuencia) return;
      vista = respuesta.ordenes.isEmpty ? Vacio(respuesta) : ConOrdenes(respuesta);
      ordenNoDisponible = ordenEnlace != null && !respuesta.ordenes.any((o) => o.id == ordenEnlace);
      entradaId++;
      filtroId = 0;
    } catch (e) {
      if (mia != _secuencia) return;
      vista = _vistaDeError(ErrorMapper.fromException(e));
    } finally {
      if (mia == _secuencia) {
        _temporizadorLento?.cancel();
        _notificar();
      }
    }
  }

  OrdenesVista _vistaDeError(AppError error) {
    final documento = error.detalles?['documentoEnmascarado'];
    final enmascarado = documento is String ? documento : null;
    final codigo = error.code ?? '';
    switch (codigo) {
      case 'AFILIACION_NO_ENCONTRADA':
        return Bloqueado(tipo: BloqueoTipo.rectificar, codigo: codigo, documento: enmascarado);
      case 'AFILIACION_SUSPENDIDA' || 'AFILIACION_RETIRADA' || 'AFILIACION_NO_VALIDA':
        return Bloqueado(tipo: BloqueoTipo.contactarEps, codigo: codigo, documento: enmascarado);
      case 'DOCUMENTO_NO_REGISTRADO':
        return Bloqueado(tipo: BloqueoTipo.sinDocumento, codigo: codigo);
      default:
        return ErrorConsulta(error);
    }
  }

  RespuestaOrdenes? get respuesta => switch (vista) {
        ConOrdenes(:final respuesta) => respuesta,
        Vacio(:final respuesta) => respuesta,
        _ => null,
      };

  // ---- Filtros (locales) ----

  bool _cumple(Orden orden, FiltroOrdenes f) => switch (f) {
        FiltroOrdenes.todas => true,
        FiltroOrdenes.domicilio => orden.permiteDomicilio,
        FiltroOrdenes.porAutorizar => orden.tienePorAutorizar,
        FiltroOrdenes.vencidas => orden.vigencia == Vigencia.vencida,
      };

  int conteo(FiltroOrdenes f) => respuesta?.ordenes.where((o) => _cumple(o, f)).length ?? 0;

  /// Órdenes que pasan el filtro actual, en el orden que entregó el backend.
  List<Orden> get visibles => [for (final o in respuesta?.ordenes ?? const <Orden>[]) if (_cumple(o, filtro)) o];

  void cambiarFiltro(FiltroOrdenes nuevo) {
    if (nuevo == filtro) return;
    filtro = nuevo;
    filtroId++;
    _notificar();
  }

  // ---- Selección ----

  bool estaMarcado(String ordenId, String medicamentoId) =>
      seleccion?.ordenId == ordenId && seleccion!.ids.contains(medicamentoId);

  int get cantidadMarcados => seleccion?.ids.length ?? 0;

  /// Marca o desmarca. Si el medicamento es de otra orden, la selección pasa a esa orden.
  void alternar(Orden orden, MedicamentoOrden medicamento) {
    if (!orden.admiteSeleccion || !medicamento.elegibleParaDomicilio) return;
    final actual = seleccion;
    if (actual == null || actual.ordenId != orden.id) {
      // Un pedido es de una sola orden: la barra lo dice cuando la selección cambia de orden.
      seleccionCambioDeOrden = actual != null;
      seleccion = Seleccion(ordenId: orden.id, ids: {medicamento.id});
    } else {
      final ids = {...actual.ids};
      if (!ids.add(medicamento.id)) ids.remove(medicamento.id);
      seleccion = ids.isEmpty ? null : Seleccion(ordenId: orden.id, ids: ids);
      if (seleccion == null) seleccionCambioDeOrden = false;
    }
    _notificar();
  }

  void elegirTodos(Orden orden) {
    final ids = {for (final m in orden.elegibles) m.id};
    if (ids.isEmpty) return;
    seleccion = Seleccion(ordenId: orden.id, ids: ids);
    _notificar();
  }

  void quitarSeleccion() {
    if (seleccion == null) return;
    seleccion = null;
    seleccionCambioDeOrden = false;
    _notificar();
  }

  Orden? get ordenSeleccionada {
    final id = seleccion?.ordenId;
    if (id == null) return null;
    for (final o in respuesta?.ordenes ?? const <Orden>[]) {
      if (o.id == id) return o;
    }
    return null;
  }

  // ---- Domicilio ----

  DomicilioOrdenController nuevoDomicilio() {
    final orden = ordenSeleccionada!;
    final ids = [
      for (final m in orden.medicamentos)
        if (seleccion!.ids.contains(m.id)) m.id,
    ];
    return DomicilioOrdenController(
      service: _service,
      orden: orden,
      medicamentoIds: ids,
      direccionInicial: _direccionPerfil(),
    );
  }

  /// Aplica lo que dejó el diálogo al cerrarse. No recarga nada por su cuenta (AC-21).
  void aplicarResultado(DomicilioOrdenController dialogo) {
    final actual = respuesta;
    if (actual == null) return;
    switch (dialogo.fase) {
      case FaseDomicilio.exito:
        exito = ExitoDomicilio(referencia: dialogo.referencia ?? '', cantidad: dialogo.medicamentoIds.length);
        seleccion = null;
        seleccionCambioDeOrden = false;
      case FaseDomicilio.cambio || FaseDomicilio.listoConCambios:
        _aplicarCambios(dialogo, actual);
      case FaseDomicilio.vencida:
        final nueva = dialogo.ordenActualizada;
        if (nueva != null) {
          _reemplazar(actual, nueva);
        } else {
          _reemplazar(actual, _comoVencida(dialogo.orden));
        }
        actualizados.add(dialogo.orden.id);
        seleccion = null;
      default:
        break;
    }
    _notificar();
  }

  void _aplicarCambios(DomicilioOrdenController dialogo, RespuestaOrdenes actual) {
    final cambios = dialogo.cambios;
    final nueva = dialogo.ordenActualizada;
    if (nueva != null) {
      _reemplazar(actual, nueva);
    } else {
      // Sin orden en la respuesta: se refleja solo lo que el backend dijo de cada medicamento.
      final porId = {for (final c in cambios) c.id: c};
      _reemplazar(
        actual,
        dialogo.orden.copyWith(
          medicamentos: [
            for (final m in dialogo.orden.medicamentos)
              porId.containsKey(m.id) ? m.conElegibilidad(elegible: false, motivos: porId[m.id]!.motivos) : m,
          ],
        ),
      );
    }
    final ids = cambios.map((c) => c.id).toSet();
    actualizados.addAll(ids);
    final sel = seleccion;
    if (sel != null) {
      final restantes = sel.ids.difference(ids);
      seleccion = restantes.isEmpty ? null : Seleccion(ordenId: sel.ordenId, ids: restantes);
    }
  }

  Orden _comoVencida(Orden orden) => Orden(
        id: orden.id,
        fechaOrden: orden.fechaOrden,
        vencimiento: orden.vencimiento,
        vigencia: Vigencia.vencida,
        permiteDomicilio: false,
        soloLectura: true,
        medicamentos: orden.medicamentos,
      );

  void _reemplazar(RespuestaOrdenes actual, Orden nueva) {
    final nuevaRespuesta = actual.reemplazando(nueva);
    vista = vista is Vacio ? Vacio(nuevaRespuesta) : ConOrdenes(nuevaRespuesta);
  }

  /// Olvida todo cuando cambia la sesión.
  void clear() {
    _secuencia++;
    _temporizadorLento?.cancel();
    vista = const Cargando();
    filtro = FiltroOrdenes.todas;
    seleccion = null;
    actualizados.clear();
    exito = null;
    ordenNoDisponible = false;
    _cargadoAlguna = false;
    _notificar();
  }

  void _notificar() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _temporizadorLento?.cancel();
    super.dispose();
  }
}
