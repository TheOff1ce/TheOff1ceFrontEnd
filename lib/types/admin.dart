/// Models of the administrator back-office (TheOff1ceAuth `/admin/users`, OrderDelivery `/orders/admin`).
library;

import 'order.dart';

/// Roles issued by TheOff1ceAuth.
enum UserRole {
  patient('PATIENT', 'Paciente'),
  eps('EPS', 'EPS'),
  driver('DELIVERY_DRIVER', 'Repartidor'),
  admin('ADMIN', 'Administrador');

  const UserRole(this.code, this.label);

  final String code, label;

  static UserRole? fromCode(Object? code) {
    for (final role in values) {
      if (role.code == code) return role;
    }
    return null;
  }
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.provider,
    required this.emailVerified,
    this.createdAt,
    this.lastLoginAt,
  });

  final String id, name, email, provider;
  final UserRole? role;
  final bool emailVerified;
  final DateTime? createdAt, lastLoginAt;

  String get roleLabel => role?.label ?? 'Sin rol';

  bool get isGoogle => provider == 'GOOGLE';

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        role: UserRole.fromCode(json['role']),
        provider: json['provider']?.toString() ?? '',
        emailVerified: json['emailVerified'] == true,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        lastLoginAt: DateTime.tryParse(json['lastLoginAt']?.toString() ?? ''),
      );

  AdminUser copyWith({UserRole? role}) => AdminUser(
        id: id,
        name: name,
        email: email,
        role: role ?? this.role,
        provider: provider,
        emailVerified: emailVerified,
        createdAt: createdAt,
        lastLoginAt: lastLoginAt,
      );
}

class UserPage {
  const UserPage({required this.users, required this.total, required this.page, required this.pageSize});

  final List<AdminUser> users;
  final int total, page, pageSize;

  bool get hasMore => page * pageSize < total;

  factory UserPage.fromJson(Map<String, dynamic> json) {
    final raw = json['users'];
    if (raw is! List) throw const FormatException('Expected a users list');
    return UserPage(
      users: [for (final item in raw) if (item is Map<String, dynamic>) AdminUser.fromJson(item)],
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
    );
  }
}

/// Which orders the administrator wants to see.
enum AdminOrderFilter {
  pending('pending', 'Pendientes'),
  published('PUBLISHED', 'Sin repartidor'),
  taken('TAKEN', 'En curso'),
  cancelled('CANCELLED', 'Cancelados'),
  all('all', 'Todos');

  const AdminOrderFilter(this.code, this.label);

  final String code, label;
}

/// Every detail of an order, including who requested and who took it.
class AdminOrder {
  const AdminOrder({required this.order, required this.patientId, required this.driverId});

  final PatientOrder order;
  final String patientId;
  final String? driverId;

  String get id => order.id;

  factory AdminOrder.fromJson(Map<String, dynamic> json) => AdminOrder(
        order: PatientOrder.fromJson(json),
        patientId: json['patientId']?.toString() ?? '',
        driverId: json['driverId']?.toString(),
      );
}
