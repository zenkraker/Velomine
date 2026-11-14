import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/page_actions.dart';
import '../../core/tokens.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_heading.dart';
import 'notifications_text.dart';
import 'notifications_view_model.dart';

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

    // Grouped by what they are about, so a wear warning is not lost between two ride results.
    final groups = <String, List<NotificationResponse>>{};
    for (final n in s.items) {
      groups.putIfAbsent(_groupOf(n.type), () => []).add(n);
    }
    String groupTitle(String group) => switch (group) {
      'rides' => l10n.notificationGroupRides,
      'club' => l10n.notificationGroupClub,
      'bikes' => l10n.notificationGroupBikes,
      _ => l10n.notificationGroupAccount,
    };

    final markAll = s.unread > 0
        ? TextButton(
            key: const Key('notifications-read-all'),
            onPressed: s.markAll.running
                ? null
                : ref.read(notificationsViewModelProvider.notifier).markAllRead,
            child: Text(l10n.markAllRead),
          )
        : null;
    // The action sits in the header with the title; a phone has no header, so it goes in the title
    // bar — and leaves it once everything is read.
    if (MediaQuery.sizeOf(context).width < AppBreakpoint.compactWidth) {
      publishPhoneActions(context, ref, [?markAll]);
    }

    return PageScaffold(
      eyebrow: l10n.notificationsEyebrow,
      title: l10n.notifications,
      subtitle: l10n.notificationsSubtitle,
      actions: markAll,
      children: [
        if (s.load.failure case final failure?)
          ErrorState(
            message: failureText(l10n, failure),
            actionKey: const Key('notifications-error'),
            onRetry: s.load.running
                ? null
                : ref.read(notificationsViewModelProvider.notifier).refresh,
          ),
        if (s.items.isEmpty && !s.load.running && s.load.failure == null)
          EmptyState(
            key: const Key('no-notifications'),
            message: l10n.noNotifications,
            icon: Icons.notifications_none,
          ),
        for (final MapEntry(key: group, value: items) in groups.entries) ...[
          SectionHeading(title: groupTitle(group)),
          for (final n in items)
            _NotificationTile(
              notification: n,
              onTap: () => _open(context, ref, n),
            ),
        ],
      ],
    );
  }

  /// The section a notification belongs to.
  static String _groupOf(String type) => switch (type) {
    'ride_ready' ||
    'ride_failed' ||
    'ride_duplicate' ||
    'ride_import' => 'rides',
    'club_join_request' ||
    'club_join_approved' ||
    'club_join_declined' => 'club',
    'part_soon' || 'part_worn' => 'bikes',
    _ => 'account',
  };
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
