import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.controller,
    required this.onOpen,
  });

  final NotificationsController controller;
  final void Function(String location) onOpen;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.refresh();
  }

  Future<void> _open(NotificationResponse n) async {
    await widget.controller.markRead(n);
    final target = notificationTarget(n);
    if (target != null && mounted) widget.onOpen(target);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Notifications',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (c.unread > 0)
                        TextButton(
                          key: const Key('notifications-read-all'),
                          onPressed: c.markAllRead,
                          child: const Text('Mark all read'),
                        ),
                    ],
                  ),
                  if (c.error != null)
                    Text(
                      failureText(context.l10n, c.error!),
                      key: const Key('notifications-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (c.items.isEmpty && !c.loading && c.error == null)
                    const Text(
                      'Nothing yet. You will hear here when a ride has been read, or a part on your bike is nearly worn.',
                      key: Key('no-notifications'),
                    ),
                  for (final n in c.items)
                    _NotificationTile(notification: n, onTap: () => _open(n)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationResponse notification;
  final VoidCallback onTap;

  static IconData _icon(String type) => switch (type) {
    'ride_ready' => Icons.check_circle_outline,
    'ride_failed' => Icons.error_outline,
    'ride_duplicate' => Icons.content_copy,
    'signup_waiting' => Icons.person_add_alt,
    'part_soon' || 'part_worn' => Icons.build_outlined,
    _ => Icons.notifications_none,
  };

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final scheme = Theme.of(context).colorScheme;
    final warning = n.type == 'ride_failed' || n.type == 'part_worn';
    return Card(
      key: Key('notification-${n.id}'),
      color: n.isRead ? null : scheme.primaryContainer.withValues(alpha: 0.5),
      child: ListTile(
        onTap: onTap,
        leading: Icon(_icon(n.type), color: warning ? scheme.error : null),
        title: Text(
          notificationText(context.l10n, n),
          style: n.isRead ? null : const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(dateTime(n.createdAt)),
        trailing: n.isRead
            ? null
            : Semantics(
                label: 'Unread',
                child: Icon(Icons.circle, size: 10, color: scheme.primary),
              ),
      ),
    );
  }
}
