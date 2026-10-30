import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../components/feedback.dart';
import '../notifications/notification_controller.dart';
import '../notifications/notification_item.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key, required this.notifications, required this.onBack});

  final NotificationController notifications;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Notificaciones'),
          leading: IconButton(tooltip: 'Volver al inicio', onPressed: onBack, icon: const Icon(Icons.arrow_back)),
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: notifications,
            builder: (context, _) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: notifications.loading
                    ? const Center(child: DelayedSpinner(label: 'Cargando notificaciones'))
                    : _NotificationContent(notifications: notifications),
              ),
            ),
          ),
        ),
      );
}

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key, required this.unreadCount, required this.onPressed});

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final countLabel = unreadCount > 9 ? '9+' : '$unreadCount';
    final label = unreadCount == 0 ? 'Notificaciones' : 'Notificaciones, $unreadCount sin leer';
    return Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
      IconButton(tooltip: label, onPressed: onPressed, icon: const Icon(Icons.notifications_none_rounded)),
      if (unreadCount > 0)
        Positioned(
          top: 4,
          right: 2,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.error,
                  borderRadius: BorderRadius.circular(AppRadii.s),
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                ),
                child: Text(countLabel, style: context.text.labelSmall?.copyWith(color: context.colors.onError)),
              ),
            ),
          ),
        ),
    ]);
  }
}

class _NotificationContent extends StatelessWidget {
  const _NotificationContent({required this.notifications});

  final NotificationController notifications;

  Future<void> _remove(BuildContext context, NotificationItem item) async {
    final removed = await notifications.remove(item.id);
    if (removed == null || !context.mounted) return;
    showAppSnackBar(
      context,
      'Eliminamos la notificación.',
      action: SnackBarAction(label: 'Deshacer', onPressed: () => notifications.restore(removed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storageNotice = notifications.storageAvailable
        ? null
        : 'No pudimos guardar tus notificaciones en este dispositivo. Las verás mientras la app siga abierta.';
    if (notifications.items.isEmpty) return _EmptyNotifications(notice: storageNotice);
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.s, AppSpacing.xl, AppSpacing.xxl),
      children: [
        if (storageNotice != null) _StorageNotice(message: storageNotice),
        Row(children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                notifications.unreadCount == 0 ? 'Todo al día' : '${notifications.unreadCount} sin leer',
                style: context.text.headlineSmall,
              ),
            ),
          ),
          if (notifications.unreadCount > 0)
            TextButton(onPressed: notifications.markAllAsRead, child: const Text('Marcar todas como leídas')),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Aquí verás actualizaciones sobre los análisis que realizas en FARMA GO.',
          style: context.text.bodyLarge,
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
        const SizedBox(height: AppSpacing.s),
        for (final item in notifications.items)
          Padding(
            key: ValueKey(item.id),
            padding: const EdgeInsets.only(bottom: AppSpacing.m),
            child: _NotificationCard(
              notification: item,
              onOpen: () => notifications.markAsRead(item.id),
              onDelete: () => _remove(context, item),
            ),
          ),
      ],
    );
  }
}

class _StorageNotice extends StatelessWidget {
  const _StorageNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.l),
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: context.status.warningContainer,
            borderRadius: BorderRadius.circular(AppRadii.s),
          ),
          child: Text(message, style: context.text.bodySmall?.copyWith(color: context.status.onWarningContainer)),
        ),
      );
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({this.notice});

  final String? notice;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (notice != null) _StorageNotice(message: notice!),
              ExcludeSemantics(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(color: context.status.brandSurface, shape: BoxShape.circle),
                  child: Icon(Icons.notifications_none_rounded, size: 36, color: context.colors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.l + 4),
              Text('No tienes notificaciones', style: context.text.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Cuando termine un análisis de fórmula, verás la actualización aquí.',
                style: context.text.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ),
      );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onOpen, required this.onDelete});

  final NotificationItem notification;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final radius = BorderRadius.circular(AppRadii.l);
    return Material(
      color: unread ? context.status.brandSurface : context.colors.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.m, AppSpacing.s, AppSpacing.m),
          decoration: BoxDecoration(
            border: Border.all(color: unread ? context.colors.outline : context.status.decorative),
            borderRadius: radius,
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _NotificationKindIcon(kind: notification.kind),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: MergeSemantics(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    unread ? '${notification.title} · Nueva' : notification.title,
                    style: context.text.titleMedium?.copyWith(fontWeight: unread ? FontWeight.w800 : FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(notification.message, style: context.text.bodyLarge),
                  const SizedBox(height: AppSpacing.s),
                  Text(_relativeTime(notification.createdAt), style: context.text.labelMedium),
                ]),
              ),
            ),
            IconButton(
              tooltip: 'Eliminar notificación',
              onPressed: onDelete,
              icon: const Icon(Icons.close_rounded, size: 20),
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
  const _NotificationKindIcon({required this.kind});

  final NotificationKind kind;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(AppRadii.s)),
          child: Icon(
            kind == NotificationKind.analysis ? Icons.document_scanner_outlined : Icons.info_outline,
            color: context.colors.primary,
          ),
        ),
      );
}
