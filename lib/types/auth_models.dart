import 'user_profile.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.provider = '',
    this.emailVerified = false,
    this.createdAt,
    this.lastLoginAt,
    this.profile = UserProfile.empty,
    this.profileComplete = true,
    this.profileMissing = const [],
  });

  final String id, name, email, role;

  /// `LOCAL` (correo y contraseña) o `GOOGLE`. Vacío con versiones anteriores de Auth.
  final String provider;
  final bool emailVerified;
  final DateTime? createdAt, lastLoginAt;

  /// Datos del rol (documento, celular, EPS…), pedidos después de crear la cuenta.
  final UserProfile profile;

  /// `false` mientras falte algo obligatorio para el rol. Versiones anteriores de Auth no lo
  /// envían: entonces se considera completo y nadie queda bloqueado.
  final bool profileComplete;

  /// Lo que falta, en orden de formulario (`dataConsent` = aceptar la política de datos).
  final List<String> profileMissing;

  bool get signsInWithGoogle => provider == 'GOOGLE';

  /// Only email-and-password accounts have a FarmaGo password to change.
  bool get hasPassword => !signsInWithGoogle;

  /// Human label for the role code returned by the API (never shown raw).
  String get roleLabel => switch (role) {
        'PATIENT' => 'Paciente',
        'EPS' => 'EPS',
        'DELIVERY_DRIVER' => 'Repartidor',
        'ADMIN' => 'Administrador',
        _ => 'Sin rol asignado',
      };

  bool get isValid => id.isNotEmpty && email.isNotEmpty;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        role: json['role']?.toString() ?? '',
        provider: json['provider']?.toString() ?? '',
        emailVerified: json['emailVerified'] == true,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        lastLoginAt: DateTime.tryParse(json['lastLoginAt']?.toString() ?? ''),
        profile: UserProfile.fromJson(json['profile']),
        profileComplete: json['profileComplete'] != false,
        profileMissing: [
          if (json['profileMissing'] is List)
            for (final item in json['profileMissing'] as List) item.toString(),
        ],
      );
}

class AuthSession {
  const AuthSession({required this.accessToken, required this.expiresIn});

  /// Access tokens live 600 seconds unless the auth service says otherwise.
  static const defaultLifetime = Duration(seconds: 600);

  final String accessToken;
  final int expiresIn;

  bool get isValid => accessToken.isNotEmpty && expiresIn > 0;

  Duration get lifetime => Duration(seconds: expiresIn);

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['accessToken']?.toString() ?? '',
        expiresIn: (json['expiresIn'] as num?)?.toInt() ?? defaultLifetime.inSeconds,
      );
}
