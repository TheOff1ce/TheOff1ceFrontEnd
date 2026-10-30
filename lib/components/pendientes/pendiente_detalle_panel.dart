import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';
import '../../errors/app_error.dart';
import '../../hooks/pendiente_detail_controller.dart';
import '../../utils/pendientes_rol.dart';
import '../farmago/buttons.dart';
import '../farmago/feedback.dart';
import '../farmago/side_panel.dart';
import 'novedad_form.dart';
import 'pendiente_detalle_view.dart';

/// Contenido del panel lateral de detalle (tablet y desktop).
///
/// El formulario de novedad reemplaza el contenido del panel en vez de abrir otra ventana
/// (manual §7.1: una sola ventana modal a la vez).
class PendienteDetallePanel extends StatefulWidget {
  const PendienteDetallePanel({super.key, required this.createController, required this.rol});

  final PendienteDetailController Function() createController;
  final PendientesRol? rol;

  @override
  State<PendienteDetallePanel> createState() => _PendienteDetallePanelState();
}

class _PendienteDetallePanelState extends State<PendienteDetallePanel> {
  late final PendienteDetailController _controller = widget.createController();
  bool _formulario = false;
  bool _sucio = false;
  bool _avisoCambios = false;

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

  void _volverAlDetalle() => setState(() {
        _formulario = false;
        _sucio = false;
        _avisoCambios = false;
      });

  /// Volver con texto escrito pide descartarlo con Cancelar: no se pierde sin querer.
  void _volverDesdeFormulario() {
    if (_sucio) {
      setState(() => _avisoCambios = true);
    } else {
      _volverAlDetalle();
    }
  }

  Future<AppError?> _registrar(String tipo, String detalle) async {
    final error = await _controller.registrarNovedad(tipo: tipo, detalleNovedad: detalle);
    if (error == null && mounted) {
      _volverAlDetalle();
      showFgToast(context, 'Novedad registrada');
    }
    return error;
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_sucio,
        onPopInvokedWithResult: (cerro, _) {
          if (!cerro) setState(() => _avisoCambios = true);
        },
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final detalle = _controller.detalle;
            final puedeRegistrar = (widget.rol?.puedeRegistrarNovedad ?? false) && detalle != null;
            final titulo = _formulario
                ? 'Registrar novedad'
                : (detalle == null ? 'Detalle del pendiente' : 'Orden ${detalle.resumen.ordenMedicamentoId}');
            return FgPanelScaffold(
              titulo: titulo,
              iconoCerrar: _formulario ? Icons.arrow_back_rounded : Icons.close_rounded,
              tooltipCerrar: _formulario ? 'Volver al detalle' : 'Cerrar',
              onCerrar: _formulario ? _volverDesdeFormulario : () => Navigator.of(context).pop(),
              cuerpo: _formulario
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_avisoCambios) ...[
                          const FgBanner(
                            kind: FgBannerKind.aviso,
                            message: 'Tienes texto sin guardar. Registra la novedad o usa Cancelar para descartarla.',
                          ),
                          const SizedBox(height: FgSpace.sp5),
                        ],
                        NovedadForm(
                          enviando: _controller.submitting,
                          onEnviar: _registrar,
                          onCancelar: _volverAlDetalle,
                          onCambiosSinGuardar: (valor) => setState(() {
                            _sucio = valor;
                            if (!valor) _avisoCambios = false;
                          }),
                        ),
                      ],
                    )
                  : PendienteDetalleCuerpo(controller: _controller, rol: widget.rol),
              pie: !_formulario && puedeRegistrar
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FgButton(
                          label: 'Registrar novedad',
                          icon: Icons.add_rounded,
                          onPressed: () => setState(() => _formulario = true),
                        ),
                      ],
                    )
                  : null,
            );
          },
        ),
      );
}
