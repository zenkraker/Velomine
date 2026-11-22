import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../accounts/ftp_source_text.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/placeholder_block.dart';
import '../../core/rider_mode.dart';
import '../../core/tokens.dart';
import '../../core/units.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/card_grid.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/ftp_suggestion_card.dart';
import '../../core/widgets/heart_rate_note_card.dart';
import '../../core/widgets/more_details.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/segmented_control.dart';
import '../../core/widgets/stat_card.dart';
import '../rides/ride_type_chips.dart';
import 'efficiency_card.dart';
import 'events.dart';
import 'ftp_reminder_card.dart';
import 'intensity_card.dart';
import 'power_summary.dart';
import 'rider_card.dart';
import 'progress_filter_sheet.dart';
import 'progress_tabs.dart';
import 'progress_view_models.dart';
import 'totals_chart.dart';
import 'training_summary.dart';

/// Where the FTP the power curve was read with came from, for its source note. [rideDate] is the day
/// of the ride a test FTP came from, which the history row's own `setAt` is not.
String? ftpSourceNote(
  AppLocalizations l10n,
  List<FtpHistoryEntry> history, {
  DateTime? rideDate,
}) {
  final newest = history.firstOrNull;
  if (newest == null) return null;
  return ftpSourceText(
    l10n,
    newest.source_,
    newest.setAt,
    rideDate: rideDate,
  );
}

