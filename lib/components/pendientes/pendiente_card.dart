import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';
import '../../types/pendiente.dart';
import '../../utils/pendiente_format.dart';
import '../../utils/plazo_vista.dart';
import '../farmago/deadline_ring.dart';
import '../farmago/focus_ring.dart';

/// Tarjeta de pendiente para móvil (§8.10): tarjeta plana, un solo objetivo táctil.
///
/// La API de la lista no incluye nombres de medicamentos (solo cuántos hay y cuántos se entregaron),
/// así que el título es la orden y el resumen cuenta los medicamentos. Pendiente de diseño: mostrar
/// el primer medicamento "(+N más)" cuando la API lo entregue.
class PendienteCard extends StatefulWidget {
  const PendienteCard({super.key, required this.pendiente, required this.desdeCarga, required this.onOpen});

  final PendienteResumen pendiente;
  final Duration desdeCarga;
  final VoidCallback onOpen;

  @override
  State<PendienteCard> createState() => _PendienteCardState();
}

class _PendienteCardState extends State<PendienteCard> {
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pendiente;
    final vista = PlazoVista.de(p, widget.desdeCarga);
    final entregados = PendienteFormat.medicamentosEntregados(p.medicamentosEntregados, p.medicamentosTotal);
    final enVigente = vista.estado == CumplimientoPlazo.vigente;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(FgRadius.md),
      side: const BorderSide(color: FgColors.linea, width: FgBorder.w1),
    );
    return Semantics(
      button: true,
      label: 'Orden ${p.ordenMedicamentoId}. $entregados. ${vista.semantica}',
      excludeSemantics: true,
      onTap: widget.onOpen,
      child: FgFocusRing(
        focusNode: _focus,
        child: Material(
          color: FgColors.superficie,
          shape: forma,
          child: InkWell(
            focusNode: _focus,
            customBorder: forma,
            onTap: widget.onOpen,
            hoverColor: FgColors.fondo,
            highlightColor: FgColors.fondo,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 96),
              child: Padding(
                padding: const EdgeInsets.all(FgSpace.sp4h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Orden ${p.ordenMedicamentoId}',
                                style: FgText.num(FgText.h3),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(entregados, style: FgText.caption),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: FgSize.iconoMd, color: FgColors.inkSoft),
                      ],
                    ),
                    const SizedBox(height: FgSpace.sp4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        DeadlineRing(vista: vista, size: DeadlineRingSize.s, decorativo: true),
                        const SizedBox(width: FgSpace.sp4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vista.titular,
                                style: FgText.num(FgText.h2.copyWith(
                                  fontSize: 28,
                                  color: enVigente ? FgColors.ink : vista.estado.texto,
                                )),
                              ),
                              if (vista.palabraEstado != null)
                                Text(
                                  vista.palabraEstado!,
                                  style: FgText.caption.copyWith(color: vista.estado.texto, fontWeight: FontWeight.w700),
                                ),
                              if (vista.subtitulo != null) Text(vista.subtitulo!, style: FgText.caption),
                              Text(vista.fecha, style: FgText.num(FgText.caption)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
