import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/user_message_text.dart';
import 'sessions_view_model.dart';
import '../../core/tokens.dart';
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
      eyebrow: l10n.profileTitle,
      title: l10n.sessionsTitle,
      subtitle: l10n.sessionsIntro,
      maxWidth: AppLayout.contentNarrow,
      children: [
        if (state.load.running && sessions == null)
          const Center(child: CircularProgressIndicator())
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
          Card(
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
                        ? Text(l10n.sessionThisDevice)
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
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('logout-others'),
            onPressed: state.logoutOthers.running
                ? null
                : notifier.logoutOthers,
            icon: const Icon(Icons.devices_other),
            label: Text(l10n.sessionLogoutOthers),
          ),
        ),
      ],
    );
  }
}