/// Progress: one overview that answers "how am I today and this week?" and opens the page that answers
/// the next question. The deep charts live on the four sub-pages; a training rider keeps the analysis
/// here, behind one fold for a simple mode.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final layout = ref.watch(riderLayoutProvider);
    final filters = ref.watch(progressFiltersViewModelProvider);
    final totals = ref.watch(totalsViewModelProvider);
    final training = ref.watch(trainingViewModelProvider);
    final readiness = ref.watch(readinessViewModelProvider);
    final events = ref.watch(eventsViewModelProvider);
    final units = ref.watch(unitsChoiceViewModelProvider);
    final riderCard = ref.watch(riderCardViewModelProvider);
    final power = ref.watch(powerCurveViewModelProvider);
    final reminder = ref.watch(ftpReminderViewModelProvider);
    final heartRate = ref.watch(heartRateSuggestionViewModelProvider);
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoint.compactWidth;

    // A source counts only when its card is on the page: a folded part says nothing until it is opened,
    // so a failure nobody can see is not thrown at the member.
    final failures = [
      totals.load.failure,
      if (!layout.foldAdvanced) ...<Failure?>[
        riderCard.load.failure,
        training.load.failure,
        power.load.failure,
        readiness.load.failure,
      ],
    ].whereType<Failure>();
    // A source the member cannot see yet says so only once the fold is open, and its retry asks that one
    // source again rather than reloading the whole page.
    Widget? foldedError(String source, Failure? failure, VoidCallback reload) =>
        failure == null
        ? null
        : ErrorState(
            key: Key('progress-error-$source'),
            message: failureText(l10n, failure),
            actionKey: Key('progress-retry-$source'),
            onRetry: reload,
          );
    final foldedErrors = [
      foldedError(
        'rider-card',
        riderCard.load.failure,
        () => ref.read(riderCardViewModelProvider.notifier).load(),
      ),
      foldedError(
        'training',
        training.load.failure,
        () => ref.read(trainingViewModelProvider.notifier).load(),
      ),
      foldedError(
        'power',
        power.load.failure,
        () => ref.read(powerCurveViewModelProvider.notifier).load(),
      ),
      foldedError(
        'readiness',
        readiness.load.failure,
        () => ref.read(readinessViewModelProvider.notifier).load(),
      ),
    ].nonNulls;

    // The period, in the gender the language needs: "Questa settimana", "Questo mese", "Quest'anno".
    final thisPeriod = switch (filters.period) {
      'week' => l10n.thisWeek,
      'month' => l10n.thisMonth,
      _ => l10n.thisYear,
    };
    final weeks = totals.load.value?.totals ?? const <PeriodTotals>[];
    final latestWeek = weeks.isEmpty ? null : weeks.last;
    final earlier = weeks.length > 1
        ? weeks.sublist(0, weeks.length - 1)
        : const <PeriodTotals>[];
    final averageM = earlier.isEmpty
        ? null
        : earlier.map((week) => week.distanceM).reduce((a, b) => a + b) /
              earlier.length;

    final readinessCard = switch (readiness.load.value) {
      final r? => StatCard(
        key: const Key('metric-readiness'),
        title: l10n.readiness,
        value: r.score == null ? '–' : '${r.score}',
        state: switch (r.band) {
          'hard' => l10n.readinessHard,
          'easy' => l10n.readinessEasy,
          'rest' => l10n.readinessRest,
          _ => l10n.readinessNormal,
        },
        stateCare: r.band == 'easy' || r.band == 'rest',
        sentence: switch (r.band) {
          'hard' => l10n.readinessAdviceHard,
          'easy' => l10n.readinessAdviceEasy,
          'rest' => l10n.readinessAdviceRest,
          _ => l10n.readinessAdviceNormal,
        },
        link: l10n.wellbeing,
        onLink: () => context.go('/progress/wellbeing'),
      ),
      null => null,
    };
    final formCard = switch (training.load.value) {
      final t? when t.days.isNotEmpty => StatCard(
        key: const Key('metric-form'),
        title: l10n.form,
        value: t.days.last.form.round().toString(),
        sentence: l10n.formFitnessFatigue(
          t.days.last.fitness.round(),
          t.days.last.fatigue.round(),
        ),
        link: l10n.fitness,
        onLink: () => context.go('/progress/fitness'),
      ),
      _ => null,
    };
    final periodCard = switch (latestWeek) {
      final week? => StatCard(
        key: const Key('metric-period'),
        title: thisPeriod,
        value: distanceParts(units, week.distanceM).value,
        unit: distanceParts(units, week.distanceM).unit,
        sentence: averageM == null
            ? l10n.periodTotals(
                week.rides,
                duration(week.movingS),
                elevation(units, week.elevationGainM),
              )
            : l10n.weekAgainstAverage(
                week.distanceM > averageM
                    ? 'above'
                    : week.distanceM < averageM
                    ? 'below'
                    : 'other',
                km(units, averageM),
              ),
        link: l10n.navTotals,
        onLink: () => context.go('/progress/totals'),
      ),
      null => null,
    };
    final nextCard = _NextEventCard(next: events.next);
    final metrics = <Widget>[?readinessCard, ?formCard, ?periodCard, nextCard];

    final periods = SegmentedControl<String>(
      buttonKey: const Key('progress-period'),
      segments: [
        ButtonSegment(value: 'week', label: Text(l10n.periodWeeks)),
        ButtonSegment(value: 'month', label: Text(l10n.periodMonths)),
        ButtonSegment(value: 'year', label: Text(l10n.periodYears)),
      ],
      selected: filters.period,
      onChanged: (period) =>
          ref.read(progressFiltersViewModelProvider.notifier).setPeriod(period),
    );

    final menu = PageMenu(
      buttonKey: const Key('progress-actions'),
      badge: filters.discipline != null,
      entries: [
        PageMenuEntry(
          key: const Key('progress-filter'),
          icon: Icons.filter_list,
          label: l10n.progressFilterTitle,
          onSelected: () => showProgressFilterSheet(context),
        ),
      ],
    );

    // What a training rider wants on the overview, in the order it answers questions: the rider's own
    // numbers, then the two suggestions, then the charts behind them. A simple mode folds them all behind
    // one button rather than taking the overview away.
    final analysis = <(Widget, bool)>[
      if (riderCard.load.value case final card?)
        (
          RiderCard(card: card, onMore: () => showRiderCard(context, card)),
          true,
        ),
      if (reminder.suggestion case final suggestion?)
        (
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
          true,
        ),
      for (final suggestion in heartRate.suggestions)
        (
          HeartRateNoteCard(
            kind: suggestion.kind,
            bpm: suggestion.bpm,
            currentBpm: suggestion.kind == 'max'
                ? heartRate.profile?.maxHeartRate
                : heartRate.profile?.thresholdHeartRate.orElse(null),
            suggestionId: suggestion.id,
            busy: heartRate.action.running,
            onAccept: ref
                .read(heartRateSuggestionViewModelProvider.notifier)
                .accept,
            onDismiss: ref
                .read(heartRateSuggestionViewModelProvider.notifier)
                .dismiss,
          ),
          true,
        ),
      if (reminder.check?.reason != null && reminder.suggestion == null)
        (
          FtpReminderCard(
            check: reminder.check!,
            busy: reminder.action.running,
            onUseEstimate: (watts) => ref
                .read(ftpReminderViewModelProvider.notifier)
                .useEstimate(watts),
            onSnooze: () =>
                ref.read(ftpReminderViewModelProvider.notifier).snooze(),
          ),
          true,
        ),
      if (training.load.value case final trainingData?)
        (
          TrainingSummary(
            training: trainingData,
            days: filters.trainingDays,
            onDays: (days) async => ref
                .read(progressFiltersViewModelProvider.notifier)
                .setTrainingDays(days),
          ),
          true,
        ),
      if (training.load.value case final trainingData?)
        if (trainingData.intensity case final intensity?)
          (
            IntensityCard(
              intensity: intensity,
              weeks: trainingData.intensityWeeks,
            ),
            // Riding with goals opens with this split; just riding folds it with the rest.
            !layout.showIntensity,
          ),
      if (training.load.value case final trainingData?)
        (EfficiencyCard(weeks: trainingData.efficiency), true),
      if (power.load.value case final curve?)
        (
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
          ),
          true,
        ),
    ];
    return PageScaffold(
      title: l10n.navProgress,
      subtitle: l10n.progressSubtitle,
      menu: menu,
      children: [
        // A phone has nowhere else for the sub-pages; from 600 dp the rail or the sidebar has them.
        if (!wide) ProgressTabs(location: '/progress'),
        if (failures.isNotEmpty)
          ErrorState(
            message: failureText(l10n, failures.first),
            // Retry reloads every number that failed, not only the chart's.
            onRetry: () {
              if (totals.load.failure != null) {
                ref.read(totalsViewModelProvider.notifier).load();
              }
              if (training.load.failure != null) {
                ref.read(trainingViewModelProvider.notifier).load();
              }
              if (readiness.load.failure != null) {
                ref.read(readinessViewModelProvider.notifier).load();
              }
            },
            actionKey: const Key('progress-error'),
          ),
        // A wide window chooses the sport with the chips on the page; a phone opens the same choice in
        // one chip, because five chips would take the top of the screen.
        if (wide)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              ChoiceChip(
                key: const Key('progress-filter-all'),
                label: Text(l10n.rideFilterAll),
                selected: filters.discipline == null,
                onSelected: (_) => ref
                    .read(progressFiltersViewModelProvider.notifier)
                    .setDiscipline(null),
              ),
              for (final discipline in ['road', 'gravel', 'mountain', 'track'])
                ChoiceChip(
                  key: Key('progress-filter-$discipline'),
                  label: Text(disciplineName(l10n, discipline)),
                  selected: filters.discipline == discipline,
                  onSelected: (_) => ref
                      .read(progressFiltersViewModelProvider.notifier)
                      .setDiscipline(discipline),
                ),
            ],
          )
        else
          Row(
            children: [
              ActionChip(
                key: const Key('progress-filter-chip'),
                avatar: const Icon(Icons.expand_more, size: 18),
                label: Text(
                  filters.discipline == null
                      ? l10n.rideFilterAll
                      : disciplineName(l10n, filters.discipline!),
                ),
                onPressed: () => showProgressFilterSheet(context),
              ),
            ],
          ),
        // A wide window puts the four facts in one row; a phone leads with readiness, puts Form and this
        // period side by side under it and ends with the next event, as the phone mock-up draws them.
        if (wide)
          StatCardRow(children: metrics)
        else ...[
          ?readinessCard,
          if (formCard != null && periodCard != null)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.lg,
                children: [
                  Expanded(child: formCard),
                  Expanded(child: periodCard),
                ],
              ),
            )
          else ...[
            ?formCard,
            ?periodCard,
          ],
          nextCard,
        ],
        // The chart's own loading state: the page is not empty while the totals arrive.
        if (totals.load.running && totals.load.value == null)
          Semantics(
            liveRegion: true,
            label: l10n.loading,
            child: const PlaceholderBlock(
              key: Key('totals-loading'),
              height: 180,
              radius: 16,
            ),
          ),
        if (totals.load.value case final data?)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: [
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(switch (data.period) {
                      'week' => l10n.totalsTitleWeekly,
                      'month' => l10n.totalsTitleMonthly,
                      _ => l10n.totalsTitleYearly,
                    }, style: Theme.of(context).textTheme.titleMedium),
                    periods,
                  ],
                ),
                TotalsChart(period: data.period, totals: data.totals),
              ],
            ),
          ),
        // A simple mode folds the analysis, but what the page leads with stays where it is: only the
        // cards the mode asks for stay above the fold.
        if (layout.foldAdvanced) ...[
          for (final (widget, advanced) in analysis)
            if (!advanced) widget,
          MoreDetails(
            label: l10n.moreDetailsAnalysis,
            children: [
              // The folded sources' own failures wait here, so opening the fold is what shows them.
              for (final error in foldedErrors) error,
              CardGrid(
                columns: 3,
                children: [
                  for (final (widget, advanced) in analysis)
                    if (advanced) widget,
                ],
              ),
            ],
          ),
        ] else
          // A training rider sees the analysis on the page itself, in the same order.
          for (final (widget, _) in analysis) widget,
      ],
    );
  }
}

