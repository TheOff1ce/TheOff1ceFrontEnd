import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/farmago_tokens.dart';
import '../../auth/auth_controller.dart';
import '../../errors/app_error.dart';
import '../../types/user_profile.dart';
import '../farmago/buttons.dart';
import '../farmago/feedback.dart';
import '../farmago/inputs.dart';

part 'profile_form_estado.dart';
part 'profile_form_partes.dart';

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
