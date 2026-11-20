import 'dart:async' show scheduleMicrotask;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/placeholder_block.dart';
import '../../core/l10n.dart';
import '../../core/rider_mode.dart';
import '../../core/widgets/more_details.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/card_grid.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/ftp_suggestion_card.dart';
import '../../core/widgets/heart_rate_note_card.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_heading.dart';
import '../../core/widgets/stat_tile.dart';
import '../../core/widgets/toolbar_row.dart';
import '../../l10n/generated/app_localizations.dart';
import '../accounts/ftp_source_text.dart';
import '../rides/ride_type_chips.dart';
import 'goals.dart';
import 'ftp_history_sheet.dart';
import 'efficiency_card.dart';
import 'events.dart';
import 'intensity_card.dart';
import 'ftp_reminder_card.dart';
import 'power_summary.dart';
import 'rider_card.dart';
import 'progress_data.dart';
import 'progress_view_models.dart';
import 'readiness_card.dart';
import 'totals_chart.dart';
import 'training_summary.dart';
import 'wellbeing_card.dart';
import '../../core/tokens.dart';
import '../../core/widgets/form_sheet.dart';
import '../../core/units.dart';

/// How many totals rows the table lists before the rest are counted.
const _totalsShown = 8;

/// Where the current FTP came from, from the newest row of the member's own history. Null when
/// the history says nothing yet (no FTP, or the call failed): a missing note beats a wrong one.
String? _ftpNote(AppLocalizations l10n, List<FtpHistoryEntry> history) {
  final newest = history.firstOrNull;
  if (newest == null) return null;
  return ftpSourceText(l10n, newest.source_, newest.setAt);
}

