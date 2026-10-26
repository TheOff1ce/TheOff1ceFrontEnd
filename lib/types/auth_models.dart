class AuthUser {
  const AuthUser({required this.id, required this.name, required this.email, required this.role});

  final String id, name, email, role;

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
