import 'package:flutter/material.dart';

import '../../../app/theme/farmago_tokens.dart';
import '../../../types/ordenes.dart';
import '../../../utils/pendiente_format.dart';
import '../buttons.dart';
import '../entrada.dart';
import '../focus_ring.dart';
import 'orden_sellos.dart';
import 'ordenes_textos.dart';

/// Tarjeta de una orden (§3.2 del handoff): encabezado con el arco de vigencia, franja «Estados
/// según tu EPS», una fila por medicamento y, si se puede, el pie para pedir a domicilio.
///
/// Es plana (solo borde) porque vive en una lista de 2 o más. Con una selección, su borde pasa a
/// `azul600` y sube a `e2`: es la unidad activa del pedido (D5). Dentro no hay tarjetas anidadas:
/// las filas son filas de lista y la nota va en un bloque `fondoHundido`.
class OrdenCard extends StatelessWidget {
  const OrdenCard({
    super.key,
    required this.orden,
    required this.consultadoEn,
    required this.marcados,
    required this.actualizados,
    required this.onAlternar,
    required this.onElegirTodos,
    this.retrasoBase = Duration.zero,
    this.tienePendiente,
    this.onVerPendientes,
  });

  final Orden orden;
  final DateTime consultadoEn;

  /// Medicamentos marcados de esta orden.
  final Set<String> marcados;

  /// Ids de medicamento u orden actualizados por un 409 (hasta la próxima recarga).
  final Set<String> actualizados;
  final ValueChanged<MedicamentoOrden> onAlternar;
  final VoidCallback onElegirTodos;

  /// Retraso de entrada de la tarjeta; sus filas suman `(j + 1) × 60 ms` (tope j = 5).
  final Duration retrasoBase;

  /// Cruce con Pendientes (AC-25). Sin él no se muestra el enlace.
  final bool Function(MedicamentoOrden)? tienePendiente;
  final void Function(MedicamentoOrden)? onVerPendientes;

