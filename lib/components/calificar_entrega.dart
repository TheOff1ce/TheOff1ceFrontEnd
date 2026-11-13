import 'package:flutter/material.dart';

import '../app/theme/farmago_tokens.dart';
import '../errors/app_error.dart';
import '../types/delivery.dart';
import 'farmago/buttons.dart';
import 'farmago/feedback.dart';

/// Después de confirmar el código: el paciente califica la entrega (1 a 5 estrellas y un
/// comentario opcional). Una sola vez; luego solo muestra su calificación.
class CalificarEntrega extends StatefulWidget {
  const CalificarEntrega({super.key, required this.rating, required this.busy, required this.onRate});

  /// Calificación ya guardada (`null` = aún no califica).
  final DeliveryRating? rating;
  final bool busy;

  /// Devuelve `null` si se guardó o el error a mostrar.
  final Future<AppError?> Function(int stars, String? comment) onRate;

  static const etiquetas = ['Muy mala', 'Mala', 'Regular', 'Buena', 'Excelente'];

  @override
  State<CalificarEntrega> createState() => _CalificarEntregaState();
}

class _CalificarEntregaState extends State<CalificarEntrega> {
  final _comentario = TextEditingController();
  int _estrellas = 0;
  String? _aviso;
  AppError? _error;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_estrellas == 0) {
      setState(() => _aviso = 'Toca de 1 a 5 estrellas.');
      return;
    }
    setState(() {
      _aviso = null;
      _error = null;
    });
    final error = await widget.onRate(_estrellas, _comentario.text);
    if (mounted && error != null) setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final guardada = widget.rating;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(FgSpace.sp5),
      decoration: FgDecor.tarjeta(),
      child: guardada != null ? _gracias(guardada.stars) : _formulario(),
    );
  }

  Widget _gracias(int estrellas) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(header: true, child: const Text('¡Gracias por calificar!', style: FgText.h3)),
        const SizedBox(height: FgSpace.sp2),
        _Estrellas(valor: estrellas),
        const SizedBox(height: FgSpace.sp2),
        Text(
          'Calificaste esta entrega como «${CalificarEntrega.etiquetas[estrellas - 1]}». Nos ayuda a mejorar el servicio.',
          style: FgText.body.copyWith(color: FgColors.inkSoft),
        ),
      ]);

  Widget _formulario() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(header: true, child: const Text('¿Cómo estuvo la entrega?', style: FgText.h3)),
        const SizedBox(height: FgSpace.sp2),
        Text(
          'Tu calificación nos ayuda a mejorar. Es opcional y solo toma un momento.',
          style: FgText.body.copyWith(color: FgColors.inkSoft),
        ),
        const SizedBox(height: FgSpace.sp4),
        if (_error != null) ...[
          FgBanner(
            kind: FgBannerKind.error,
            message: _error!.userMessage,
            referencia: _error!.showsReference ? _error!.referenceId : null,
          ),
          const SizedBox(height: FgSpace.sp4),
        ],
        _Estrellas(
          valor: _estrellas,
          onChanged: widget.busy
              ? null
              : (v) => setState(() {
                    _estrellas = v;
                    _aviso = null;
                  }),
        ),
        const SizedBox(height: FgSpace.sp1),
        Text(
          _aviso ?? (_estrellas == 0 ? 'Toca una estrella' : CalificarEntrega.etiquetas[_estrellas - 1]),
          style: FgText.label.copyWith(color: _aviso != null ? FgColors.peligro : FgColors.inkSoft),
        ),
        const SizedBox(height: FgSpace.sp4),
        TextField(
          controller: _comentario,
          enabled: !widget.busy,
          maxLines: 3,
          minLines: 2,
          maxLength: 500,
          decoration:
              const InputDecoration(labelText: 'Comentario (opcional)', helperText: 'No se le muestra al repartidor.'),
        ),
        const SizedBox(height: FgSpace.sp3),
        FgButton(
          label: 'Enviar calificación',
          icon: Icons.send_outlined,
          loading: widget.busy,
          loadingLabel: 'Enviando…',
          expand: true,
          onPressed: _enviar,
        ),
      ]);
}

/// Cinco estrellas de 48 px (área de toque cómoda). Sin `onChanged` son solo lectura.
class _Estrellas extends StatelessWidget {
  const _Estrellas({required this.valor, this.onChanged});

  final int valor;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    if (onChanged == null && valor > 0) {
      return Semantics(
        label: '$valor de 5 estrellas',
        excludeSemantics: true,
        child: Row(children: [
          for (var i = 1; i <= 5; i++)
            Icon(i <= valor ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 32, color: i <= valor ? FgColors.riesgoSolid : FgColors.lineaControl),
        ]),
      );
    }
    return Wrap(children: [
      for (var i = 1; i <= 5; i++)
        Semantics(
          selected: i == valor,
          child: IconButton(
            tooltip: '$i ${i == 1 ? 'estrella' : 'estrellas'}: ${CalificarEntrega.etiquetas[i - 1]}',
            iconSize: 40,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: onChanged == null ? null : () => onChanged!(i),
            icon: Icon(
              i <= valor ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i <= valor ? FgColors.riesgoSolid : FgColors.lineaControl,
            ),
          ),
        ),
    ]);
  }
}
