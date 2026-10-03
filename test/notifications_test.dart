import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farma_go/notifications/notification_item.dart';
import 'package:farma_go/pages/notifications_page.dart';

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

  testWidgets('notification bell exposes its unread count and action',
      (tester) async {
    var opened = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NotificationBellButton(
          unreadCount: 2,
          onPressed: () => opened = true,
        ),
      ),
    ));

    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    expect(opened, isTrue);
  });
}
