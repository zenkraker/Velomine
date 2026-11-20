import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/confirm.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/toolbar_row.dart';
import 'club_rides_view_model.dart';

/// The member's private calendar address: shown once, replaceable, and stopped when they leave the club.
class CalendarFeedScreen extends ConsumerWidget {
  const CalendarFeedScreen({super.key});

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
    return PageScaffold(
      title: l10n.calendarTitle,
      subtitle: l10n.calendarHelp,
      maxWidth: AppLayout.contentNarrow,
      menu: s.active
          ? PageMenu(
              buttonKey: const Key('calendar-actions'),
              entries: [
                PageMenuEntry(
                  key: const Key('stop-calendar-address'),
                  icon: Icons.link_off,
                  label: l10n.calendarDelete,
                  destructive: true,
                  onSelected: busy
                      ? () {}
                      : () => scheduleMicrotask(() async {
                          if (!context.mounted) return;
                          if (await confirmDestructive(
                            context,
                            title: l10n.calendarDeleteConfirmTitle,
                            body: l10n.calendarDeleteConfirmBody,
                            action: l10n.calendarDelete,
                            key: const Key('confirm-stop-calendar'),
                          )) {
                            await notifier.stop();
                          }
                        }),
                ),
              ],
            )
          : null,
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: [
                if (s.load.failure case final failure?)
                  ErrorState(
                    message: failureText(l10n, failure),
                    actionKey: const Key('calendar-feed-error'),
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
                            SnackBar(content: Text(l10n.calendarAddressCopied)),
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
          ),
        ),
        ToolbarRow(
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
                        if (await confirmDestructive(
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
          ],
        ),
      ],
    );
  }
}
