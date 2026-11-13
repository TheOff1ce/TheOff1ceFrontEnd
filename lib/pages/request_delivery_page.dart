import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../app/theme/farmago_tokens.dart';
import '../components/delivery_widgets.dart';
import '../components/farmago/buttons.dart';
import '../components/farmago/dialogs.dart';
import '../components/farmago/feedback.dart';
import '../hooks/patient_orders_controller.dart';
import '../types/order.dart';
import '../components/farmago/card.dart';

/// Patient asks for a home delivery: pharmacy, address and the medications wanted.
class RequestDeliveryPage extends StatefulWidget {
  const RequestDeliveryPage({
    super.key,
    required this.controller,
    required this.onCreated,
    required this.onBack,
    this.defaultAddress,
  });

  /// Dirección guardada en el perfil: se escribe sola para que la persona no la repita.
  final String? defaultAddress;

  final PatientOrdersController controller;
  final ValueChanged<PatientOrder> onCreated;
  final VoidCallback onBack;

  @override
  State<RequestDeliveryPage> createState() => _RequestDeliveryPageState();
}

class _ItemFields {
  final name = TextEditingController();
  int quantity = 1;

  void dispose() => name.dispose();
}

class _RequestDeliveryPageState extends State<RequestDeliveryPage> {
  static const maxItems = 20;
  final _form = GlobalKey<FormState>();
  final _pharmacyName = TextEditingController();
  final _pharmacyAddress = TextEditingController();
  late final _address = TextEditingController(text: widget.defaultAddress ?? '');
  final _notes = TextEditingController();
  final _items = [_ItemFields()];

  @override
  void dispose() {
    for (final c in [_pharmacyName, _pharmacyAddress, _address, _notes]) {
      c.dispose();
    }
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  static String? _text(String? value, {int min = 2, int max = 120}) {
    final text = value?.trim() ?? '';
    if (text.length < min) return 'Escribe al menos $min caracteres.';
    if (text.length > max) return 'Máximo $max caracteres.';
    if (RegExp(r'[<>{}\\]').hasMatch(text)) return 'Quita los caracteres < > { } \\';
    return null;
  }

  bool get _dirty =>
      _pharmacyName.text.isNotEmpty ||
      _pharmacyAddress.text.isNotEmpty ||
      _notes.text.isNotEmpty ||
      _address.text != (widget.defaultAddress ?? '') ||
      _items.any((i) => i.name.text.isNotEmpty);

  /// Salir con datos escritos pide confirmación: nadie pierde el formulario por un toque.
  Future<void> _back() async {
    if (!_dirty || widget.controller.submitting) return widget.onBack();
    final leave = await showFgConfirm(
      context,
      titulo: '¿Salir sin pedir el domicilio?',
      mensaje: 'Se perderá lo que escribiste.',
      confirmar: 'Salir',
      cancelar: 'Seguir editando',
    );
    if (leave && mounted) widget.onBack();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) {
      showAppSnackBar(context, 'Revisa los campos marcados en rojo.', error: true);
      return;
    }
    final request = DeliveryRequest(
      pharmacy: Pharmacy(name: _pharmacyName.text.trim(), address: _pharmacyAddress.text.trim()),
      deliveryAddress: _address.text.trim(),
      items: [for (final i in _items) OrderItem(name: i.name.text.trim(), quantity: i.quantity)],
      notes: _notes.text,
    );
    final order = await widget.controller.publish(request);
    if (order != null && mounted) widget.onCreated(order);
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => DeliveryScaffold(
            title: 'Pedir domicilio',
            onBack: _back,
            barraAccion: FgButton(
              label: 'Pedir domicilio',
              icon: Icons.delivery_dining,
              size: FgButtonSize.lg,
              expand: true,
              loading: widget.controller.submitting,
              loadingLabel: 'Publicando tu pedido…',
              onPressed: _submit,
            ),
            children: [
              const Text(
                'Un repartidor recoge tu pedido en la farmacia y lo sigues en el mapa hasta tu puerta.',
                style: FgText.bodyLg,
              ),
              const SizedBox(height: FgSpace.sp5),
              ErrorBanner(error: widget.controller.error),
              // Mismas cajas de texto que el resto de la app (no la línea inferior por defecto).
              Builder(
                builder: (context) => Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: AppTheme.light.inputDecorationTheme.copyWith(helperMaxLines: 2),
                  ),
                  child: _formulario(),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _formulario() => Form(
        key: _form,
        // Avisa al salir de cada campo, no solo al final.
        autovalidateMode: AutovalidateMode.onUnfocus,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _section('1. ¿Dónde lo recogemos?', [
            TextFormField(
              controller: _pharmacyName,
              decoration: const InputDecoration(labelText: 'Nombre de la farmacia'),
              textInputAction: TextInputAction.next,
              validator: (v) => _text(v),
            ),
            const SizedBox(height: FgSpace.sp4),
            TextFormField(
              controller: _pharmacyAddress,
              decoration: const InputDecoration(
                labelText: 'Dirección de la farmacia',
                helperText: 'Ejemplo: Calle 72 # 10-20, Bogotá',
              ),
              textInputAction: TextInputAction.next,
              validator: (v) => _text(v, min: 5, max: 300),
            ),
          ]),
          _section('2. ¿A dónde lo llevamos?', [
            TextFormField(
              controller: _address,
              decoration: InputDecoration(
                labelText: 'Tu dirección',
                helperText: (widget.defaultAddress ?? '').isNotEmpty
                    ? 'Es la de tu perfil. Cámbiala si este pedido va a otro lugar.'
                    : 'Ejemplo: Calle 92 # 15-30, Bogotá',
              ),
              textInputAction: TextInputAction.next,
              validator: (v) => _text(v, min: 5, max: 300),
            ),
            const SizedBox(height: FgSpace.sp4),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Indicaciones (opcional)',
                helperText: 'Para el repartidor: portería, torre, apartamento…',
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? null : _text(v, min: 1, max: 500),
            ),
          ]),
          _section('3. ¿Qué te llevamos?', [
            for (final (index, item) in _items.indexed) _itemRow(index, item),
            if (_items.length < maxItems)
              Align(
                alignment: Alignment.centerLeft,
                child: FgButton(
                  label: 'Agregar otro producto',
                  icon: Icons.add,
                  variant: FgButtonVariant.ghost,
                  onPressed: () => setState(() => _items.add(_ItemFields())),
                ),
              ),
          ]),
        ]),
      );

