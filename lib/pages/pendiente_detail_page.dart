import 'package:flutter/material.dart';

import '../app/theme/farmago_tokens.dart';
import '../components/farmago/buttons.dart';
import '../components/farmago/layout.dart';
import '../components/pendientes/novedad_form.dart';
import '../components/pendientes/pendiente_detalle_view.dart';
import '../hooks/pendiente_detail_controller.dart';
import '../utils/pendientes_rol.dart';

/// Detalle de un pendiente (patrón "Detalle", §9).
///
/// En móvil es una pantalla completa con la acción principal en la barra fija inferior; en
/// pantallas anchas (enlace directo) la acción va en el contenido. Desde la lista, en tablet y
/// desktop el detalle se abre en un panel lateral (`PendienteDetallePanel`).
class PendienteDetailPage extends StatefulWidget {
  const PendienteDetailPage({super.key, required this.rol, required this.createController, required this.onBack});

  final PendientesRol? rol;
  final PendienteDetailController Function() createController;
  final VoidCallback onBack;

  @override
  State<PendienteDetailPage> createState() => _PendienteDetailPageState();
}

class _PendienteDetailPageState extends State<PendienteDetailPage> {
  late final PendienteDetailController _controller = widget.createController();

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _registrar(BuildContext context, {required bool conBarra}) =>
      registrarNovedadEnVentana(context, _controller, separacionToast: conBarra ? FgSize.barraAccion : 0);

  @override
  Widget build(BuildContext context) => FarmaGoThemed(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final detalle = _controller.detalle;
            final compacto = FgBreakpoint.esCompacto(MediaQuery.sizeOf(context).width);
            final puedeRegistrar = (widget.rol?.puedeRegistrarNovedad ?? false) && detalle != null;
            return FgScreen(
              titulo: detalle == null ? 'Pendiente' : 'Orden ${detalle.resumen.ordenMedicamentoId}',
              onBack: widget.onBack,
              onRefresh: () => _controller.load(silencioso: true),
              acciones: [
                FgIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Actualizar',
                  onPressed: _controller.loading ? null : () => _controller.load(silencioso: _controller.detalle != null),
                ),
              ],
              barraAccion: compacto && puedeRegistrar
                  ? FgButton(
                      label: 'Registrar novedad',
                      size: FgButtonSize.lg,
                      expand: true,
                      onPressed: () => _registrar(context, conBarra: true),
                    )
                  : null,
              children: [
                if (!compacto && puedeRegistrar) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: FgButton(
                      label: 'Registrar novedad',
                      icon: Icons.add_rounded,
                      onPressed: () => _registrar(context, conBarra: false),
                    ),
                  ),
                  const SizedBox(height: FgSpace.sp5),
                ],
                PendienteDetalleCuerpo(controller: _controller, rol: widget.rol),
              ],
            );
          },
        ),
      );
}
