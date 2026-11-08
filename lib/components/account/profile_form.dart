import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/farmago_tokens.dart';
import '../../auth/auth_controller.dart';
import '../../errors/app_error.dart';
import '../../types/user_profile.dart';
import '../farmago/buttons.dart';
import '../farmago/feedback.dart';
import '../farmago/inputs.dart';

/// Reglas de formato iguales a las de Auth, para avisar antes de enviar.
abstract final class ProfileRules {
  static String normalizeDocument(DocumentType type, String raw) {
    final compact = raw.replaceAll(RegExp(r'[\s.\-]'), '').toUpperCase();
    return type.allowsLetters ? compact : compact.replaceAll(RegExp(r'\D'), '');
  }

  static String? document(DocumentType? type, String raw) {
    if (type == null) return 'Elige el tipo de documento.';
    final number = normalizeDocument(type, raw);
    if (number.isEmpty) return 'Escribe el número de documento.';
    final ok = switch (type) {
      DocumentType.cc => RegExp(r'^\d{5,10}$').hasMatch(number),
      DocumentType.ti => RegExp(r'^\d{10,11}$').hasMatch(number),
      DocumentType.ce => RegExp(r'^[A-Z0-9]{4,12}$').hasMatch(number),
      DocumentType.pa => RegExp(r'^[A-Z0-9]{5,12}$').hasMatch(number),
      DocumentType.ppt => RegExp(r'^\d{5,15}$').hasMatch(number),
    };
    return ok ? null : 'Revisa el número: no tiene el formato de ${type.label.toLowerCase()}.';
  }

