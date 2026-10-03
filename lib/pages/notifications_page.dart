import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../notifications/notification_controller.dart';
import '../notifications/notification_item.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({
    super.key,
    required this.notifications,
    required this.onBack,
  });

  final NotificationController notifications;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Notificaciones'),
          leading: IconButton(
            tooltip: 'Volver al inicio',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: notifications,
            builder: (context, _) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: notifications.loading
                    ? const Center(child: CircularProgressIndicator())
                    : _NotificationContent(notifications: notifications),
              ),
            ),
          ),
        ),
      );
}

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({
    super.key,
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final countLabel = unreadCount > 9 ? '9+' : '$unreadCount';
    final semanticLabel = unreadCount == 0
        ? 'Notificaciones'
        : 'Notificaciones, $unreadCount sin leer';
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          IconButton(
            tooltip: semanticLabel,
            onPressed: onPressed,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          if (unreadCount > 0)
            Positioned(
              top: 6,
              right: 5,
              child: IgnorePointer(
                child: Container(
                  constraints: const BoxConstraints(minWidth: 17),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  height: 17,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: Text(
                    countLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationContent extends StatelessWidget {
  const _NotificationContent({required this.notifications});

  final NotificationController notifications;

  @override
  Widget build(BuildContext context) {
    if (notifications.items.isEmpty) return const _EmptyNotifications();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
      children: [
        Row(children: [
          Expanded(
            child: Text(
              notifications.unreadCount == 0
                  ? 'Todo al día'
                  : '${notifications.unreadCount} sin leer',
              style: AppText.heading,
            ),
          ),
          if (notifications.unreadCount > 0)
            TextButton(
              onPressed: notifications.markAllAsRead,
              child: const Text('Marcar todas como leídas'),
            ),
        ]),
        const SizedBox(height: 5),
        const Text(
          'Aquí verás actualizaciones sobre los análisis que realizas en FARMA GO.',
          style: AppText.body,
        ),
        if (notifications.hasReadItems)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: notifications.clearRead,
              icon: const Icon(Icons.clear_all_rounded, size: 18),
              label: const Text('Limpiar leídas'),
            ),
          ),
        const SizedBox(height: 8),
        ...notifications.items.map(
          (notification) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _NotificationCard(
              notification: notification,
              onOpen: () => notifications.markAsRead(notification.id),
              onDelete: () => notifications.remove(notification.id),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: AppColors.light,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_none_rounded,
                    size: 36, color: AppColors.navy),
              ),
              const SizedBox(height: 20),
              const Text('No tienes notificaciones',
                  style: AppText.heading, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'Cuando termine un análisis de fórmula, verás la actualización aquí.',
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ),
      );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onOpen,
    required this.onDelete,
  });

  final NotificationItem notification;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return Material(
      color: unread ? const Color(0xFFF1F8FD) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 15, 10, 15),
          decoration: BoxDecoration(
            border: Border.all(color: unread ? AppColors.sky : AppColors.light),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _NotificationKindIcon(kind: notification.kind, unread: unread),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    if (unread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ]),
                  const SizedBox(height: 5),
                  Text(notification.message, style: AppText.body),
                  const SizedBox(height: 9),
                  Text(_relativeTime(notification.createdAt), style: AppText.label),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Eliminar notificación',
              onPressed: onDelete,
              icon: const Icon(Icons.close_rounded, size: 19),
            ),
          ]),
        ),
      ),
    );
  }

  String _relativeTime(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) return 'Ahora';
    if (difference.inHours < 1) return 'Hace ${difference.inMinutes} min';
    if (difference.inDays < 1) return 'Hace ${difference.inHours} h';
    if (difference.inDays == 1) return 'Ayer';
    return 'Hace ${difference.inDays} días';
  }
}

class _NotificationKindIcon extends StatelessWidget {
  const _NotificationKindIcon({required this.kind, required this.unread});

  final NotificationKind kind;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final isAnalysis = kind == NotificationKind.analysis;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: unread ? Colors.white : AppColors.light,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        isAnalysis ? Icons.document_scanner_outlined : Icons.info_outline,
        color: AppColors.navy,
      ),
    );
  }
}
