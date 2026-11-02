import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';

/// Trayecto de estados: una secuencia real y ordenada (manual §8.14).
///
/// Úsalo solo cuando los pasos son estados que ocurren en orden. No es un patrón de navegación.
/// Cada paso se distingue por forma y palabra, no solo por color:
/// - Completado: nodo relleno con check y la palabra "Completado".
/// - En curso: anillo grueso con punto interior y la palabra "En curso", en texto destacado.
/// - Pendiente: nodo blanco con contorno fino y la palabra "Pendiente", en texto atenuado.
class FgTrail extends StatelessWidget {
  const FgTrail({super.key, required this.etiquetas, required this.actual});

  final List<String> etiquetas;

  /// Índice del paso en curso. Los anteriores están completados y los siguientes, pendientes.
  /// Un valor fuera de rango (por ejemplo -1) deja todos los pasos pendientes.
  final int actual;

  static const _nodo = FgSize.simboloS; // 28 px: nodo del trayecto
  static const _conector = FgBorder.w4;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < etiquetas.length; i++)
            _Paso(
              etiqueta: etiquetas[i],
              estado: i < actual
                  ? _Estado.completado
                  : i == actual
                      ? _Estado.enCurso
                      : _Estado.pendiente,
              conectaConSiguiente: i < etiquetas.length - 1,
              conectorCompletado: i < actual,
            ),
        ],
      );
}

enum _Estado { completado, enCurso, pendiente }

class _Paso extends StatelessWidget {
  const _Paso({
    required this.etiqueta,
    required this.estado,
    required this.conectaConSiguiente,
    required this.conectorCompletado,
  });

  final String etiqueta;
  final _Estado estado;
  final bool conectaConSiguiente;
  final bool conectorCompletado;

  String get _palabra => switch (estado) {
        _Estado.completado => 'Completado',
        _Estado.enCurso => 'En curso',
        _Estado.pendiente => 'Pendiente',
      };

  @override
  Widget build(BuildContext context) {
    final texto = switch (estado) {
      _Estado.completado => FgText.label.copyWith(color: FgColors.ink),
      _Estado.enCurso => FgText.h3.copyWith(color: FgColors.azul800),
      _Estado.pendiente => FgText.body.copyWith(color: FgColors.inkSoft),
    };

    return Semantics(
      container: true,
      label: '$etiqueta. $_palabra',
      child: ExcludeSemantics(
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: FgSize.simboloS,
              child: Column(children: [
                _Nodo(estado: estado),
                if (conectaConSiguiente)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: FgTrail._conector,
                        margin: const EdgeInsets.symmetric(vertical: FgSpace.sp1),
                        decoration: BoxDecoration(
                          color: conectorCompletado ? FgColors.azul600 : FgColors.linea,
                          borderRadius: BorderRadius.circular(FgRadius.pill),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
            const SizedBox(width: FgSpace.sp4),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: conectaConSiguiente ? FgSpace.sp5 : 0, top: FgSpace.sp1),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(etiqueta, style: texto),
                  Text(_palabra, style: FgText.caption),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Nodo extends StatelessWidget {
  const _Nodo({required this.estado});

  final _Estado estado;

  @override
  Widget build(BuildContext context) => switch (estado) {
        _Estado.completado => Container(
            width: FgTrail._nodo,
            height: FgTrail._nodo,
            decoration: const BoxDecoration(color: FgColors.azul600, shape: BoxShape.circle),
            child: const Icon(Icons.check, size: FgSize.iconoSm, color: FgColors.blanco),
          ),
        _Estado.enCurso => Container(
            width: FgTrail._nodo,
            height: FgTrail._nodo,
            decoration: BoxDecoration(
              color: FgColors.superficie,
              shape: BoxShape.circle,
              border: Border.all(color: FgColors.azul600, width: FgBorder.w4),
            ),
            alignment: Alignment.center,
            child: Container(
              width: FgSpace.sp3,
              height: FgSpace.sp3,
              decoration: const BoxDecoration(color: FgColors.azul600, shape: BoxShape.circle),
            ),
          ),
        _Estado.pendiente => Container(
            width: FgTrail._nodo,
            height: FgTrail._nodo,
            decoration: BoxDecoration(
              color: FgColors.superficie,
              shape: BoxShape.circle,
              border: Border.all(color: FgColors.lineaControl, width: FgBorder.w2),
            ),
          ),
      };
}
