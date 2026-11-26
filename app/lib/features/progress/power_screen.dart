import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/ftp_suggestion_card.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/page_scaffold.dart';
import 'ftp_history_sheet.dart';
import 'power_summary.dart';
import 'progress_data.dart';
import 'progress_filter_sheet.dart';
import 'progress_screen.dart';
import 'progress_tabs.dart';
import 'ftp_reminder_card.dart';
import 'progress_view_models.dart';
import 'rider_card.dart';

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
    final riderCard = ref.watch(riderCardViewModelProvider);
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
      parent: l10n.navProgress,
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
        // First, full width: the rider's own numbers, the ones this page does not otherwise show.
        if (riderCard.load.failure case final cardFailure?)
          ErrorState(
            key: const Key('rider-card-error'),
            message: failureText(l10n, cardFailure),
            onRetry: ref.read(riderCardViewModelProvider.notifier).load,
            actionKey: const Key('rider-card-retry'),
          )
        else if (riderCard.load.value case final card?)
          RiderCard(card: card, onMore: () => showRiderCard(context, card)),
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
            ftpNote: ftpSourceNote(
              l10n,
              power.history,
              rideDate: power.ftpRideDate,
            ),
            ftpRideId: power.history.firstOrNull?.rideId,
            onOpenRide: (id) => context.push('/rides/$id'),
            onAllDurations: switch (riderCard.load.value) {
              final card? => () => showRiderCard(context, card),
              null => null,
            },
          ),
      ],
    );
  }
}
