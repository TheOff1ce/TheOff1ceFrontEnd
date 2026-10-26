import 'package:flutter/material.dart';

import '../app/theme/farmago_tokens.dart';
import '../components/farmago/buttons.dart';
import '../components/farmago/feedback.dart';
import '../components/farmago/inputs.dart';
import '../components/farmago/layout.dart';
import '../components/farmago/side_panel.dart';
import '../components/pendientes/pendiente_card.dart';
import '../components/pendientes/pendiente_detalle_panel.dart';
import '../components/pendientes/pendientes_table.dart';
import '../hooks/pendiente_detail_controller.dart';
import '../hooks/pendientes_list_controller.dart';
import '../types/pendiente.dart';
import '../utils/pendientes_rol.dart';

/// Lista de pendientes (patrón "Lista" del manual, §9).
///
/// - Móvil (< 768): tarjetas; tocar una abre la pantalla de detalle.
/// - Tablet y desktop (>= 768): tabla; tocar una fila abre el detalle en un panel lateral.
class PendientesPage extends StatefulWidget {
  const PendientesPage({
    super.key,
    required this.controller,
    required this.rol,
    required this.createDetailController,
    required this.onOpen,
    required this.onBack,
  });

  final PendientesListController controller;
  final PendientesRol? rol;
  final PendienteDetailController Function(String id) createDetailController;

  /// Abre la pantalla de detalle (móvil).
  final ValueChanged<PendienteResumen> onOpen;
  final VoidCallback onBack;

  @override
  State<PendientesPage> createState() => _PendientesPageState();
}

class _PendientesPageState extends State<PendientesPage> {
  late final TextEditingController _busqueda = TextEditingController(text: widget.controller.orden);
  String? _seleccionado;

  @override
  void initState() {
    super.initState();
    // Después del primer fotograma: cargar notifica a los oyentes y no debe ocurrir al construir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _abrirPanel(PendienteResumen pendiente) async {
    setState(() => _seleccionado = pendiente.id);
    await showFgSidePanel<void>(
      context,
      etiquetaSemantica: 'Detalle del pendiente de la orden ${pendiente.ordenMedicamentoId}',
      builder: (_) => PendienteDetallePanel(
        createController: () => widget.createDetailController(pendiente.id),
        rol: widget.rol,
      ),
    );
    if (mounted) setState(() => _seleccionado = null);
  }

  void _abrir(PendienteResumen pendiente) {
    if (FgBreakpoint.esCompacto(MediaQuery.sizeOf(context).width)) {
      widget.onOpen(pendiente);
    } else {
      _abrirPanel(pendiente);
    }
  }

  void _quitarFiltros() {
    _busqueda.clear();
    widget.controller.quitarFiltros();
  }

