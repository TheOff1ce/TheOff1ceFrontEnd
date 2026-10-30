import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';
import '../../types/pendiente.dart';
import '../../utils/pendiente_format.dart';
import '../../utils/plazo_vista.dart';
import '../farmago/deadline_ring.dart';
import '../farmago/focus_ring.dart';
import '../farmago/status_badge.dart';

/// Tabla de pendientes para tablet y desktop (§8.11).
///
/// Sin orden por columna: la API entrega el orden y no admite ordenar, así que no se ofrecen
/// controles de orden que no funcionarían. El detalle se abre en un panel lateral.
class PendientesTable extends StatelessWidget {
  const PendientesTable({
    super.key,
    required this.items,
    required this.desdeCarga,
    required this.onOpen,
    this.idSeleccionado,
    this.pie,
  });

  final List<PendienteResumen> items;
  final Duration desdeCarga;
  final ValueChanged<PendienteResumen> onOpen;

  /// Fila cuyo detalle está abierto (fondo `--azul-100` y marcador de 4 px).
  final String? idSeleccionado;

  /// Pie de 64 px con paginación.
  final Widget? pie;

  static const _flex = [3, 4, 2, 2, 3];

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: FgColors.superficie,
          borderRadius: BorderRadius.circular(FgRadius.md),
          border: Border.all(color: FgColors.linea, width: FgBorder.w1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Encabezado(),
            for (final p in items)
              _Fila(
                pendiente: p,
                desdeCarga: desdeCarga,
                seleccionada: p.id == idSeleccionado,
                onOpen: () => onOpen(p),
              ),
            if (pie != null) pie!,
          ],
        ),
      );
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    const titulos = ['Orden', 'Plazo', 'Estado', 'Medicamentos', 'Fecha límite'];
    return Container(
      constraints: const BoxConstraints(minHeight: FgSize.encabezadoTabla),
      color: FgColors.fondoHundido,
      padding: const EdgeInsets.symmetric(horizontal: FgSpace.sp4h),
      child: Row(
        children: [
          for (var i = 0; i < titulos.length; i++)
            Expanded(
              flex: PendientesTable._flex[i],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: FgSpace.sp2, vertical: FgSpace.sp2),
                child: Semantics(
                  header: true,
                  child: Text(
                    titulos[i],
                    textAlign: _alinearDerecha(i) ? TextAlign.right : TextAlign.left,
                    style: FgText.caption.copyWith(color: FgColors.ink, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Las columnas numéricas (medicamentos y fecha límite) van a la derecha.
bool _alinearDerecha(int columna) => columna == 3 || columna == 4;

class _Fila extends StatefulWidget {
  const _Fila({required this.pendiente, required this.desdeCarga, required this.seleccionada, required this.onOpen});

  final PendienteResumen pendiente;
  final Duration desdeCarga;
  final bool seleccionada;
  final VoidCallback onOpen;

  @override
  State<_Fila> createState() => _FilaState();
}

class _FilaState extends State<_Fila> {
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
    final entregados = '${p.medicamentosEntregados} / ${p.medicamentosTotal}';
    final celdas = <Widget>[
      Text(p.ordenMedicamentoId, style: FgText.num(FgText.cell)),
      Row(
        children: [
          DeadlineRing(vista: vista, size: DeadlineRingSize.xs, decorativo: true),
          const SizedBox(width: FgSpace.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vista.estado == CumplimientoPlazo.vigente ? vista.titular : (vista.subtitulo ?? vista.titular),
                  style: FgText.num(FgText.cell),
                ),
              ],
            ),
          ),
        ],
      ),
      Align(alignment: Alignment.centerLeft, child: StatusBadge(estado: vista.estado)),
      Text(entregados, textAlign: TextAlign.right, style: FgText.num(FgText.cell)),
      Text(PendienteFormat.fechaHora(p.fechaLimite), textAlign: TextAlign.right, style: FgText.num(FgText.cell)),
    ];
    final contenido = Container(
      constraints: const BoxConstraints(minHeight: FgSize.filaTabla),
      padding: const EdgeInsets.only(left: FgSpace.sp4h - FgBorder.w4, right: FgSpace.sp4h),
      decoration: BoxDecoration(
        color: widget.seleccionada ? FgColors.azul100 : null,
        border: Border(
          top: const BorderSide(color: FgColors.linea, width: FgBorder.w1),
          left: BorderSide(
            color: widget.seleccionada ? FgColors.azul600 : Colors.transparent,
            width: FgBorder.w4,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < celdas.length; i++)
            Expanded(
              flex: PendientesTable._flex[i],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: FgSpace.sp2, vertical: FgSpace.sp2),
                child: celdas[i],
              ),
            ),
        ],
      ),
    );
    return Semantics(
      button: true,
      selected: widget.seleccionada,
      label: 'Orden ${p.ordenMedicamentoId}. ${PendienteFormat.medicamentosEntregados(p.medicamentosEntregados, p.medicamentosTotal)}. '
          '${vista.semantica} Abre el detalle.',
      excludeSemantics: true,
      onTap: widget.onOpen,
      child: FgFocusRing(
        focusNode: _focus,
        inset: true,
        radius: 0,
        child: InkWell(
          focusNode: _focus,
          onTap: widget.onOpen,
          hoverColor: FgColors.fondo,
          highlightColor: FgColors.azul100,
          child: contenido,
        ),
      ),
    );
  }
}
