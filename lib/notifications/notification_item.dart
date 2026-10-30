enum NotificationKind { analysis, system }

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.kind,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final NotificationKind kind;
  final bool isRead;

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        title: title,
        message: message,
        createdAt: createdAt,
        kind: kind,
        isRead: isRead ?? this.isRead,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'kind': kind.name,
        'isRead': isRead,
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
    );
  }
}