  @override
  Widget build(BuildContext context) {
    final compacto = FgBreakpoint.esCompacto(MediaQuery.sizeOf(context).width);
    final relleno = compacto ? FgSpace.sp4h : FgSpace.sp5;
    final conSeleccion = marcados.isNotEmpty;
    final nota = _notaDeOrden();
    final elegibles = orden.elegibles;
    final actualizada = actualizados.contains(orden.id);
    return _FondoActualizado(
      activo: actualizada,
      radio: FgRadius.md,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: FgColors.superficie,
          borderRadius: BorderRadius.circular(FgRadius.md),
          border: Border.all(color: conSeleccion ? FgColors.azul600 : FgColors.lineaSuave, width: FgBorder.w1),
          boxShadow: conSeleccion ? FgShadow.tarjetaHover : FgShadow.tarjeta,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(relleno),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Encabezado(orden: orden, consultadoEn: consultadoEn, compacto: compacto),
                  if (nota != null) ...[const SizedBox(height: FgSpace.sp4), nota],
                ],
              ),
            ),
            Container(
              color: FgColors.fondoHundido,
              padding: EdgeInsets.symmetric(horizontal: relleno, vertical: FgSpace.sp3),
              child: Text(OrdenesTextos.medicamentos(orden.medicamentos.length), style: FgText.label),
            ),
            // La instrucción va antes de las filas: quien llega a ellas ya sabe que son casillas.
            if (orden.admiteSeleccion && elegibles.isNotEmpty)
              _Instruccion(
                elegibles: elegibles.length,
                marcados: marcados.length,
                relleno: relleno,
                onElegirTodos: onElegirTodos,
              ),
            for (final (j, m) in orden.medicamentos.indexed) ...[
              if (j > 0) const Divider(height: FgBorder.w1, thickness: FgBorder.w1, color: FgColors.linea),
              FgEntrada(
                retraso: retrasoBase + FgMotion.escalon * ((j < 5 ? j : 5) + 1),
                child: MedicamentoOrdenRow(
                  orden: orden,
                  medicamento: m,
                  marcado: marcados.contains(m.id),
                  actualizado: actualizados.contains(m.id),
                  relleno: relleno,
                  compacto: compacto,
                  onAlternar: () => onAlternar(m),
                  tienePendiente: tienePendiente?.call(m) ?? false,
                  onVerPendientes: onVerPendientes == null ? null : () => onVerPendientes!(m),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _notaDeOrden() {
    if (orden.vigencia == Vigencia.vencida) {
      return const _NotaOrden(icono: Icons.visibility_outlined, texto: OrdenesTextos.notaVencida);
    }
    if (orden.vencimiento == null) {
      return const _NotaOrden(icono: Icons.info_outline, texto: OrdenesTextos.notaSinVencimiento);
    }
    return null;
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.orden, required this.consultadoEn, required this.compacto});

  final Orden orden;
  final DateTime consultadoEn;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final vencida = orden.vigencia == Vigencia.vencida;
    final vence = orden.vencimiento;
    final conArco = vencida || vence != null;
    final String titulo;
    final String linea;
    if (vencida) {
      titulo = vence == null ? 'Orden vencida' : 'Venció el ${PendienteFormat.fechaHora(vence)}';
      linea = 'Ordenada el ${PendienteFormat.fecha(orden.fechaOrden)}';
    } else if (vence == null) {
      titulo = 'Sin fecha de vencimiento';
      linea = 'Ordenada el ${PendienteFormat.fecha(orden.fechaOrden)}';
    } else {
      titulo = ArcoOrden.de(orden, consultadoEn).titulo;
      linea = 'Vence el ${PendienteFormat.fechaHora(vence)} · Ordenada el ${PendienteFormat.fecha(orden.fechaOrden)}';
    }
    final estiloTitulo = (compacto ? FgText.h3 : FgText.h2).copyWith(color: vencida ? FgColors.inkSoft : FgColors.ink);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (conArco) ...[
          OrdenArco(orden: orden, consultadoEn: consultadoEn),
          const SizedBox(width: FgSpace.sp4),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: FgSpace.sp3,
                children: [
                  orden.vigencia.sello,
                  Text(OrdenesTextos.ordenId(orden.id), style: FgText.num(FgText.caption)),
                ],
              ),
              Semantics(header: true, child: Text(titulo, style: FgText.num(estiloTitulo))),
              const SizedBox(height: FgSpace.sp1),
              Text(linea, style: FgText.num(FgText.caption)),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotaOrden extends StatelessWidget {
  const _NotaOrden({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(FgSpace.sp3),
        decoration: BoxDecoration(color: FgColors.fondoHundido, borderRadius: BorderRadius.circular(FgRadius.sm)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Icon(icono, size: FgSize.iconoMd, color: FgColors.inkSoft)),
            const SizedBox(width: FgSpace.sp3),
            Expanded(child: Text(texto, style: FgText.caption.copyWith(color: FgColors.ink))),
          ],
        ),
      );
}

class _Instruccion extends StatelessWidget {
  const _Instruccion({required this.elegibles, required this.marcados, required this.relleno, required this.onElegirTodos});

  final int elegibles;
  final int marcados;
  final double relleno;
  final VoidCallback onElegirTodos;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: FgColors.linea, width: FgBorder.w1)),
        ),
        padding: EdgeInsets.symmetric(horizontal: relleno, vertical: FgSpace.sp2),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: FgSpace.sp4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ExcludeSemantics(child: Icon(Icons.local_shipping_outlined, size: FgSize.iconoMd, color: FgColors.azul800)),
                const SizedBox(width: FgSpace.sp3),
                Flexible(child: Text(OrdenesTextos.puedesPedir(elegibles), style: FgText.caption.copyWith(color: FgColors.ink))),
              ],
            ),
            if (elegibles >= 2 && marcados < elegibles)
              FgLinkButton(label: OrdenesTextos.elegirLos(elegibles), onPressed: onElegirTodos),
          ],
        ),
      );
}