  @override
  Widget build(BuildContext context) => FarmaGoThemed(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final c = widget.controller;
            final rol = widget.rol;
            final compacto = FgBreakpoint.esCompacto(MediaQuery.sizeOf(context).width);
            final pagina = c.pagina;
            return FgScreen(
              titulo: rol?.tituloLista ?? 'Pendientes',
              onBack: widget.onBack,
              onRefresh: c.recargar,
              acciones: [
                FgIconButton(icon: Icons.refresh_rounded, tooltip: 'Actualizar', onPressed: c.loading ? null : c.recargar),
              ],
              children: [
                if (rol == PendientesRol.paciente) ...[
                  const FgNota(texto: 'Esta información no reemplaza a tu médico ni a tu EPS.'),
                  const SizedBox(height: FgSpace.sp5),
                ],
                _Filtros(controller: c, busqueda: _busqueda, compacto: compacto),
                SizedBox(height: compacto ? FgSpace.sp4 : FgSpace.sp5),
                if (c.error != null) ...[
                  FgBanner(
                    kind: FgBannerKind.error,
                    title: 'No pudimos cargar los pendientes',
                    message: c.error!.userMessage,
                    referencia: c.error!.showsReference ? c.error!.referenceId : null,
                    actionLabel: 'Reintentar',
                    onAction: c.recargar,
                  ),
                  const SizedBox(height: FgSpace.sp5),
                ],
                if (pagina == null && c.error == null)
                  _EsqueletoLista(compacto: compacto)
                else if (pagina != null && pagina.items.isEmpty)
                  FgEmptyState(
                    titulo: c.filtrosActivos ? 'No encontramos pendientes' : (rol?.vacioTitulo ?? 'No hay pendientes'),
                    mensaje: c.filtrosActivos
                        ? 'Prueba con otro estado o revisa el código de la orden.'
                        : (rol?.vacioMensaje ?? 'Cuando una entrega quede incompleta, la verás aquí.'),
                    accionLabel: c.filtrosActivos ? 'Quitar filtros' : null,
                    onAccion: c.filtrosActivos ? _quitarFiltros : null,
                  )
                else if (pagina != null)
                  // Cada minuto se reconstruye para refrescar los relojes.
                  MinuteTicker(
                    builder: (context) => AnimatedOpacity(
                      opacity: c.loading ? .5 : 1,
                      duration: FgMotion.reducir(context, FgMotion.rapida),
                      child: compacto
                          ? _ListaTarjetas(pagina: pagina, controller: c, onOpen: _abrir)
                          : PendientesTable(
                              items: pagina.items,
                              desdeCarga: c.desdeCarga,
                              idSeleccionado: _seleccionado,
                              onOpen: _abrir,
                              pie: _PaginacionAncha(pagina: pagina, controller: c),
                            ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
}

class _Filtros extends StatelessWidget {
  const _Filtros({required this.controller, required this.busqueda, required this.compacto});

  final PendientesListController controller;
  final TextEditingController busqueda;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final chips = [
      FgChip(
        label: 'Todos',
        selected: controller.estado == null,
        compacto: !compacto,
        onPressed: () => controller.cambiarEstado(null),
      ),
      FgChip(
        label: 'Pendientes',
        selected: controller.estado == EstadoEntrega.pendiente,
        compacto: !compacto,
        onPressed: () => controller.cambiarEstado(EstadoEntrega.pendiente),
      ),
      FgChip(
        label: 'Entregados',
        selected: controller.estado == EstadoEntrega.entregado,
        compacto: !compacto,
        onPressed: () => controller.cambiarEstado(EstadoEntrega.entregado),
      ),
    ];
    final fila = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (indice, chip) in chips.indexed) ...[if (indice > 0) const SizedBox(width: FgSpace.sp2), chip],
      ],
    );
    final campo = FgTextField(
      label: 'Buscar por orden',
      controller: busqueda,
      iconoInicial: Icons.search_rounded,
      limpiable: true,
      ayuda: 'Escribe el código completo de la orden y presiona Intro.',
      textInputAction: TextInputAction.search,
      onSubmitted: controller.buscar,
      onChanged: (valor) {
        if (valor.isEmpty && controller.orden.isNotEmpty) controller.buscar('');
      },
    );
    if (compacto) {
      // Única excepción del manual: los chips se desplazan en horizontal en móvil.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none, // el anillo de foco se dibuja fuera de los chips
            padding: const EdgeInsets.symmetric(vertical: FgSpace.sp2),
            child: fila,
          ),
          const SizedBox(height: FgSpace.sp4),
          campo,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: FgSpace.sp6 + FgSpace.sp1),
            child: Align(alignment: Alignment.centerLeft, child: fila),
          ),
        ),
        const SizedBox(width: FgSpace.sp4),
        SizedBox(width: 320, child: campo),
      ],
    );
  }
}

class _ListaTarjetas extends StatelessWidget {
  const _ListaTarjetas({required this.pagina, required this.controller, required this.onOpen});