/// Totals per week, month or year, goals, readiness, training, power and the
/// daily check-in. Each source is its own ViewModel, so one failing endpoint
/// does not blank the page.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  Future<void> _addGoal(BuildContext context, WidgetRef ref) async {
    final g = await showGoalForm(context);
    if (g == null) return;
    await ref
        .read(goalsViewModelProvider.notifier)
        .add(
          CreateGoalRequest(
            period: g.period,
            metric: g.metric,
            target: g.target,
          ),
        );
  }

  Future<void> _editGoal(
    BuildContext context,
    WidgetRef ref,
    GoalResponse goal,
  ) async {
    final g = await showGoalForm(context, goal: goal);
    if (g == null) return;
    await ref
        .read(goalsViewModelProvider.notifier)
        .setTarget(goal.id, g.target);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final layout = ref.watch(riderLayoutProvider);
    final filters = ref.watch(progressFiltersViewModelProvider);
    final totals = ref.watch(totalsViewModelProvider);
    final goals = ref.watch(goalsViewModelProvider);
    final training = ref.watch(trainingViewModelProvider);
    final riderCard = ref.watch(riderCardViewModelProvider);
    final power = ref.watch(powerCurveViewModelProvider);
    final readiness = ref.watch(readinessViewModelProvider);
    final wellbeing = ref.watch(wellbeingViewModelProvider);
    final reminder = ref.watch(ftpReminderViewModelProvider);
    final heartRate = ref.watch(heartRateSuggestionViewModelProvider);
    final events = ref.watch(eventsViewModelProvider);
    final units = ref.watch(unitsChoiceViewModelProvider);

    listenUserMessages(
      ref,
      context,
      goalsViewModelProvider.select((s) => s.messages),
      ref.read(goalsViewModelProvider.notifier).messageShown,
    );
    listenUserMessages(
      ref,
      context,
      powerCurveViewModelProvider.select((s) => s.messages),
      ref.read(powerCurveViewModelProvider.notifier).messageShown,
    );
    listenUserMessages(
      ref,
      context,
      wellbeingViewModelProvider.select((s) => s.messages),
      ref.read(wellbeingViewModelProvider.notifier).messageShown,
    );
    listenUserMessages(
      ref,
      context,
      ftpReminderViewModelProvider.select((s) => s.messages),
      ref.read(ftpReminderViewModelProvider.notifier).messageShown,
    );
    listenUserMessages(
      ref,
      context,
      heartRateSuggestionViewModelProvider.select((s) => s.messages),
      ref.read(heartRateSuggestionViewModelProvider.notifier).messageShown,
    );
    listenUserMessages(
      ref,
      context,
      eventsViewModelProvider.select((s) => s.messages),
      ref.read(eventsViewModelProvider.notifier).messageShown,
    );

    // A source counts only when its card is on the page: a folded part says nothing until it is opened,
    // so a failure nobody can see is not thrown at the member.
    final failures = [
      totals.load.failure,
      goals.load.failure,
      if (!layout.foldAdvanced) ...[
        riderCard.load.failure,
        training.load.failure,
        power.load.failure,
        readiness.load.failure,
        wellbeing.load.failure,
      ],
    ].whereType<Failure>();
    // A source the member cannot see yet says so only once the fold is open, and its retry asks that one source
    // again rather than reloading the whole page.
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
      foldedError(
        'wellbeing',
        wellbeing.load.failure,
        () => ref.read(wellbeingViewModelProvider.notifier).load(),
      ),
    ].nonNulls;

    // The analysis: the totals chart leads, then each source that explains it. The check-in follows,
    // because it is the member's own input rather than an answer. Each part says whether only the
    // training view keeps it on the page; a simple mode folds those behind one button.
    final analysis = <(Widget, bool)>[
      // The rider's own numbers lead: they say where they stand before any one chart explains why. They are
      // part of the analysis, so the simple modes fold them behind the same button as the rest.
      if (riderCard.load.value case final card?)
        (
          RiderCard(card: card, onMore: () => showRiderCard(context, card)),
          true,
        ),
      // A ride that shows a higher FTP is the strongest answer there is, so it leads; while it is open the
      // reminder stays quiet, because it would only ask about the number the same FTP is about to replace.
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
      // A heart-rate number the rider typed that a ride beat is the same kind of question, answered here.
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
      // A wrong FTP makes every zone and TSS below it wrong, so the reminder leads the analysis.
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
      if (totals.load.value case final totalsData?)
        (_TotalsCard(totals: totalsData), false)
      else if (totals.load.running)
        (
          Semantics(
            liveRegion: true,
            label: l10n.loading,
            child: const Column(
              key: Key('totals-loading'),
              children: [
                PlaceholderBlock(height: 180, radius: 16),
                SizedBox(height: AppSpacing.md),
                PlaceholderBlock(height: 120, radius: 16),
              ],
            ),
          ),
          false,
        ),
      if (readiness.load.value case final readinessData?)
        (ReadinessCard(readiness: readinessData), true),
      if (events.next case final EventResponse next)
        (
          NextEventCard(
            next: next,
            onAll: () => context.push('/progress/events'),
          ),
          false,
        ),
      if (totals.load.value case final totalsData?)
        (_TotalsTable(totals: totalsData), false),
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
            ftpNote: _ftpNote(l10n, power.history),
            ftpRideId: power.history.firstOrNull?.rideId,
            onOpenRide: (id) => context.push('/rides/$id'),
          ),
          true,
        ),
    ];
    final coreAnalysis = [
      for (final (widget, advanced) in analysis)
        if (!advanced) widget,
    ];
    final foldedAnalysis = [
      for (final (widget, advanced) in analysis)
        if (advanced) widget,
    ];
    final wellbeingCard = WellbeingCard(
      wellbeing: wellbeing.today,
      checkIns: wellbeing.checkIns,
      saving: wellbeing.action.running,
      onConsent: () => ref.read(wellbeingViewModelProvider.notifier).consent(),
      onWithdraw: () =>
          ref.read(wellbeingViewModelProvider.notifier).withdrawConsent(),
      onSave: (fatigue, soreness, mood, stress, motivation) => ref
          .read(wellbeingViewModelProvider.notifier)
          .saveCheckIn(fatigue, soreness, mood, stress, motivation),
    );

    // A wide window also keeps the filters on the page; every width opens them from the header menu.
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoint.compactWidth;
    final periods = SegmentedButton<String>(
      key: const Key('progress-period'),
      showSelectedIcon: false,
      segments: [
        ButtonSegment(value: 'week', label: Text(l10n.periodWeeks)),
        ButtonSegment(value: 'month', label: Text(l10n.periodMonths)),
        ButtonSegment(value: 'year', label: Text(l10n.periodYears)),
      ],
      selected: {filters.period},
      onSelectionChanged: (s) => ref
          .read(progressFiltersViewModelProvider.notifier)
          .setPeriod(s.single),
    );
    final disciplines = [
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
    ];

    // The dashboard reads top-down: the four numbers that answer "how am I going", then the detail
    // they come from. Every number is one the page already had.
    final periodWord = switch (filters.period) {
      'week' => l10n.periodWordWeek,
      'month' => l10n.periodWordMonth,
      _ => l10n.periodWordYear,
    };
    final latest = switch (totals.load.value) {
      final data? when data.totals.isNotEmpty => data.totals.last,
      _ => null,
    };
    final thisPeriod = _metricCard(
      key: const Key('metric-period'),
      label: l10n.metricThisPeriod(periodWord),
      value: latest == null ? '–' : km(units, latest.distanceM),
      detail: latest == null
          ? null
          : l10n.periodTotals(
              latest.rides,
              duration(latest.movingS),
              elevation(units, latest.elevationGainM),
            ),
    );
    final metrics = <Widget>[
      if (!layout.foldAdvanced) ...[
        if (readiness.load.value case final r?)
          _metricCard(
            key: const Key('metric-readiness'),
            label: l10n.readiness,
            value: r.score == null ? '–' : '${r.score}',
            detail: switch (r.band) {
              'hard' => l10n.readinessHard,
              'easy' => l10n.readinessEasy,
              'rest' => l10n.readinessRest,
              _ => l10n.readinessNormal,
            },
          ),
        if (training.load.value case final t?)
          _metricCard(
            key: const Key('metric-training'),
            label: l10n.metricTrainingLoad,
            value: t.tss.round().toString(),
            detail: 'TSS · ${l10n.bikeRides(t.rides)}',
          ),
        if (power.load.value case final p? when p.hasPower)
          _metricCard(
            key: const Key('metric-power'),
            label: l10n.metricPower,
            value: p.currentFtpW == null ? '–' : '${p.currentFtpW} W',
            detail: l10n.ftpCurrent,
          ),
      ],
      thisPeriod,
    ];

    final menu = PageMenu(
      buttonKey: const Key('progress-actions'),
      badge: filters.discipline != null,
      entries: [
        PageMenuEntry(
          key: const Key('progress-filter'),
          icon: Icons.filter_list,
          label: l10n.progressFilterTitle,
          // The menu closes first; the sheet then opens over the page, not over the menu.
          onSelected: () => scheduleMicrotask(() {
            if (context.mounted) {
              showFiltersSheet(context, (_) => const _ProgressFilterSheet());
            }
          }),
        ),
        PageMenuEntry(
          key: const Key('progress-ftp-history'),
          icon: Icons.history,
          label: l10n.ftpHistory,
          onSelected: () => scheduleMicrotask(() {
            if (context.mounted) {
              final data = ref.read(progressDataProvider);
              showFtpHistorySheet(context, data.ftpHistory, data.ftpRideDates);
            }
          }),
        ),
      ],
    );

    final page = PageScaffold(
      eyebrow: l10n.eyebrowProgress,
      title: l10n.navProgress,
      subtitle: l10n.progressSubtitle,
      menu: menu,
      children: [
        if (wide) ToolbarRow(children: [periods, ...disciplines]),
        if (failures.isNotEmpty)
          ErrorState(
            message: failureText(l10n, failures.first),
            actionKey: const Key('progress-error'),
          ),
        _MetricRow(children: metrics),
        // A simple mode folds the training lab, but never the goals: opening the fold must not push them down.
        if (layout.foldAdvanced)
          CardGrid(
            columns: 3,
            hero: coreAnalysis.isEmpty ? 0 : 2,
            children: coreAnalysis,
          )
        else
          CardGrid(
            columns: 3,
            hero: analysis.isEmpty ? 0 : 2,
            children: [for (final (widget, _) in analysis) widget],
          ),
        SectionHeading(
          title: l10n.goals,
          action: FilledButton.tonalIcon(
            key: const Key('add-goal'),
            onPressed: () => _addGoal(context, ref),
            icon: const Icon(Icons.flag),
            label: Text(l10n.addGoal),
          ),
        ),
        CardGrid(
          children: [
            if (goals.goals.isEmpty &&
                !goals.load.running &&
                goals.load.failure == null)
              EmptyState(
                key: const Key('no-goals'),
                message: l10n.noGoals,
                icon: Icons.flag_outlined,
              ),
            for (final goal in goals.goals)
              GoalCard(
                goal: goal,
                onEdit: () => _editGoal(context, ref, goal),
                onDelete: () =>
                    ref.read(goalsViewModelProvider.notifier).delete(goal.id),
              ),
          ],
        ),
        if (layout.foldAdvanced)
          MoreDetails(
            label: l10n.moreDetailsAnalysis,
            children: [
              // The folded sources' own failures wait here, so opening the fold is what shows them.
              for (final error in foldedErrors) error,
              CardGrid(columns: 3, children: foldedAnalysis),
              // The check-in is the member's own input, and a simple mode never opens with it.
              wellbeingCard,
            ],
          )
        else
          wellbeingCard,
      ],
    );
    return page;
  }
}