/// Days to the next event, and which event it is. With nothing planned it says so and still leads to
/// Goals, which is where an event is added.
class _NextEventCard extends ConsumerWidget {
  const _NextEventCard({required this.next});

  final EventResponse? next;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final units = ref.watch(unitsChoiceViewModelProvider);
    final event = next;
    if (event == null) {
      return StatCard(
        key: const Key('metric-next-event'),
        title: l10n.nextEvent,
        value: '–',
        sentence: l10n.noEventPlanned,
        link: l10n.navGoalsAndEvents,
        onLink: () => context.go('/goals'),
      );
    }
    final days = DateUtils.dateOnly(event.date)
        .difference(DateUtils.dateOnly(DateTime.now()))
        .inDays;
    return StatCard(
      key: const Key('metric-next-event'),
      title: l10n.nextEvent,
      value: days <= 0 ? l10n.eventToday : '$days',
      unit: days <= 0 ? null : (days == 1 ? l10n.dayUnit : l10n.daysUnit),
      sentence:
          '${event.name} · ${DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag()).format(event.date)}'
          '${eventDetail(l10n, units, event).isEmpty ? '' : ' · ${eventDetail(l10n, units, event)}'}',
      link: l10n.navGoalsAndEvents,
      onLink: () => context.go('/goals'),
    );
  }
}