  final PaginaPendientes pagina;
  final PendientesListController controller;
  final ValueChanged<PendienteResumen> onOpen;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final p in pagina.items) ...[
            PendienteCard(pendiente: p, desdeCarga: controller.desdeCarga, onOpen: () => onOpen(p)),
            const SizedBox(height: FgSpace.sp4),
          ],
          Text(
            'Mostrando ${pagina.desde}–${pagina.hasta} de ${pagina.total}',
            style: FgText.num(FgText.caption),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: FgSpace.sp4),
          Row(
            children: [
              Expanded(
                child: FgButton(
                  label: 'Anterior',
                  icon: Icons.chevron_left_rounded,
                  variant: FgButtonVariant.secondary,
                  expand: true,
                  onPressed: pagina.hayAnterior && !controller.loading ? controller.anterior : null,
                ),
              ),
              const SizedBox(width: FgSpace.sp4),
              Expanded(
                child: FgButton(
                  label: 'Siguiente',
                  variant: FgButtonVariant.secondary,
                  expand: true,
                  onPressed: pagina.haySiguiente && !controller.loading ? controller.siguiente : null,
                ),
              ),
            ],
          ),
        ],
      );
}

/// Pie de la tabla (§8.11): "Mostrando 1–25 de 128", filas por página y anterior/siguiente.
class _PaginacionAncha extends StatelessWidget {
  const _PaginacionAncha({required this.pagina, required this.controller});

  final PaginaPendientes pagina;
  final PendientesListController controller;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: FgSize.pieTabla),
        padding: const EdgeInsets.symmetric(horizontal: FgSpace.sp4h, vertical: FgSpace.sp2),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: FgColors.linea, width: FgBorder.w1)),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: FgSpace.sp2,
          spacing: FgSpace.sp4,
          children: [
            Text('Mostrando ${pagina.desde}–${pagina.hasta} de ${pagina.total}', style: FgText.num(FgText.caption)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Filas por página', style: FgText.caption),
                const SizedBox(width: FgSpace.sp2),
                _SelectorFilas(controller: controller),
                const SizedBox(width: FgSpace.sp4),
                FgButton(
                  label: 'Anterior',
                  icon: Icons.chevron_left_rounded,
                  variant: FgButtonVariant.secondary,
                  onPressed: pagina.hayAnterior && !controller.loading ? controller.anterior : null,
                ),
                const SizedBox(width: FgSpace.sp2),
                FgButton(
                  label: 'Siguiente',
                  variant: FgButtonVariant.secondary,
                  onPressed: pagina.haySiguiente && !controller.loading ? controller.siguiente : null,
                ),
              ],
            ),
          ],
        ),
      );
}

class _SelectorFilas extends StatelessWidget {
  const _SelectorFilas({required this.controller});

  final PendientesListController controller;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Filas por página',
        child: Container(
          height: FgSize.ctrlMd,
          padding: const EdgeInsets.symmetric(horizontal: FgSpace.sp3),
          decoration: BoxDecoration(
            color: FgColors.superficie,
            borderRadius: BorderRadius.circular(FgRadius.sm),
            border: Border.all(color: FgColors.lineaControl, width: FgBorder.w2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: controller.limite,
              style: FgText.body,
              borderRadius: BorderRadius.circular(FgRadius.md),
              dropdownColor: FgColors.superficie,
              icon: const Icon(Icons.expand_more_rounded, size: FgSize.iconoMd),
              items: [
                for (final limite in PendientesListController.limitesPermitidos)
                  DropdownMenuItem(value: limite, child: Text('$limite')),
              ],
              onChanged: controller.loading
                  ? null
                  : (valor) {
                      if (valor != null) controller.cambiarLimite(valor);
                    },
            ),
          ),
        ),
      );
}

class _EsqueletoLista extends StatelessWidget {
  const _EsqueletoLista({required this.compacto});

  final bool compacto;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Cargando los pendientes',
        liveRegion: true,
        child: compacto
            ? Column(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    const FgSkeleton(alto: 148, radio: FgRadius.md),
                    const SizedBox(height: FgSpace.sp4),
                  ],
                ],
              )
            : Column(
                children: [
                  const FgSkeleton(alto: FgSize.encabezadoTabla, radio: FgRadius.md),
                  for (var i = 0; i < 5; i++) ...[
                    const SizedBox(height: FgSpace.sp2),
                    const FgSkeleton(alto: FgSize.filaTabla, radio: FgRadius.sm),
                  ],
                ],
              ),
      );
}