/// The filters in one sheet: the period and the discipline, applied as they are chosen.
class _ProgressFilterSheet extends ConsumerWidget {
  const _ProgressFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(progressFiltersViewModelProvider);
    final notifier = ref.read(progressFiltersViewModelProvider.notifier);
    final l10n = context.l10n;
    return SheetFrame(
      title: l10n.progressFilterTitle,
      children: [
        SegmentedButton<String>(
          key: const Key('progress-period'),
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 'week', label: Text(l10n.periodWeeks)),
            ButtonSegment(value: 'month', label: Text(l10n.periodMonths)),
            ButtonSegment(value: 'year', label: Text(l10n.periodYears)),
          ],
          selected: {filters.period},
          onSelectionChanged: (s) => notifier.setPeriod(s.single),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            ChoiceChip(
              key: const Key('progress-filter-all'),
              label: Text(l10n.rideFilterAll),
              selected: filters.discipline == null,
              onSelected: (_) => notifier.setDiscipline(null),
            ),
            for (final discipline in ['road', 'gravel', 'mountain', 'track'])
              ChoiceChip(
                key: Key('progress-filter-$discipline'),
                label: Text(disciplineName(l10n, discipline)),
                selected: filters.discipline == discipline,
                onSelected: (_) => notifier.setDiscipline(discipline),
              ),
          ],
        ),
      ],
    );
  }
}

