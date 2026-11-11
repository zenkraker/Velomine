import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/section_card.dart';
import 'club_rides_view_model.dart';

/// The member's private calendar address: shown once, replaceable, and stopped when they leave the club.
class CalendarFeedScreen extends ConsumerWidget {
  const CalendarFeedScreen({super.key});

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    required Key key,
  }) async {
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: key,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return sure == true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(calendarFeedViewModelProvider);
    final notifier = ref.read(calendarFeedViewModelProvider.notifier);

    listenUserMessages(
      ref,
      context,
      calendarFeedViewModelProvider.select((s) => s.messages),
      notifier.messageShown,
    );

    final busy = s.action.running;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                SectionCard(
                  title: l10n.calendarTitle,
                  description: l10n.calendarHelp,
                  children: [
                    if (s.load.failure case final failure?)
                      Text(
                        failureText(l10n, failure),
                        key: const Key('calendar-feed-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      )
                    else if (s.address != null) ...[
                      SelectableText(
                        s.address!,
                        key: const Key('calendar-address'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        l10n.calendarShownOnce,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Row(
                        children: [
                          FilledButton.tonalIcon(
                            key: const Key('copy-calendar-address'),
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: s.address!),
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.calendarAddressCopied),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: Text(l10n.calendarCopy),
                          ),
                        ],
                      ),
                    ] else
                      Text(
                        s.active
                            ? [
                                l10n.calendarActive,
                                if (s.createdAt != null) dateTime(s.createdAt),
                              ].join(' · ')
                            : l10n.calendarInactive,
                        key: const Key('calendar-status'),
                      ),
                  ],
                ),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (!s.active || s.address == null)
                      FilledButton.icon(
                        key: const Key('create-calendar-address'),
                        onPressed: busy ? null : notifier.create,
                        icon: const Icon(Icons.add_link),
                        label: Text(l10n.calendarCreate),
                      ),
                    if (s.active)
                      OutlinedButton.icon(
                        key: const Key('replace-calendar-address'),
                        onPressed: busy
                            ? null
                            : () async {
                                if (await _confirm(
                                  context,
                                  title: l10n.calendarReplaceConfirmTitle,
                                  body: l10n.calendarReplaceConfirmBody,
                                  action: l10n.calendarReplace,
                                  key: const Key('confirm-replace-calendar'),
                                )) {
                                  await notifier.create();
                                }
                              },
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.calendarReplace),
                      ),
                    if (s.active)
                      TextButton.icon(
                        key: const Key('stop-calendar-address'),
                        onPressed: busy
                            ? null
                            : () async {
                                if (await _confirm(
                                  context,
                                  title: l10n.calendarDeleteConfirmTitle,
                                  body: l10n.calendarDeleteConfirmBody,
                                  action: l10n.calendarDelete,
                                  key: const Key('confirm-stop-calendar'),
                                )) {
                                  await notifier.stop();
                                }
                              },
                        icon: const Icon(Icons.link_off),
                        label: Text(l10n.calendarDelete),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
