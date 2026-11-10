import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/user_message_text.dart';
import 'sessions_view_model.dart';

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(sessionsViewModelProvider);
    final notifier = ref.read(sessionsViewModelProvider.notifier);

    ref.listen(sessionsViewModelProvider, (_, next) {
      final message = next.message;
      if (message == null) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userMessageText(l10n, message))));
      notifier.messageShown(message.id);
    });

    final sessions = state.load.value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sessionsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.sessionsIntro),
          const SizedBox(height: 16),
          if (state.load.running && sessions == null)
            const Center(child: CircularProgressIndicator())
          else if (state.load.failure case final failure?)
            Row(
              children: [
                Expanded(child: Text(failureText(l10n, failure))),
                TextButton(onPressed: notifier.load, child: Text(l10n.tryAgain)),
              ],
            )
          else if (sessions != null && sessions.isEmpty)
            Text(l10n.sessionsEmpty)
          else
            for (final session in sessions ?? const [])
              ListTile(
                key: Key('session-${session.id}'),
                contentPadding: EdgeInsets.zero,
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
          if (state.revoke.completed) Text(l10n.sessionRevoked),
          if (state.logoutOthers.completed) Text(l10n.sessionOthersRevoked),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const Key('logout-others'),
            onPressed: state.logoutOthers.running ? null : notifier.logoutOthers,
            icon: const Icon(Icons.devices_other),
            label: Text(l10n.sessionLogoutOthers),
          ),
        ],
      ),
    );
  }
}
