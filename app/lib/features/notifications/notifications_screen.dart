import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
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

    // Unread first as its own group, then grouped by what they are about, so nothing waiting to be
    // read sits below something already read.
    List<NotificationResponse> newestFirst(
      Iterable<NotificationResponse> items,
    ) => [...items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final unread = newestFirst(s.items.where((n) => !n.isRead));
    final groups = <String, List<NotificationResponse>>{};
    for (final n in newestFirst(s.items.where((n) => n.isRead))) {
      groups.putIfAbsent(_groupOf(n.type), () => []).add(n);
    }
    String groupTitle(String group) => switch (group) {
      'rides' => l10n.notificationGroupRides,
      'club' => l10n.notificationGroupClub,
      'bikes' => l10n.notificationGroupBikes,
      'unread' => l10n.notificationGroupUnread,
      _ => l10n.notificationGroupAccount,
    };
    final sections = <String, List<NotificationResponse>>{
      if (unread.isNotEmpty) 'unread': unread,
      ...groups,
    };

    // The main action is a filled pill with its words at every width: an icon alone would not say what
    // it does. It stays in the header with nothing to do rather than vanishing, so the page's one action
    // keeps its place.
    final markAll = FilledButton.icon(
      key: const Key('notifications-read-all'),
      onPressed: s.unread == 0 || s.markAll.running
          ? null
          : ref.read(notificationsViewModelProvider.notifier).markAllRead,
      icon: const Icon(Icons.done_all),
      label: Text(l10n.markAllRead),
    );
    return PageScaffold(
      title: l10n.notifications,
      subtitle: l10n.notificationsSubtitle,
      primaryAction: markAll,
      // The inbox is a list of short rows: it reads at the narrow measure, as the mock-up draws it.
      maxWidth: AppLayout.contentNarrow,
      children: [
        // The first load is a loading state, not a page that says there is nothing.
        if (s.items.isEmpty && s.load.failure == null && !s.load.completed)
          const LoadingState(),
        if (s.load.failure case final failure?)
          ErrorState(
            message: failureText(l10n, failure),
            actionKey: const Key('notifications-error'),
            onRetry: s.load.running
                ? null
                : ref.read(notificationsViewModelProvider.notifier).refresh,
          ),
        if (s.items.isEmpty && s.load.completed)
          EmptyState(
            key: const Key('no-notifications'),
            message: l10n.noNotifications,
            icon: Icons.notifications_none,
          ),
        for (final MapEntry(key: group, value: items) in sections.entries)
          _NotificationGroup(
            group: group,
            title: groupTitle(group),
            items: items,
            onOpen: (n) => _open(context, ref, n),
          ),
      ],
    );
  }

  /// The section a notification belongs to.
  static String _groupOf(String type) => switch (type) {
    'ride_ready' ||
    'ride_failed' ||
    'ride_duplicate' ||
    'ride_import' ||
    'power_record' ||
    'ftp_suggested' ||
    'heart_rate_measured' ||
    'heart_rate_suggested' ||
    'training_session_question' ||
    'training_today' ||
    'training_easy' ||
    'training_moved' ||
    'training_skipped' => 'rides',
    'club_join_request' ||
    'club_join_approved' ||
    'club_join_declined' => 'club',
    'part_soon' || 'part_worn' => 'bikes',
    _ => 'account',
  };
}

class _NotificationGroup extends StatelessWidget {
  const _NotificationGroup({
    required this.group,
    required this.title,
    required this.items,
    required this.onOpen,
  });

  final String group;
  final String title;
  final List<NotificationResponse> items;
  final void Function(NotificationResponse) onOpen;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: Key('notification-group-$group'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: SectionHeading(title: title),
          ),
          for (final (i, n) in items.indexed) ...[
            if (i > 0) const Divider(height: 1),
            _NotificationTile(notification: n, onTap: () => onOpen(n)),
          ],
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
    'power_record' => Icons.emoji_events_outlined,
    'ftp_suggested' => Icons.speed_outlined,
    'heart_rate_measured' || 'heart_rate_suggested' => Icons.favorite_border,
    'training_session_question' ||
    'training_today' => Icons.event_available_outlined,
    'training_easy' => Icons.spa_outlined,
    'training_moved' => Icons.event_outlined,
    'training_skipped' => Icons.skip_next_outlined,
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
    return ListTile(
      key: Key('notification-${n.id}'),
      onTap: onTap,
      leading: Icon(_icon(n.type), color: warning ? scheme.error : null),
      title: Text(
        notificationText(context.l10n, n),
        style: n.isRead
            ? null
            : Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(dateTime(n.createdAt)),
      // An unread row says so in words, beside its date, as the mock-up draws it.
      trailing: n.isRead ? null : AppBadge(context.l10n.unread),
    );
  }
}
