import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'notification_item.dart';

class NotificationRepository {
  NotificationRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<List<NotificationItem>> read(String userId) async {
    try {
      final raw = await _storage.read(key: _keyFor(userId));
      if (raw == null) return [];
      final data = jsonDecode(raw);
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((item) => NotificationItem.fromJson(
              Map<String, dynamic>.from(item)))
          .where((item) => item.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> write(String userId, List<NotificationItem> items) async {
    try {
      await _storage.write(
        key: _keyFor(userId),
        value: jsonEncode(items.map((item) => item.toJson()).toList()),
      );
    } catch (_) {
      // The in-memory center remains useful when device storage is unavailable.
    }
  }

  String _keyFor(String userId) =>
      'farma_go_notifications_${Uri.encodeComponent(userId)}';
}
