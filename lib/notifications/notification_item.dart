enum NotificationKind { analysis, delivery, system }

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.kind,
    this.isRead = false,
    this.ruta,
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final NotificationKind kind;
  final bool isRead;

  /// Pantalla que abre la notificación (por ejemplo el seguimiento de un domicilio).
  final String? ruta;

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        title: title,
        message: message,
        createdAt: createdAt,
        kind: kind,
        isRead: isRead ?? this.isRead,
        ruta: ruta,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'kind': kind.name,
        'isRead': isRead,
        if (ruta != null) 'ruta': ruta,
      };

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final kind = NotificationKind.values.where(
      (value) => value.name == json['kind']?.toString(),
    );
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      kind: kind.isEmpty ? NotificationKind.system : kind.first,
      isRead: json['isRead'] == true,
      ruta: json['ruta'] is String && (json['ruta'] as String).startsWith('/') ? json['ruta'] as String : null,
    );
  }
}
