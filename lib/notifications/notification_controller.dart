import 'package:flutter/foundation.dart';

import 'notification_item.dart';
import 'notification_repository.dart';

class NotificationController extends ChangeNotifier {
  NotificationController(this._repository);

  final NotificationRepository _repository;
  final List<NotificationItem> _items = [];
  String? _userId;
  bool loading = false;

  /// False when the device could not read or save notifications (FE-015).
  bool storageAvailable = true;

  List<NotificationItem> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((item) => !item.isRead).length;
  bool get hasReadItems => _items.any((item) => item.isRead);

  /// Whether notifications survive closing the app on this platform.
  bool get persistsAcrossSessions => _repository.persistent && storageAvailable;

  Future<void> loadForUser(String userId) async {
    if (userId.isEmpty || (_userId == userId && !loading)) return;
    _userId = userId;
    loading = true;
    _items.clear();
    notifyListeners();

    List<NotificationItem> stored;
    try {
      stored = await _repository.read(userId);
      storageAvailable = true;
    } on NotificationStorageException {
      stored = const [];
      storageAvailable = false;
    }
    if (_userId != userId) return;
    _items
      ..clear()
      ..addAll(stored);
    _sort();
    loading = false;
    notifyListeners();
  }

  void clearSession() {
    if (_userId == null && _items.isEmpty && !loading) return;
    _userId = null;
    loading = false;
    _items.clear();
    notifyListeners();
  }

  Future<void> addAnalysisCompleted({required int medicationCount}) async {
    final countText = switch (medicationCount) {
      0 => 'No identificamos medicamentos.',
      1 => 'Identificamos 1 medicamento.',
      _ => 'Identificamos $medicationCount medicamentos.',
    };
    await _add(
      NotificationItem(
        id: 'analysis-${DateTime.now().microsecondsSinceEpoch}',
        title: 'Análisis completado',
        message: '$countText Revisa el resultado antes de gestionar tu solicitud.',
        createdAt: DateTime.now(),
        kind: NotificationKind.analysis,
      ),
    );
  }

  Future<void> markAsRead(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1 || _items[index].isRead) return;
    _items[index] = _items[index].copyWith(isRead: true);
    notifyListeners();
    await _persist();
  }

  Future<void> markAllAsRead() async {
    if (unreadCount == 0) return;
    for (var index = 0; index < _items.length; index++) {
      _items[index] = _items[index].copyWith(isRead: true);
    }
    notifyListeners();
    await _persist();
  }

  /// Removes an item and returns it so the UI can offer "Deshacer".
  Future<NotificationItem?> remove(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return null;
    final removed = _items.removeAt(index);
    notifyListeners();
    await _persist();
    return removed;
  }

  Future<void> restore(NotificationItem item) async {
    if (_items.any((existing) => existing.id == item.id)) return;
    _items.add(item);
    _sort();
    notifyListeners();
    await _persist();
  }

  Future<void> clearRead() async {
    final previousLength = _items.length;
    _items.removeWhere((item) => item.isRead);
    if (_items.length == previousLength) return;
    notifyListeners();
    await _persist();
  }

  Future<void> _add(NotificationItem item) async {
    if (_userId == null) return;
    _items.add(item);
    _sort();
    notifyListeners();
    await _persist();
  }

  void _sort() => _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> _persist() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _repository.write(userId, _items);
      if (!storageAvailable) {
        storageAvailable = true;
        notifyListeners();
      }
    } on NotificationStorageException {
      if (storageAvailable) {
        storageAvailable = false;
        notifyListeners();
      }
    }
  }
}