  static String? normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^57(?=3\d{9}$)'), '');
    return RegExp(r'^3\d{9}$').hasMatch(digits) ? digits : null;
  }

  static String? normalizePlate(String raw) {
    final plate = raw.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
    return RegExp(r'^[A-Z]{3}\d{3}$').hasMatch(plate) || RegExp(r'^[A-Z]{3}\d{2}[A-Z]$').hasMatch(plate)
        ? plate
        : null;
  }

  /// `DD/MM/AAAA`, un día real en el pasado y dentro de los últimos 120 años.
  static DateTime? parseBirthDate(String raw, {DateTime? now}) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(raw.trim());
    if (match == null) return null;
    final day = int.parse(match[1]!), month = int.parse(match[2]!), year = int.parse(match[3]!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) return null;
    final today = now ?? DateTime.now();
    if (date.isAfter(today) || date.isBefore(DateTime(today.year - 120, today.month, today.day))) return null;
    return date;
  }

  static String formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// Escribe las barras de la fecha a medida que se teclean los números.
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < clipped.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(clipped[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// Datos del rol pedidos después de crear la cuenta (local o Google) y editables en "Mi cuenta".
///
/// - Paciente: documento, celular, fecha de nacimiento, EPS y dirección opcional.
/// - Repartidor: documento, celular, vehículo y placa (no para bicicleta).
/// - EPS: documento, celular, EPS donde trabaja y cargo.
///
/// El documento lo escribe la persona una sola vez; después se muestra fijo. La política de datos
/// se acepta solo la primera vez.
class ProfileForm extends StatefulWidget {
  const ProfileForm({
    super.key,
    required this.auth,
    required this.onDone,
    this.onCancel,
    this.submitLabel = 'Guardar datos',
  });

  final AuthController auth;
  final VoidCallback onDone;
  final VoidCallback? onCancel;
  final String submitLabel;

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late final UserProfile _initial = widget.auth.user?.profile ?? UserProfile.empty;
  late final String _role = widget.auth.user?.role ?? '';

  late DocumentType? _documentType = _initial.documentType;
  late VehicleType? _vehicleType = _initial.vehicleType;
  bool _consent = false;

  late final _document = TextEditingController(text: _initial.documentNumber ?? '');
  late final _phone = TextEditingController(text: _initial.phone ?? '');
  late final _birthDate =
      TextEditingController(text: _initial.birthDate == null ? '' : ProfileRules.formatDate(_initial.birthDate!));
  late final _eps = TextEditingController(text: _role == 'EPS' ? (_initial.organization ?? '') : (_initial.eps ?? ''));
  late final _address = TextEditingController(text: _initial.address ?? '');
  late final _plate = TextEditingController(text: _initial.vehiclePlate ?? '');
  late final _position = TextEditingController(text: _initial.position ?? '');

  final _documentFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _birthFocus = FocusNode();
  final _epsFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _plateFocus = FocusNode();
  final _positionFocus = FocusNode();

  final Map<String, String?> _errors = {};
  AppError? _serviceError;
  bool _busy = false;

  bool get _isPatient => _role == 'PATIENT';
  bool get _isDriver => _role == 'DELIVERY_DRIVER';
  bool get _isEpsStaff => _role == 'EPS';
  bool get _documentLocked => _initial.hasDocument;
  bool get _needsConsent => !_initial.hasConsent;

  @override
  void dispose() {
    for (final c in [_document, _phone, _birthDate, _eps, _address, _plate, _position]) {
      c.dispose();
    }
    for (final f in [_documentFocus, _phoneFocus, _birthFocus, _epsFocus, _addressFocus, _plateFocus, _positionFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  /// Valida todo, marca cada campo y lleva el foco al primero con error.
  ProfileInput? _validate() {
    final errors = <String, String?>{};
    if (!_documentLocked) {
      errors['documentType'] = _documentType == null ? 'Elige el tipo de documento.' : null;
      errors['document'] = _documentType == null ? null : ProfileRules.document(_documentType, _document.text);
    }
    final phone = ProfileRules.normalizePhone(_phone.text);
    errors['phone'] = phone == null ? 'Escribe un celular de 10 dígitos que empiece por 3.' : null;
    DateTime? birth;
    if (_isPatient) {
      birth = ProfileRules.parseBirthDate(_birthDate.text);
      errors['birthDate'] = birth == null ? 'Escribe la fecha como DD/MM/AAAA.' : null;
    }
    if (_isPatient || _isEpsStaff) {
      errors['eps'] = _eps.text.trim().isEmpty
          ? (_isPatient ? 'Escribe tu EPS.' : 'Escribe la EPS donde trabajas.')
          : null;
    }
    if (_isEpsStaff) errors['position'] = _position.text.trim().isEmpty ? 'Escribe tu cargo.' : null;
    String? plate;
    if (_isDriver) {
      errors['vehicleType'] = _vehicleType == null ? 'Elige tu vehículo.' : null;
      if (_vehicleType?.needsPlate ?? false) {
        plate = ProfileRules.normalizePlate(_plate.text);
        errors['plate'] = plate == null ? 'Escribe la placa como ABC123 (carro) o ABC12D (moto).' : null;
      }
    }
    if (_needsConsent) errors['consent'] = _consent ? null : 'Debes aceptar para continuar.';

    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    final focusOrder = <(String, FocusNode?)>[
      ('documentType', _documentFocus),
      ('document', _documentFocus),
      ('phone', _phoneFocus),
      ('birthDate', _birthFocus),
      ('eps', _epsFocus),
      ('position', _positionFocus),
      ('plate', _plateFocus),
    ];
    if (errors.values.any((e) => e != null)) {
      for (final (key, node) in focusOrder) {
        if (errors[key] != null) {
          node?.requestFocus();
          break;
        }
      }
      return null;
    }
    return ProfileInput(
      documentType: _documentLocked ? null : _documentType,
      documentNumber: _documentLocked ? null : ProfileRules.normalizeDocument(_documentType!, _document.text),
      phone: phone,
      birthDate: birth,
      eps: _isPatient ? _eps.text.trim() : null,
      address: _isPatient ? _address.text.trim() : null,
      vehicleType: _isDriver ? _vehicleType : null,
      vehiclePlate: _isDriver ? (plate ?? '') : null,
      organization: _isEpsStaff ? _eps.text.trim() : null,
      position: _isEpsStaff ? _position.text.trim() : null,
      acceptDataPolicy: _needsConsent ? true : null,
    );
  }

  Future<void> _submit() async {
    if (_busy) return;
    final input = _validate();
    if (input == null) return;
    setState(() {
      _busy = true;
      _serviceError = null;
    });
    final error = await widget.auth.saveProfile(input);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      widget.onDone();
      return;
    }
    switch (error.code) {
      case 'DOCUMENT_IN_USE':
        setState(() => _errors['document'] = error.userMessage);
        _documentFocus.requestFocus();
      case 'CONSENT_REQUIRED':
        setState(() => _errors['consent'] = error.userMessage);
      default:
        setState(() => _serviceError = error);
    }
  }

  Widget _gap([double h = FgSpace.sp4]) => SizedBox(height: h);

  Widget _choiceGroup<T>({
    required String label,
    required List<T> values,
    required String Function(T) labelOf,
    required T? selected,
    required ValueChanged<T> onSelected,
    String? error,
  }) =>
      Semantics(
        container: true,
        label: label,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: FgText.label),
            const SizedBox(height: FgSpace.sp2),
            Wrap(
              spacing: FgSpace.sp2,
              runSpacing: FgSpace.sp2,
              children: [
                for (final value in values)
                  FgChip(
                    label: labelOf(value),
                    selected: value == selected,
                    onPressed: _busy ? null : () => onSelected(value),
                  ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: FgSpace.sp1),
              _FieldError(error),
            ],
          ],
        ),
      );

  Widget _epsField({required String label, required String ayuda}) => RawAutocomplete<String>(
        textEditingController: _eps,
        focusNode: _epsFocus,
        optionsBuilder: (value) {
          final query = value.text.trim().toLowerCase();
          if (query.isEmpty) return const Iterable<String>.empty();
          return epsSuggestions.where((eps) => eps.toLowerCase().contains(query)).take(6);
        },
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) => FgTextField(
          label: label,
          controller: controller,
          focusNode: focusNode,
          ayuda: ayuda,
          error: _errors['eps'],
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => onSubmitted(),
        ),
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: FgColors.superficie,
            borderRadius: BorderRadius.circular(FgRadius.sm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: FgSize.dialogSm),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  for (final option in options)
                    ListTile(title: Text(option, style: FgText.body), onTap: () => onSelected(option)),
                ],
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (_serviceError != null) ...[
        FgBanner(kind: FgBannerKind.error, message: _serviceError!.userMessage, referencia: _serviceError!.referenceId),
        _gap(),
      ],
      if (_documentLocked)
        _LockedDocument(type: _initial.documentType!, number: _initial.documentNumber!)
      else ...[
        _choiceGroup<DocumentType>(
          label: 'Tipo de documento',
          values: DocumentType.values,
          labelOf: (t) => t.code == 'PPT' ? 'PPT' : t.label,
          selected: _documentType,
          error: _errors['documentType'],
          onSelected: (t) => setState(() {
            _documentType = t;
            _errors['documentType'] = null;
          }),
        ),
        _gap(),
        FgTextField(
          label: 'Número de documento',
          controller: _document,
          focusNode: _documentFocus,
          error: _errors['document'],
          ayuda: 'Sin puntos ni espacios. Después solo un administrador puede cambiarlo.',
          keyboardType: (_documentType?.allowsLetters ?? false) ? TextInputType.text : TextInputType.number,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _phoneFocus.requestFocus(),
        ),
      ],
      _gap(),
      FgTextField(
        label: 'Celular',
        controller: _phone,
        focusNode: _phoneFocus,
        error: _errors['phone'],
        ayuda: '10 dígitos, empieza por 3.',
        keyboardType: TextInputType.phone,
        autofillHints: const [AutofillHints.telephoneNumberNational],
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => (_isPatient ? _birthFocus : _epsFocus).requestFocus(),
      ),
      if (_isPatient) ...[
        _gap(),
        FgTextField(
          label: 'Fecha de nacimiento',
          controller: _birthDate,
          focusNode: _birthFocus,
          error: _errors['birthDate'],
          ayuda: 'DD/MM/AAAA',
          keyboardType: TextInputType.number,
          inputFormatters: [_DateInputFormatter()],
          autofillHints: const [AutofillHints.birthday],
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _epsFocus.requestFocus(),
        ),
        _gap(),
        _epsField(label: 'EPS', ayuda: 'La EPS a la que estás afiliado.'),
        _gap(),
        FgTextField(
          label: 'Dirección de entrega',
          controller: _address,
          focusNode: _addressFocus,
          opcional: true,
          ayuda: 'La usamos para sugerirla al pedir un domicilio.',
          autofillHints: const [AutofillHints.fullStreetAddress],
          textInputAction: TextInputAction.done,
        ),
      ],
      if (_isEpsStaff) ...[
        _gap(),
        _epsField(label: 'EPS donde trabajas', ayuda: 'El nombre de la EPS.'),
        _gap(),
        FgTextField(
          label: 'Cargo',
          controller: _position,
          focusNode: _positionFocus,
          error: _errors['position'],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
      ],
      if (_isDriver) ...[
        _gap(),
        _choiceGroup<VehicleType>(
          label: 'Vehículo',
          values: VehicleType.values,
          labelOf: (v) => v.label,
          selected: _vehicleType,
          error: _errors['vehicleType'],
          onSelected: (v) => setState(() {
            _vehicleType = v;
            _errors['vehicleType'] = null;
          }),
        ),
        if (_vehicleType?.needsPlate ?? false) ...[
          _gap(),
          FgTextField(
            label: 'Placa',
            controller: _plate,
            focusNode: _plateFocus,
            error: _errors['plate'],
            ayuda: 'ABC123 (carro) o ABC12D (moto).',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ],
      if (_needsConsent) ...[
        _gap(FgSpace.sp5),
        _ConsentCheck(
          value: _consent,
          error: _errors['consent'],
          onChanged: _busy
              ? null
              : (value) => setState(() {
                    _consent = value;
                    _errors['consent'] = null;
                  }),
        ),
      ],
      _gap(FgSpace.sp5),
      Wrap(
        spacing: FgSpace.sp3,
        runSpacing: FgSpace.sp3,
        children: [
          FgButton(
            label: widget.submitLabel,
            loadingLabel: 'Guardando…',
            loading: _busy,
            expand: widget.onCancel == null,
            onPressed: _submit,
          ),
          if (widget.onCancel != null)
            FgButton(label: 'Cancelar', variant: FgButtonVariant.ghost, onPressed: _busy ? null : widget.onCancel),
        ],
      ),
    ];
    return AutofillGroup(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class _LockedDocument extends StatelessWidget {
  const _LockedDocument({required this.type, required this.number});

  final DocumentType type;
  final String number;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Documento', style: FgText.label),
            const SizedBox(height: FgSpace.sp1),
            Text('${type.label} · $number', style: FgText.num(FgText.body)),
            const SizedBox(height: FgSpace.sp1),
            const Text(
              'Para corregirlo, pide ayuda a un administrador.',
              style: FgText.caption,
            ),
          ],
        ),
      );
}

class _ConsentCheck extends StatelessWidget {
  const _ConsentCheck({required this.value, required this.onChanged, this.error});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MergeSemantics(
            child: InkWell(
              borderRadius: BorderRadius.circular(FgRadius.sm),
              onTap: onChanged == null ? null : () => onChanged!(!value),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(value: value, onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false)),
                  const SizedBox(width: FgSpace.sp2),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: FgSpace.sp2),
                      child: Text(
                        'Autorizo a FARMA GO a tratar mis datos personales para gestionar mis medicamentos y '
                        'domicilios, según la Ley 1581 de 2012. Puedo consultarlos, corregirlos o pedir que se '
                        'borren.',
                        style: FgText.body,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: FgSpace.sp1),
              child: _FieldError(error!),
            ),
        ],
      );
}

/// Error bajo un grupo de opciones o la casilla: icono + texto, como en los campos de texto.
class _FieldError extends StatelessWidget {
  const _FieldError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.error_outline_rounded, size: 16, color: FgColors.peligro),
            ),
            const SizedBox(width: FgSpace.sp2),
            Expanded(child: Text(message, style: FgText.caption.copyWith(color: FgColors.peligro))),
          ],
        ),
      );
}
