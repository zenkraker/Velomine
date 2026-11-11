import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/user_message_text.dart';
import 'notifications_text.dart';
import 'notifications_view_model.dart';
import '../../core/tokens.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key, required this.onOpen});

  final void Function(String location) onOpen;

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    NotificationResponse n,
  ) async {
    await ref.read(notificationsViewModelProvider.notifier).markRead(n);
    final target = notificationTarget(n);
    if (target != null && context.mounted) onOpen(target);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(notificationsViewModelProvider);
    final l10n = context.l10n;

    listenUserMessages(
      ref,
      context,
      notificationsViewModelProvider.select((s) => s.messages),
      ref.read(notificationsViewModelProvider.notifier).messageShown,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                if (s.unread > 0)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const Key('notifications-read-all'),
                      onPressed: s.markAll.running
                          ? null
                          : () => ref
                                .read(notificationsViewModelProvider.notifier)
                                .markAllRead(),
                      child: Text(l10n.markAllRead),
                    ),
                  ),
                if (s.load.failure case final failure?)
                  Text(
                    failureText(l10n, failure),
                    key: const Key('notifications-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (s.items.isEmpty &&
                    !s.load.running &&
                    s.load.failure == null)
                  Text(
                    l10n.noNotifications,
                    key: const Key('no-notifications'),
                  ),
                for (final n in s.items)
                  _NotificationTile(
                    notification: n,
                    onTap: () => _open(context, ref, n),
                  ),
              ],
            ),
          ),
        ),
      ],
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
    'club_join_request' => Icons.person_add_alt,
    'club_join_approved' => Icons.check_circle_outline,
    'club_join_declined' => Icons.info_outline,
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
                label: context.l10n.unread,
                child: Icon(Icons.circle, size: 10, color: scheme.primary),
              ),
      ),
    );
  }
}
