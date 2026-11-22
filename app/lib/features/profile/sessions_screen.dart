import 'dart:async' show scheduleMicrotask;

import '../../core/confirm.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/page_menu.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/user_message_text.dart';
import 'sessions_view_model.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(sessionsViewModelProvider);
    final notifier = ref.read(sessionsViewModelProvider.notifier);

    ref.listen(
      sessionsViewModelProvider,
      (_, next) =>
          showUserMessage(context, next.message, notifier.messageShown),
    );

    final sessions = state.load.value;
    return PageScaffold(
      title: l10n.sessionsTitle,
      parent: l10n.profileTitle,
      subtitle: l10n.sessionsIntro,
      maxWidth: AppLayout.contentNarrow,
      // Signing the other devices out is rare: in the menu, behind a confirmation.
      menu: PageMenu(
        buttonKey: const Key('sessions-actions'),
        entries: [
          PageMenuEntry(
            key: const Key('logout-others'),
            label: l10n.sessionLogoutOthers,
            icon: Icons.devices_other,
            destructive: true,
            onSelected: state.logoutOthers.running
                ? () {}
                : () => scheduleMicrotask(() async {
                    if (!context.mounted) return;
                    final sure = await confirmDestructive(
                      context,
                      title: l10n.sessionLogoutOthers,
                      body: l10n.sessionLogoutOthersBody,
                      action: l10n.sessionLogoutOthers,
                      key: const Key('confirm-logout-others'),
                    );
                    if (sure) notifier.logoutOthers();
                  }),
          ),
        ],
      ),
      children: [
        if (state.load.running && sessions == null)
          const LoadingState()
        else if (state.load.failure case final failure?)
          ErrorState(
            message: failureText(l10n, failure),
            onRetry: notifier.load,
          )
        else if (sessions != null && sessions.isEmpty)
          EmptyState(
            key: const Key('sessions-empty'),
            message: l10n.sessionsEmpty,
            icon: Icons.devices_other,
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final session in sessions ?? const [])
                  ListTile(
                    key: Key('session-${session.id}'),
                    title: Text(session.label),
                    subtitle: Text(
                      '${l10n.sessionLastUsed}: ${dateTime(session.lastUsedAt)}',
                    ),
                    trailing: session.current
                        ? AppBadge(
                            l10n.sessionThisDevice,
                            tone: AppBadgeTone.good,
                          )
                        : TextButton(
                            key: Key('revoke-${session.id}'),
                            onPressed: state.revoke.running
                                ? null
                                : () => notifier.revoke(session.id),
                            child: Text(l10n.sessionRevoke),
                          ),
                  ),
              ],
            ),
          ),
        if (state.revoke.completed)
          Text(l10n.sessionRevoked, key: const Key('session-revoked')),
        if (state.logoutOthers.completed)
          Text(l10n.sessionOthersRevoked, key: const Key('others-revoked')),
      ],
    );
  }
}
