import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../app/theme/farmago_tokens.dart';
import '../../services/estado_conexion.dart';
import '../../utils/constants.dart';
import 'feedback.dart';

/// Banda de «Sin conexión» arriba de toda la app. Empuja la app hacia abajo (no tapa la barra
/// superior) y, mientras se ve, prueba la conexión cada pocos segundos; al volver, se recoge y un
/// aviso lo confirma.
class BandaSinConexion extends StatefulWidget {
  const BandaSinConexion({super.key, required this.child, this.estado, this.sonda, this.cliente, this.cada});

  final Widget child;

  /// Inyectables en pruebas.
  final EstadoConexion? estado;
  final Uri? sonda;
  final http.Client? cliente;
  final Duration? cada;

  /// Dirección liviana para probar la conexión: en la web, un archivo del mismo sitio (sin CORS);
  /// en la app, el gateway. Cualquier respuesta, aunque sea un error, prueba que hay conexión.
  static Uri sondaPorDefecto() =>
      kIsWeb ? Uri.base.resolve('/version.json') : Uri.parse('${AppConfig.authBaseUrl}/auth/me');

  @override
  State<BandaSinConexion> createState() => _BandaSinConexionState();
}

class _BandaSinConexionState extends State<BandaSinConexion> {
  late final EstadoConexion _estado = widget.estado ?? EstadoConexion.instancia;
  late final http.Client _cliente = widget.cliente ?? http.Client();
  late final Duration _cada = widget.cada ?? const Duration(seconds: 8);
  Timer? _sondeo;
  bool _probando = false;
  late bool _visible = _estado.sinConexion;

  @override
  void initState() {
    super.initState();
    _estado.addListener(_cambio);
    if (_visible) _empezarSondeo();
  }

  @override
  void dispose() {
    _estado.removeListener(_cambio);
    _sondeo?.cancel();
    if (widget.cliente == null) _cliente.close();
    super.dispose();
  }

  void _cambio() {
    final sin = _estado.sinConexion;
    if (sin == _visible || !mounted) return;
    setState(() => _visible = sin);
    if (sin) {
      _empezarSondeo();
    } else {
      _sondeo?.cancel();
      _sondeo = null;
      avisar('Conexión recuperada', kind: FgToastKind.exito);
    }
  }

  void _empezarSondeo() {
    _sondeo?.cancel();
    _sondeo = Timer.periodic(_cada, (_) => unawaited(_probar()));
  }

  Future<void> _probar() async {
    if (_probando) return;
    setState(() => _probando = true);
    try {
      await _cliente.get(widget.sonda ?? BandaSinConexion.sondaPorDefecto()).timeout(const Duration(seconds: 6));
      _estado.respuesta();
    } catch (_) {
      // Sigue sin conexión: se prueba otra vez en el siguiente ciclo.
    } finally {
      if (mounted) setState(() => _probando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final medidas = MediaQuery.of(context);
    return Column(
      children: [
        AnimatedSize(
          duration: FgMotion.reducir(context, FgMotion.media),
          curve: FgMotion.ease,
          alignment: Alignment.topCenter,
          child: _visible ? _banda(medidas) : const SizedBox(width: double.infinity),
        ),
        Expanded(
          // La banda ya ocupa el borde de arriba (barra de estado incluida). Siempre el mismo
          // envoltorio: cambiarlo reconstruiría la app desde cero y perdería la pantalla abierta.
          child: MediaQuery.removePadding(context: context, removeTop: _visible, child: widget.child),
        ),
      ],
    );
  }

  Widget _banda(MediaQueryData medidas) => Semantics(
        container: true,
        liveRegion: true,
        child: Material(
          color: FgColors.superficieInversa,
          child: Padding(
            padding: EdgeInsets.fromLTRB(FgSpace.sp4, medidas.padding.top + FgSpace.sp2, FgSpace.sp2, FgSpace.sp2),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(Icons.wifi_off_rounded, color: FgColors.riesgoSolid, size: FgSize.iconoMd),
                ),
                const SizedBox(width: FgSpace.sp3),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'Sin conexión. ', style: FgText.label.copyWith(color: FgColors.blanco)),
                      TextSpan(
                        text: 'Reintentamos solos.',
                        style: FgText.body.copyWith(color: FgColors.blanco.withValues(alpha: .78)),
                      ),
                    ]),
                  ),
                ),
                TextButton(
                  onPressed: _probando ? null : _probar,
                  style: TextButton.styleFrom(foregroundColor: FgColors.blanco),
                  child: Text(_probando ? 'Probando…' : 'Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
}
