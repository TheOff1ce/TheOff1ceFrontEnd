import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';
import '../../errors/app_error.dart';
import '../../hooks/pendiente_detail_controller.dart';
import '../farmago/buttons.dart';
import '../farmago/feedback.dart';
import '../farmago/inputs.dart';

/// Límites del backend (`novedad.ts`): tipo 50 caracteres, detalle 2000.
const novedadTipoMaximo = 50;
const novedadDetalleMaximo = 2000;

/// Formulario para registrar una novedad (§8.3): dos campos, errores bajo cada uno y un resumen
/// en un banner. Los botones van al final del formulario.
///
/// `tipo` es texto libre: el catálogo de tipos de novedad está pendiente de definir.
class NovedadForm extends StatefulWidget {
  const NovedadForm({
    super.key,
    required this.enviando,
    required this.onEnviar,
    required this.onCancelar,
    required this.onCambiosSinGuardar,
  });

  final bool enviando;

  /// Devuelve el error del envío, o `null` si se registró.
  final Future<AppError?> Function(String tipo, String detalle) onEnviar;
  final VoidCallback onCancelar;

  /// Avisa si hay texto escrito que se perdería al cerrar.
  final ValueChanged<bool> onCambiosSinGuardar;

  @override
  State<NovedadForm> createState() => _NovedadFormState();
}

class _NovedadFormState extends State<NovedadForm> {
  final _tipo = TextEditingController();
  final _detalle = TextEditingController();
  final _focoTipo = FocusNode();
  final _focoDetalle = FocusNode();
  bool _intentado = false;
  bool _tipoTocado = false;
  bool _detalleTocado = false;
  bool _sucio = false;
  AppError? _errorEnvio;

  @override
  void initState() {
    super.initState();
    _tipo.addListener(_cambio);
    _detalle.addListener(_cambio);
    _focoTipo.addListener(() {
      if (!_focoTipo.hasFocus && _tipo.text.isNotEmpty) setState(() => _tipoTocado = true);
    });
    _focoDetalle.addListener(() {
      if (!_focoDetalle.hasFocus && _detalle.text.isNotEmpty) setState(() => _detalleTocado = true);
    });
  }

  @override
  void dispose() {
    _tipo.dispose();
    _detalle.dispose();
    _focoTipo.dispose();
    _focoDetalle.dispose();
    super.dispose();
  }

  void _cambio() {
    final sucio = _tipo.text.isNotEmpty || _detalle.text.isNotEmpty;
    if (sucio != _sucio) {
      _sucio = sucio;
      widget.onCambiosSinGuardar(sucio);
    }
    setState(() {});
  }

  String? get _errorTipo {
    final texto = _tipo.text.trim();
    if (texto.isEmpty) return 'Escribe el tipo de novedad.';
    if (texto.length > novedadTipoMaximo) return 'El tipo no puede superar $novedadTipoMaximo caracteres.';
    return null;
  }

  String? get _errorDetalle {
    final texto = _detalle.text.trim();
    if (texto.isEmpty) return 'Describe la novedad.';
    if (texto.length > novedadDetalleMaximo) {
      return 'El detalle no puede superar $novedadDetalleMaximo caracteres (ahora tiene ${texto.length}).';
    }
    return null;
  }

  Future<void> _enviar() async {
    if (widget.enviando) return;
    setState(() {
      _intentado = true;
      _errorEnvio = null;
    });
    final errorTipo = _errorTipo;
    final errorDetalle = _errorDetalle;
    if (errorTipo != null || errorDetalle != null) {
      (errorTipo != null ? _focoTipo : _focoDetalle).requestFocus();
      return;
    }
    final error = await widget.onEnviar(_tipo.text.trim(), _detalle.text.trim());
    if (mounted && error != null) setState(() => _errorEnvio = error);
  }

