import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../components/delivery_widgets.dart';
import '../components/feedback.dart';
import '../components/ui.dart';
import '../hooks/patient_orders_controller.dart';
import '../types/order.dart';

/// Patient asks for a home delivery: pharmacy, address and the medications wanted.
class RequestDeliveryPage extends StatefulWidget {
  const RequestDeliveryPage({super.key, required this.controller, required this.onCreated, required this.onBack});

  final PatientOrdersController controller;
  final ValueChanged<PatientOrder> onCreated;
  final VoidCallback onBack;

  @override
  State<RequestDeliveryPage> createState() => _RequestDeliveryPageState();
}

class _ItemFields {
  final name = TextEditingController();
  final quantity = TextEditingController(text: '1');

  void dispose() {
    name.dispose();
    quantity.dispose();
  }
}

class _RequestDeliveryPageState extends State<RequestDeliveryPage> {
  static const maxItems = 20;
  final _form = GlobalKey<FormState>();
  final _pharmacyName = TextEditingController();
  final _pharmacyAddress = TextEditingController();
  final _address = TextEditingController();
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

  static String? _quantity(String? value) {
    final n = int.tryParse(value?.trim() ?? '');
    if (n == null || n < 1 || n > 99) return 'Entre 1 y 99';
    return null;
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final request = DeliveryRequest(
      pharmacy: Pharmacy(name: _pharmacyName.text.trim(), address: _pharmacyAddress.text.trim()),
      deliveryAddress: _address.text.trim(),
      items: [for (final i in _items) OrderItem(name: i.name.text.trim(), quantity: int.parse(i.quantity.text.trim()))],
      notes: _notes.text,
    );
    final order = await widget.controller.publish(request);
    if (order != null && mounted) widget.onCreated(order);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => DeliveryScaffold(
          title: 'Pedir domicilio',
          onBack: widget.onBack,
          children: [
            Text('¿Qué necesitas que te llevemos?', style: context.text.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Un repartidor recogerá tu pedido en la farmacia y podrás seguirlo en el mapa.',
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.l),
            ErrorBanner(error: widget.controller.error),
            Form(
              key: _form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _section(context, 'Farmacia'),
                TextFormField(
                  controller: _pharmacyName,
                  decoration: const InputDecoration(labelText: 'Nombre de la farmacia'),
                  textInputAction: TextInputAction.next,
                  validator: (v) => _text(v),
                ),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _pharmacyAddress,
                  decoration: const InputDecoration(labelText: 'Dirección de la farmacia', hintText: 'Calle 72 # 10-20, Bogotá'),
                  textInputAction: TextInputAction.next,
                  validator: (v) => _text(v, min: 5, max: 300),
                ),
                _section(context, 'Entrega'),
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(labelText: 'Tu dirección', hintText: 'Calle 92 # 15-30, Bogotá'),
                  textInputAction: TextInputAction.next,
                  validator: (v) => _text(v, min: 5, max: 300),
                ),
                _section(context, 'Medicamentos o productos'),
                for (final (index, item) in _items.indexed) _itemRow(index, item),
                if (_items.length < maxItems)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _items.add(_ItemFields())),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar otro'),
                    ),
                  ),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Indicaciones (opcional)', hintText: 'Portería, torre, apartamento…'),
                  validator: (v) => (v ?? '').trim().isEmpty ? null : _text(v, min: 1, max: 500),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: widget.controller.submitting ? 'Publicando…' : 'Pedir domicilio',
                  icon: Icons.delivery_dining,
                  onPressed: widget.controller.submitting ? null : _submit,
                ),
              ]),
            ),
          ],
        ),
      );

  void _removeItem(int index) {
    final removed = _items.removeAt(index);
    setState(() {});
    // Dispose after the frame, once the fields are no longer in the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.l, bottom: AppSpacing.s),
        child: Semantics(header: true, child: Text(title, style: context.text.titleMedium)),
      );

  Widget _itemRow(int index, _ItemFields item) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.m),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: TextFormField(
              controller: item.name,
              decoration: InputDecoration(labelText: 'Producto ${index + 1}', hintText: 'Acetaminofén 500 mg'),
              validator: (v) => _text(v),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          SizedBox(
            width: 84,
            child: TextFormField(
              controller: item.quantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cant.'),
              validator: _quantity,
            ),
          ),
          if (_items.length > 1)
            IconButton(
              tooltip: 'Quitar producto ${index + 1}',
              onPressed: () => _removeItem(index),
              icon: const Icon(Icons.close),
            ),
        ]),
      );
}