/// Fila de un medicamento. Si es elegible, toda la fila es la casilla (objetivo táctil ≥ 56).
class MedicamentoOrdenRow extends StatefulWidget {
  const MedicamentoOrdenRow({
    super.key,
    required this.orden,
    required this.medicamento,
    required this.marcado,
    required this.actualizado,
    required this.relleno,
    required this.compacto,
    required this.onAlternar,
    this.tienePendiente = false,
    this.onVerPendientes,
  });

  final Orden orden;
  final MedicamentoOrden medicamento;
  final bool marcado;
  final bool actualizado;
  final double relleno;
  final bool compacto;
  final VoidCallback onAlternar;
  final bool tienePendiente;
  final VoidCallback? onVerPendientes;

  @override
  State<MedicamentoOrdenRow> createState() => _MedicamentoOrdenRowState();
}

class _MedicamentoOrdenRowState extends State<MedicamentoOrdenRow> {
  final _foco = FocusNode();
  bool _encima = false;

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  bool get _seleccionable => widget.orden.admiteSeleccion && widget.medicamento.elegibleParaDomicilio;

  @override
  Widget build(BuildContext context) {
    final m = widget.medicamento;
    final seleccionable = _seleccionable;
    final reservaCasilla = widget.orden.admiteSeleccion;
    final motivos = widget.orden.vigencia == Vigencia.vencida || m.elegibleParaDomicilio
        ? null
        : OrdenesTextos.frasesMotivosFila(m.motivosNoElegible);
    final estados = Wrap(
      spacing: FgSpace.sp4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [m.autorizacion.sello, ReclamacionTexto(reclamacion: m.reclamacion)],
    );
    final contenido = Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.relleno, vertical: FgSpace.sp3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (seleccionable) ...[
            Padding(
              padding: const EdgeInsets.only(top: FgSpace.sp1),
              child: _Casilla(marcada: widget.marcado),
            ),
            const SizedBox(width: FgSpace.sp3),
          ] else if (reservaCasilla) ...[
            const SizedBox(width: FgSize.casilla + FgSpace.sp3),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final ancho = c.maxWidth >= 560;
                final datos = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.nombre.isEmpty ? 'Medicamento sin nombre' : m.nombre,
                      style: FgText.h3,
                      softWrap: true,
                    ),
                    if (m.detalle.isNotEmpty) Text(m.detalle, style: FgText.caption),
                    if (!ancho) ...[const SizedBox(height: FgSpace.sp2), estados],
                    if (motivos != null) ...[
                      const SizedBox(height: FgSpace.sp2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ExcludeSemantics(child: Icon(Icons.block, size: FgSize.iconoSm, color: FgColors.inkSoft)),
                          const SizedBox(width: FgSpace.sp2),
                          Expanded(child: Text(motivos, style: FgText.caption)),
                        ],
                      ),
                    ],
                    if (widget.actualizado) ...[
                      const SizedBox(height: FgSpace.sp2),
                      const Row(
                        children: [
                          ExcludeSemantics(child: Icon(Icons.sync, size: FgSize.iconoSm, color: FgColors.riesgoFg)),
                          SizedBox(width: FgSpace.sp2),
                          Flexible(
                            child: Text(
                              OrdenesTextos.actualizadoPorEps,
                              style: TextStyle(
                                fontFamily: FgText.family,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                                color: FgColors.riesgoFg,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (widget.tienePendiente && widget.onVerPendientes != null) ...[
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(OrdenesTextos.tienePendiente, style: FgText.caption),
                          FgLinkButton(label: OrdenesTextos.verEnPendientes, onPressed: widget.onVerPendientes),
                        ],
                      ),
                    ],
                  ],
                );
                if (!ancho) return datos;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: datos),
                    const SizedBox(width: FgSpace.sp4),
                    Padding(
                      padding: const EdgeInsets.only(top: FgSpace.sp1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [m.autorizacion.sello, ReclamacionTexto(reclamacion: m.reclamacion)],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
    final fondo = widget.marcado
        ? FgColors.azul100
        : (seleccionable && _encima ? FgColors.fondo : FgColors.superficie);
    final fila = _FondoActualizado(
      activo: widget.actualizado,
      radio: 0,
      child: AnimatedContainer(
        duration: FgMotion.reducir(context, FgMotion.rapida),
        curve: FgMotion.ease,
        color: fondo,
        constraints: const BoxConstraints(minHeight: FgSize.filaTabla),
        child: contenido,
      ),
    );
    if (!seleccionable) return fila;
    return Semantics(
      container: true,
      checked: widget.marcado,
      label: 'Pedir a domicilio ${m.nombre}',
      onTap: widget.onAlternar,
      child: MouseRegion(
        onEnter: (_) => setState(() => _encima = true),
        onExit: (_) => setState(() => _encima = false),
        cursor: SystemMouseCursors.click,
        child: FgFocusRing(
          focusNode: _foco,
          radius: 0,
          inset: true,
          child: InkWell(
            focusNode: _foco,
            onTap: widget.onAlternar,
            hoverColor: Colors.transparent,
            child: fila,
          ),
        ),
      ),
    );
  }
}

/// Casilla de 28×28 (§8.4). El check entra con escala 0,6→1 y opacidad en 220 ms.
class _Casilla extends StatelessWidget {
  const _Casilla({required this.marcada});

  final bool marcada;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: AnimatedContainer(
          duration: FgMotion.reducir(context, FgMotion.rapida),
          curve: FgMotion.ease,
          width: FgSize.casilla,
          height: FgSize.casilla,
          decoration: BoxDecoration(
            color: marcada ? FgColors.azul600 : FgColors.superficie,
            borderRadius: BorderRadius.circular(FgRadius.sm),
            border: Border.all(color: marcada ? FgColors.azul600 : FgColors.lineaControl, width: FgBorder.w2),
          ),
          alignment: Alignment.center,
          child: AnimatedScale(
            scale: marcada ? 1 : .6,
            duration: FgMotion.reducir(context, FgMotion.media),
            curve: FgMotion.ease,
            child: AnimatedOpacity(
              opacity: marcada ? 1 : 0,
              duration: FgMotion.reducir(context, FgMotion.media),
              curve: FgMotion.ease,
              child: const Icon(Icons.check, size: FgSize.iconoSm, color: FgColors.blanco, weight: 700),
            ),
          ),
        ),
      );
}

/// Fondo `riesgo-bg` que se mantiene al 100 % el 40 % de 2,4 s y luego se desvanece (D6).
/// Solo anima cuando `activo` pasa de falso a verdadero, no al reconstruirse con un valor ya activo.
class _FondoActualizado extends StatefulWidget {
  const _FondoActualizado({required this.activo, required this.radio, required this.child});

  final bool activo;
  final double radio;
  final Widget child;

  @override
  State<_FondoActualizado> createState() => _FondoActualizadoState();
}

class _FondoActualizadoState extends State<_FondoActualizado> with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void didUpdateWidget(_FondoActualizado vieja) {
    super.didUpdateWidget(vieja);
    if (widget.activo && !vieja.activo && !MediaQuery.disableAnimationsOf(context)) {
      _controlador.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controlador,
        builder: (context, hijo) {
          final t = _controlador.value;
          final opacidad = t == 0 || t >= 1 ? 0.0 : (t < .4 ? 1.0 : 1 - Curves.easeOut.transform((t - .4) / .6));
          return DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              color: FgColors.riesgoBg.withValues(alpha: opacidad * .85),
              borderRadius: BorderRadius.circular(widget.radio),
            ),
            child: hijo,
          );
        },
        child: widget.child,
      );
}
