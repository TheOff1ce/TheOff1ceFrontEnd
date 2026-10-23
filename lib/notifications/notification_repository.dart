import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../errors/app_error.dart';
import 'notification_item.dart';

/// Thrown when the device cannot persist notifications.
class NotificationStorageException implements Exception {
  const NotificationStorageException(this.cause);
  final Object cause;
}

/// Stores the notification center per user on mobile/desktop. On the web the
/// center lives only in memory, so no health-related history stays in the
/// browser storage of a shared computer (FE-020).
class NotificationRepository {
  NotificationRepository({FlutterSecureStorage? storage, bool? persistent})
      : _storage = storage ?? const FlutterSecureStorage(),
        persistent = persistent ?? !kIsWeb;

  final FlutterSecureStorage _storage;
  final bool persistent;

  Future<List<NotificationItem>> read(String userId) async {
    if (!persistent) return [];
    final raw = await _readRaw(userId);
    if (raw == null) return [];
    try {
      final data = jsonDecode(raw);
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((item) => NotificationItem.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.id.isNotEmpty)
          .toList();
    } on FormatException catch (error, stackTrace) {
      // Corrupted entry: start clean instead of failing forever, but leave a trace.
      ErrorReporter.reportUnexpected(error, stackTrace);
      return [];
    }
  }

  Future<void> write(String userId, List<NotificationItem> items) async {
    if (!persistent) return;
    try {
      await _storage.write(
        key: _keyFor(userId),
        value: jsonEncode(items.map((item) => item.toJson()).toList()),
      );
    } catch (error, stackTrace) {
      ErrorReporter.reportUnexpected(error, stackTrace);
      throw NotificationStorageException(error);
    }
  }

  Future<String?> _readRaw(String userId) async {
    try {
      return await _storage.read(key: _keyFor(userId));
    } catch (error, stackTrace) {
      ErrorReporter.reportUnexpected(error, stackTrace);
      throw NotificationStorageException(error);
    }
  }

  String _keyFor(String userId) => 'farma_go_notifications_${Uri.encodeComponent(userId)}';
}
