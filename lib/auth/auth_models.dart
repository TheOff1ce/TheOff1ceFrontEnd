class AuthUser {
  const AuthUser(
      {required this.id,
      required this.name,
      required this.email,
      required this.role});
  final String id, name, email, role;
  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        role: json['role']?.toString() ?? '',
      );
}

class AuthSession {
  const AuthSession({required this.accessToken, required this.expiresIn});
  final String accessToken;
  final int expiresIn;
  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['accessToken']?.toString() ?? '',
        expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      );
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}
