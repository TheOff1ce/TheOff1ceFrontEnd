import 'package:farma_go/notifications/notification_controller.dart';
import 'package:farma_go/notifications/notification_item.dart';
import 'package:farma_go/notifications/notification_repository.dart';
import 'package:farma_go/pages/notifications_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FailingRepository extends NotificationRepository {
  FailingRepository() : super(persistent: true);

  @override
  Future<List<NotificationItem>> read(String userId) async => throw const NotificationStorageException('denied');

  @override
  Future<void> write(String userId, List<NotificationItem> items) async =>
      throw const NotificationStorageException('denied');
}

void main() {
  test('notification items preserve their persisted state', () {
    final item = NotificationItem(
      id: 'analysis-1',
      title: 'Análisis completado',
      message: 'Identificamos 2 medicamentos.',
      createdAt: DateTime.utc(2026, 10, 2, 15),
      kind: NotificationKind.analysis,
    );
    final restored = NotificationItem.fromJson(item.toJson());
    expect(restored.id, item.id);
    expect(restored.kind, NotificationKind.analysis);
    expect(restored.isRead, isFalse);
    expect(restored.copyWith(isRead: true).isRead, isTrue);
  });

  test('FE-015: storage failures are surfaced instead of swallowed', () async {
    final controller = NotificationController(FailingRepository());
    await controller.loadForUser('user-1');
    expect(controller.storageAvailable, isFalse);
    await controller.addAnalysisCompleted(medicationCount: 1);
    expect(controller.items, hasLength(1));
    expect(controller.storageAvailable, isFalse);
  });

  test('FE-020: on the web notifications are kept only in memory', () async {
    final repository = NotificationRepository(persistent: false);
    await repository.write('user-1', const []);
    expect(await repository.read('user-1'), isEmpty);
  });

  test('a removed notification can be restored (undo)', () async {
    final controller = NotificationController(NotificationRepository(persistent: false));
    await controller.loadForUser('user-1');
    await controller.addAnalysisCompleted(medicationCount: 2);
    final removed = await controller.remove(controller.items.single.id);
    expect(controller.items, isEmpty);
    await controller.restore(removed!);
    expect(controller.items, hasLength(1));
  });

  testWidgets('notification bell exposes its unread count and action', (tester) async {
    var opened = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: NotificationBellButton(unreadCount: 2, onPressed: () => opened = true)),
    ));
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.byTooltip('Notificaciones, 2 sin leer'), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    expect(opened, isTrue);
  });
}