  @override
  Widget build(BuildContext context) {
    final mostrarTipo = _intentado || _tipoTocado;
    final mostrarDetalle = _intentado || _detalleTocado;
    final hayErroresVisibles = (mostrarTipo && _errorTipo != null) || (mostrarDetalle && _errorDetalle != null);
    final ancho = MediaQuery.sizeOf(context).width;
    final acciones = FgBreakpoint.esCompacto(ancho)
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FgButton(
                label: 'Registrar novedad',
                loadingLabel: 'Registrando…',
                loading: widget.enviando,
                size: FgButtonSize.lg,
                expand: true,
                onPressed: _enviar,
              ),
              const SizedBox(height: FgSpace.sp4),
              FgButton(
                label: 'Cancelar',
                variant: FgButtonVariant.secondary,
                size: FgButtonSize.lg,
                expand: true,
                onPressed: widget.enviando ? null : widget.onCancelar,
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FgButton(
                label: 'Cancelar',
                variant: FgButtonVariant.secondary,
                onPressed: widget.enviando ? null : widget.onCancelar,
              ),
              const SizedBox(width: FgSpace.sp4),
              FgButton(
                label: 'Registrar novedad',
                loadingLabel: 'Registrando…',
                loading: widget.enviando,
                onPressed: _enviar,
              ),
            ],
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_errorEnvio != null) ...[
          FgBanner(
            kind: FgBannerKind.error,
            message: _errorEnvio!.userMessage,
            referencia: _errorEnvio!.showsReference ? _errorEnvio!.referenceId : null,
          ),
          const SizedBox(height: FgSpace.sp5),
        ] else if (hayErroresVisibles && _intentado) ...[
          const FgBanner(kind: FgBannerKind.error, message: 'Revisa los campos marcados e inténtalo de nuevo.'),
          const SizedBox(height: FgSpace.sp5),
        ],
        FgTextField(
          label: 'Tipo de novedad',
          controller: _tipo,
          focusNode: _focoTipo,
          ayuda: 'Por ejemplo: contacto con el paciente.',
          error: mostrarTipo ? _errorTipo : null,
          textInputAction: TextInputAction.next,
          autofocus: true,
        ),
        const SizedBox(height: FgSpace.sp5),
        FgTextField(
          label: 'Detalle',
          controller: _detalle,
          focusNode: _focoDetalle,
          multilinea: true,
          ayuda: 'Cuenta qué pasó y qué se hizo.',
          error: mostrarDetalle ? _errorDetalle : null,
          textInputAction: TextInputAction.newline,
        ),
        const SizedBox(height: FgSpace.sp6),
        acciones,
      ],
    );
  }
}

/// Registra una novedad en una ventana propia de la pantalla de detalle (§7.1): hoja inferior en
/// móvil y diálogo centrado en tablet/desktop. Devuelve `true` si se registró.
///
/// El panel lateral no usa esto: allí el formulario reemplaza el contenido del panel (una sola
/// ventana modal a la vez).
Future<bool> registrarNovedadEnVentana(
  BuildContext context,
  PendienteDetailController controller, {
  double separacionToast = 0,
}) async {
  final compacto = FgBreakpoint.esCompacto(MediaQuery.sizeOf(context).width);
  final resultado = compacto
      ? await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          enableDrag: false,
          backgroundColor: FgColors.superficie,
          barrierColor: FgColors.scrim,
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(FgRadius.lg)),
          ),
          builder: (contexto) => FarmaGoThemed(child: _VentanaNovedad(controller: controller, compacto: true)),
        )
      : await showDialog<bool>(
          context: context,
          barrierColor: FgColors.scrim,
          builder: (contexto) => FarmaGoThemed(
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.all(FgSpace.sp6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: FgSize.dialogMd),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: FgColors.superficie,
                    borderRadius: BorderRadius.circular(FgRadius.lg),
                    boxShadow: FgShadow.e4,
                  ),
                  child: _VentanaNovedad(controller: controller, compacto: false),
                ),
              ),
            ),
          ),
        );
  final registrada = resultado ?? false;
  if (registrada && context.mounted) {
    showFgToast(context, 'Novedad registrada', separacionInferior: separacionToast);
  }
  return registrada;
}

class _VentanaNovedad extends StatefulWidget {
  const _VentanaNovedad({required this.controller, required this.compacto});

  final PendienteDetailController controller;
  final bool compacto;

  @override
  State<_VentanaNovedad> createState() => _VentanaNovedadState();
}

class _VentanaNovedadState extends State<_VentanaNovedad> {
  bool _sucio = false;
  bool _avisoCambios = false;

  Future<AppError?> _enviar(String tipo, String detalle) async {
    final error = await widget.controller.registrarNovedad(tipo: tipo, detalleNovedad: detalle);
    if (error == null && mounted) {
      _sucio = false;
      Navigator.of(context).pop(true);
    }
    return error;
  }

  @override
  Widget build(BuildContext context) {
    final inferior = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      canPop: !_sucio,
      onPopInvokedWithResult: (cerro, _) {
        if (!cerro) setState(() => _avisoCambios = true);
      },
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            widget.compacto ? FgSpace.sp4h : FgSpace.sp6,
            widget.compacto ? FgSpace.sp5 : FgSpace.sp6,
            widget.compacto ? FgSpace.sp4h : FgSpace.sp6,
            (widget.compacto ? FgSpace.sp5 : FgSpace.sp6) + inferior,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Semantics(header: true, child: const Text('Registrar novedad', style: FgText.h2))),
                  FgIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: FgSpace.sp4),
              if (_avisoCambios) ...[
                const FgBanner(
                  kind: FgBannerKind.aviso,
                  message: 'Tienes texto sin guardar. Registra la novedad o usa Cancelar para descartarla.',
                ),
                const SizedBox(height: FgSpace.sp5),
              ],
              NovedadForm(
                enviando: widget.controller.submitting,
                onEnviar: _enviar,
                onCancelar: () {
                  _sucio = false;
                  Navigator.of(context).pop(false);
                },
                onCambiosSinGuardar: (valor) => setState(() {
                  _sucio = valor;
                  if (!valor) _avisoCambios = false;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