  void _removeItem(int index) {
    final removed = _items.removeAt(index);
    setState(() {});
    // Dispose after the frame, once the fields are no longer in the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  /// Cada paso en su tarjeta: se ve qué va junto y cuánto falta.
  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: FgSpace.sp4),
        child: FgCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [SectionHeading(title), ...children]),
        ),
      );

  Widget _itemRow(int index, _ItemFields item) => Padding(
        padding: const EdgeInsets.only(bottom: FgSpace.sp4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            controller: item.name,
            decoration: InputDecoration(
              labelText: _items.length == 1 ? 'Medicamento o producto' : 'Producto ${index + 1}',
              helperText: index == 0 ? 'Ejemplo: Acetaminofén 500 mg' : null,
            ),
            textInputAction: TextInputAction.next,
            validator: (v) => _text(v),
          ),
          const SizedBox(height: FgSpace.sp2),
          Row(children: [
            QuantityStepper(
              value: item.quantity,
              label: 'Cantidad del producto ${index + 1}',
              onChanged: (value) => setState(() => item.quantity = value),
            ),
            const Spacer(),
            if (_items.length > 1)
              FgButton(
                label: 'Quitar',
                icon: Icons.delete_outline,
                variant: FgButtonVariant.ghost,
                size: FgButtonSize.sm,
                onPressed: () => _removeItem(index),
              ),
          ]),
        ]),
      );
}

/// Cantidad con botones − y +: no deja escribir valores inválidos (1 a 99).
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({super.key, required this.value, required this.onChanged, required this.label});

  static const min = 1, max = 99;

  final int value;
  final ValueChanged<int> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: label,
        value: '$value',
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('Cantidad', style: FgText.label),
          const SizedBox(width: FgSpace.sp3),
          IconButton.outlined(
            tooltip: 'Quitar uno',
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 44,
            child: ExcludeSemantics(
              child: Text('$value', textAlign: TextAlign.center, style: FgText.num(FgText.h3)),
            ),
          ),
          IconButton.outlined(
            tooltip: 'Agregar uno',
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ]),
      );
}