/// A number and what it means, on a surface of its own: the top of a dashboard.
Widget _metricCard({
  required Key key,
  required String label,
  required String value,
  String? detail,
}) => StatTile(
  key: key,
  label: label,
  value: value,
  detail: detail,
  boxed: true,
  headline: true,
);

/// The metric cards in one row: equal columns on a desktop window, two and two on a tablet, one
/// under the other on a phone.
class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = MediaQuery.sizeOf(context).width;
      final count = switch (width) {
        >= AppBreakpoint.expandedWidth => children.length,
        >= AppBreakpoint.compactWidth => 2,
        _ => 1,
      };
      const gap = AppSpacing.md;
      final cell = (constraints.maxWidth - gap * (count - 1)) / count;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: cell, child: child),
        ],
      );
    },
  );
}

/// The totals as the chart and its numbers: the chart gets a title, so the page says what it shows.
class _TotalsCard extends ConsumerWidget {
  const _TotalsCard({required this.totals});

  final TotalsResponse totals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final units = ref.watch(unitsChoiceViewModelProvider);
    final latest = totals.totals.isEmpty ? null : totals.totals.last;
    final title = switch (totals.period) {
      'week' => l10n.totalsTitleWeekly,
      'month' => l10n.totalsTitleMonthly,
      _ => l10n.totalsTitleYearly,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (latest != null)
              Text(
                l10n.periodTotals(
                  latest.rides,
                  duration(latest.movingS),
                  elevation(units, latest.elevationGainM),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            TotalsChart(period: totals.period, totals: totals.totals),
          ],
        ),
      ),
    );
  }
}

/// The same totals as the chart, newest first, with every number. A long year stops at the first few
/// rows; the chart still has them all.
class _TotalsTable extends ConsumerWidget {
  const _TotalsTable({required this.totals});

  final TotalsResponse totals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final units = ref.watch(unitsChoiceViewModelProvider);
    final rows = totals.totals.reversed.toList();
    return Card(
      child: Column(
        children: [
          for (final (i, t) in rows.take(_totalsShown).indexed)
            ListTile(
              key: Key('total-$i'),
              dense: true,
              title: Text(
                i == 0
                    ? switch (totals.period) {
                        'week' => l10n.thisWeek,
                        'month' => l10n.thisMonth,
                        _ => l10n.thisYear,
                      }
                    : periodTitle(totals.period, t.start, t.end),
              ),
              subtitle: Text(
                l10n.periodTotals(
                  t.rides,
                  duration(t.movingS),
                  elevation(units, t.elevationGainM),
                ),
              ),
              trailing: Text(
                km(units, t.distanceM),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          if (rows.length > _totalsShown)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l10n.totalsMore(rows.length - _totalsShown),
                key: const Key('totals-more'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
