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
  });

  final String id, name, email, role;

  /// `LOCAL` (correo y contraseña) o `GOOGLE`. Vacío con versiones anteriores de Auth.
  final String provider;
  final bool emailVerified;
  final DateTime? createdAt, lastLoginAt;

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
