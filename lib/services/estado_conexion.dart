import 'package:flutter/foundation.dart';

/// Si la app tiene conexión, según las propias llamadas a los servicios (sin librerías extra).
///
/// Un fallo de red (sin internet, DNS, conexión cortada) la marca sin conexión de inmediato; dos
/// demoras seguidas también, porque una red muy mala se comporta igual. Cualquier respuesta del
/// servidor, aunque sea un error, prueba que hay conexión.
class EstadoConexion extends ChangeNotifier {
  EstadoConexion._();

  static final instancia = EstadoConexion._();

  bool _sinConexion = false;
  int _demoras = 0;

  bool get sinConexion => _sinConexion;

  void respuesta() {
    _demoras = 0;
    _poner(false);
  }

  void falloDeRed() => _poner(true);

  void demora() {
    _demoras++;
    if (_demoras >= 2) _poner(true);
  }

  void _poner(bool valor) {
    if (_sinConexion == valor) return;
    _sinConexion = valor;
    notifyListeners();
  }

  @visibleForTesting
  void reiniciar() {
    _demoras = 0;
    _sinConexion = false;
  }
}
