import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Cómo quiere ver la app la persona: como el dispositivo, siempre clara o siempre oscura.
enum Apariencia {
  automatica('Automática'),
  clara('Clara'),
  oscura('Oscura');

  const Apariencia(this.etiqueta);

  final String etiqueta;

  /// Si la app va en oscuro, dado el modo del dispositivo.
  bool oscuraCon({required bool sistemaOscuro}) => switch (this) {
        Apariencia.automatica => sistemaOscuro,
        Apariencia.clara => false,
        Apariencia.oscura => true,
      };
}

/// Guarda la apariencia elegida en este dispositivo (no viaja con la cuenta: cada pantalla tiene su
/// luz). Si el almacenamiento no está disponible, la elección dura mientras la app esté abierta.
class AparienciaController extends ChangeNotifier {
  AparienciaController({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  static final instancia = AparienciaController();

  static const _clave = 'farmago.apariencia';

  final FlutterSecureStorage _storage;
  Apariencia _valor = Apariencia.automatica;

  Apariencia get valor => _valor;

  Future<void> cargar() async {
    try {
      final guardada = await _storage.read(key: _clave);
      final elegida = Apariencia.values.where((a) => a.name == guardada).firstOrNull;
      if (elegida != null && elegida != _valor) {
        _valor = elegida;
        notifyListeners();
      }
    } catch (_) {
      // Sin almacenamiento: se queda en automática.
    }
  }

  /// Se aplica al instante; guardarla no hace esperar a nadie.
  void elegir(Apariencia nueva) {
    if (nueva == _valor) return;
    _valor = nueva;
    notifyListeners();
    unawaited(_guardar(nueva));
  }

  Future<void> _guardar(Apariencia valor) async {
    try {
      await _storage.write(key: _clave, value: valor.name);
    } catch (_) {
      // Se aplica igual; solo no se recordará al volver a abrir la app.
    }
  }

  @visibleForTesting
  void reiniciar() => _valor = Apariencia.automatica;
}
