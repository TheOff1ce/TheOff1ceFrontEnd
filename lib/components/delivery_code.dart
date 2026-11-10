import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme/farmago_tokens.dart';
import '../errors/app_error.dart';
import 'farmago/buttons.dart';
import 'farmago/feedback.dart';
import 'farmago/code_input.dart';

/// `123456` → `123 456`, más fácil de dictar y de leer de un vistazo.
String formatDeliveryCode(String code) =>
    code.length == 6 ? '${code.substring(0, 3)} ${code.substring(3)}' : code;

/// Tarjeta del repartidor con el código que le dice al paciente al entregar.
class DriverDeliveryCodeCard extends StatelessWidget {
  const DriverDeliveryCodeCard({super.key, required this.code, required this.awaitingPatient});

  final String code;

  /// En camino o llegando: ya solo falta que el paciente escriba el código.
  final bool awaitingPatient;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(FgSpace.sp5),
          decoration: BoxDecoration(
            color: FgColors.azul100,
            borderRadius: BorderRadius.circular(FgRadius.md),
            border: Border.all(color: FgColors.azul600, width: FgBorder.w2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Código de entrega', style: FgText.label.copyWith(color: FgColors.azul800)),
              const SizedBox(height: FgSpace.sp2),
              FgCodeBoxes(code: code),
              const SizedBox(height: FgSpace.sp2),
              Text(
                awaitingPatient
                    ? 'Díselo al paciente cuando le entregues el pedido. La entrega se cierra cuando lo escriba en su app.'
                    : 'Al entregar, díselo al paciente: él lo escribe en su app para cerrar la entrega.',
                style: FgText.body,
              ),
            ],
          ),
        ),
      );
}

/// Campo del paciente para escribir el código del repartidor y cerrar la entrega.
class PatientConfirmDelivery extends StatefulWidget {
  const PatientConfirmDelivery({super.key, required this.onConfirm, required this.busy});

  /// Devuelve `null` si quedó entregado o el error a mostrar.
  final Future<AppError?> Function(String code) onConfirm;
  final bool busy;

  @override
  State<PatientConfirmDelivery> createState() => _PatientConfirmDeliveryState();
}

class _PatientConfirmDeliveryState extends State<PatientConfirmDelivery> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  String? _fieldError;
  AppError? _serviceError;

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code.text.replaceAll(RegExp(r'\D'), '');
    if (code.length != 6) {
      setState(() => _fieldError = 'Escribe los 6 dígitos que te dice el repartidor.');
      _focus.requestFocus();
      return;
    }
    setState(() {
      _fieldError = null;
      _serviceError = null;
    });
    final error = await widget.onConfirm(code);
    if (!mounted || error == null) return;
    setState(() {
      if (error.code == 'DELIVERY_CODE_INVALID') {
        _fieldError = error.userMessage;
        _code.clear();
        _focus.requestFocus();
      } else {
        _serviceError = error;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(FgSpace.sp5),
        decoration: BoxDecoration(
          color: FgColors.superficie,
          borderRadius: BorderRadius.circular(FgRadius.md),
          border: Border.all(color: FgColors.linea, width: FgBorder.w1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: const Text('¿Ya recibiste tu pedido?', style: FgText.h3)),
            const SizedBox(height: FgSpace.sp2),
            Text(
              'Pídele al repartidor su código de 6 dígitos y escríbelo aquí para confirmar la entrega.',
              style: FgText.body.copyWith(color: FgColors.inkSoft),
            ),
            const SizedBox(height: FgSpace.sp4),
            if (_serviceError != null) ...[
              FgBanner(
                kind: FgBannerKind.error,
                message: _serviceError!.userMessage,
                referencia: _serviceError!.showsReference ? _serviceError!.referenceId : null,
              ),
              const SizedBox(height: FgSpace.sp4),
            ],
            FgCodeInput(
              label: 'Código de entrega',
              controller: _code,
              focusNode: _focus,
              error: _fieldError,
              enabled: !widget.busy,
              onChanged: (_) {
                if (_fieldError != null) setState(() => _fieldError = null);
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: FgSpace.sp4),
            FgButton(
              label: 'Confirmar entrega',
              icon: Icons.check_circle_outline,
              loading: widget.busy,
              loadingLabel: 'Confirmando…',
              expand: true,
              onPressed: _submit,
            ),
          ],
        ),
      );
}
