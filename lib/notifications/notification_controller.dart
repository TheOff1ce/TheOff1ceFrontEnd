import 'package:flutter/foundation.dart';

import 'notification_item.dart';
import 'notification_repository.dart';

class NotificationController extends ChangeNotifier {
  NotificationController(this._repository);

  final NotificationRepository _repository;
  final List<NotificationItem> _items = [];
  String? _userId;
  bool loading = false;

  List<NotificationItem> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((item) => !item.isRead).length;
  bool get hasReadItems => _items.any((item) => item.isRead);

  Future<void> loadForUser(String userId) async {
    if (userId.isEmpty || (_userId == userId && !loading)) return;
    _userId = userId;
    loading = true;
    _items.clear();
    notifyListeners();

    final stored = await _repository.read(userId);
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
    final countText = medicationCount == 1
        ? 'Identificamos 1 medicamento.'
        : 'Identificamos $medicationCount medicamentos.';
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

  Future<void> remove(String id) async {
    final previousLength = _items.length;
    _items.removeWhere((item) => item.id == id);
    if (_items.length == previousLength) return;
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
    if (userId != null) await _repository.write(userId, _items);
  }
}
