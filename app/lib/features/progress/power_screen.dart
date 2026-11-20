import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/ftp_suggestion_card.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/page_scaffold.dart';
import '../accounts/ftp_source_text.dart';
import '../../l10n/generated/app_localizations.dart';
import 'ftp_history_sheet.dart';
import 'ftp_reminder_card.dart';
import 'power_summary.dart';
import 'progress_data.dart';
import 'progress_filter_sheet.dart';
import 'progress_tabs.dart';
import 'progress_view_models.dart';

/// Where the current FTP came from, from the newest row of the member's own history. Null when the
/// history says nothing yet (no FTP, or the call failed): a missing note beats a wrong one.
String? _ftpNote(AppLocalizations l10n, List<FtpHistoryEntry> history) {
  final newest = history.firstOrNull;
  if (newest == null) return null;
  return ftpSourceText(l10n, newest.source_, newest.setAt);
}

/// Progress → Power answers "What is my power profile?": FTP, critical power and the VO2max estimate
/// above the power curve and the best efforts.
class PowerScreen extends ConsumerWidget {
  const PowerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filters = ref.watch(progressFiltersViewModelProvider);
    final power = ref.watch(powerCurveViewModelProvider);
    final reminder = ref.watch(ftpReminderViewModelProvider);
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoint.compactWidth;

    listenUserMessages(
      ref,
      context,
      powerCurveViewModelProvider.select((s) => s.messages),
      ref.read(powerCurveViewModelProvider.notifier).messageShown,
    );
    listenUserMessages(
      ref,
      context,
      ftpReminderViewModelProvider.select((s) => s.messages),
      ref.read(ftpReminderViewModelProvider.notifier).messageShown,
    );

    final failure = power.load.failure;
    return PageScaffold(
      title: l10n.metricPower,
      parent: wide ? l10n.navProgress : null,
      menu: PageMenu(
        buttonKey: const Key('power-actions'),
        badge: filters.discipline != null,
        entries: [
          PageMenuEntry(
            key: const Key('power-filter'),
            icon: Icons.filter_list,
            label: l10n.progressFilterTitle,
            onSelected: () => showProgressFilterSheet(context),
          ),
          PageMenuEntry(
            key: const Key('power-ftp-history'),
            icon: Icons.history,
            label: l10n.ftpHistory,
            onSelected: () {
              final data = ref.read(progressDataProvider);
              showFtpHistorySheet(context, data.ftpHistory, data.ftpRideDates);
            },
          ),
        ],
      ),
      children: [
        if (!wide) ProgressTabs(location: '/progress/power'),
        if (failure != null)
          ErrorState(
            message: failureText(l10n, failure),
            onRetry: ref.read(powerCurveViewModelProvider.notifier).load,
            actionKey: const Key('power-error'),
          ),
        // A ride that shows a higher FTP is the strongest answer there is, so it leads; while it is
        // open the reminder stays quiet, because it would only ask about the number it replaces.
        if (reminder.suggestion case final suggestion?)
          FtpSuggestionCard(
            watts: suggestion.watts,
            method: suggestion.method,
            effortWatts: suggestion.effortWatts,
            suggestionId: suggestion.id,
            busy: reminder.action.running,
            onAccept: ref
                .read(ftpReminderViewModelProvider.notifier)
                .useSuggestion,
            onDismiss: ref
                .read(ftpReminderViewModelProvider.notifier)
                .dismissSuggestion,
          ),
        if (reminder.check?.reason != null && reminder.suggestion == null)
          FtpReminderCard(
            check: reminder.check!,
            busy: reminder.action.running,
            onUseEstimate: (watts) => ref
                .read(ftpReminderViewModelProvider.notifier)
                .useEstimate(watts),
            onSnooze: () =>
                ref.read(ftpReminderViewModelProvider.notifier).snooze(),
          ),
        if (power.load.value case final curve?)
          PowerSummary(
            curve: curve,
            days: filters.powerDays,
            onDays: (days) async => ref
                .read(progressFiltersViewModelProvider.notifier)
                .setPowerDays(days),
            onUseFtp: (watts) =>
                ref.read(powerCurveViewModelProvider.notifier).useFtp(watts),
            ftpNote: _ftpNote(l10n, power.history),
            ftpRideId: power.history.firstOrNull?.rideId,
            onOpenRide: (id) => context.push('/rides/$id'),
          ),
      ],
    );
  }
}
