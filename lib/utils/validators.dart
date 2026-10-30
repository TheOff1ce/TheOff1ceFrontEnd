/// Form validators shared by every authentication form (FE-010).
abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _code = RegExp(r'^\d{6}$');
  static const minPasswordLength = 8;

  static String? email(String? value) =>
      value == null || !_email.hasMatch(value.trim())
          ? 'Escribe un correo con el formato nombre@dominio.com.'
          : null;

  static String? password(String? value) =>
      value == null || value.length < minPasswordLength
          ? 'La contraseña debe tener al menos $minPasswordLength caracteres.'
          : null;

  static String? name(String? value) =>
      value == null || value.trim().isEmpty ? 'Escribe tu nombre.' : null;

  static String? Function(String?) confirmation(String Function() original) =>
      (value) => value != original() ? 'Las contraseñas no coinciden.' : null;

  static bool isCode(String value) => _code.hasMatch(value);
}

/// Hides most of the local part of an email: `ana.perez@x.co` → `an•••@x.co`.
/// Never throws, whatever the input (FE-019).
String maskEmail(String? email) {
  final value = email?.trim() ?? '';
  final at = value.indexOf('@');
  if (at <= 0) return value.isEmpty ? 'tu correo' : '•••';
  final visible = at <= 2 ? 1 : 2;
  return '${value.substring(0, visible)}•••${value.substring(at)}';
}
