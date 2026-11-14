import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/placeholder_block.dart';
import '../../core/l10n.dart';
import '../../core/page_actions.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/card_grid.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_heading.dart';
import '../../core/widgets/toolbar_row.dart';
import '../rides/ride_type_chips.dart';
import 'goals.dart';
import 'power_summary.dart';
import 'progress_view_models.dart';
import 'readiness_card.dart';
import 'totals_chart.dart';
import 'training_summary.dart';
import 'wellbeing_card.dart';
import '../../core/tokens.dart';
import '../../core/units.dart';

/// How many totals rows the table lists before the rest are counted.
const _totalsShown = 8;

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
    final filters = ref.watch(progressFiltersViewModelProvider);
    final totals = ref.watch(totalsViewModelProvider);
    final goals = ref.watch(goalsViewModelProvider);
    final training = ref.watch(trainingViewModelProvider);
    final power = ref.watch(powerCurveViewModelProvider);
    final readiness = ref.watch(readinessViewModelProvider);
    final wellbeing = ref.watch(wellbeingViewModelProvider);
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

    final failures = [
      totals.load.failure,
      goals.load.failure,
      training.load.failure,
      power.load.failure,
      readiness.load.failure,
      wellbeing.load.failure,
    ].whereType<Failure>();

    // The analysis: the totals chart leads, then each source that explains it. The check-in follows,
    // because it is the member's own input rather than an answer.
    final analysis = <Widget>[
      if (totals.load.value case final totalsData?)
        _TotalsCard(totals: totalsData)
      else if (totals.load.running)
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
      if (readiness.load.value case final readinessData?)
        ReadinessCard(readiness: readinessData),
      if (totals.load.value case final totalsData?)
        _TotalsTable(totals: totalsData),
      if (training.load.value case final trainingData?)
        TrainingSummary(
          training: trainingData,
          days: filters.trainingDays,
          onDays: (days) async => ref
              .read(progressFiltersViewModelProvider.notifier)
              .setTrainingDays(days),
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
        ),
    ];

    // A wide window keeps the filters on the page; a phone opens them from the title bar.
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
    final thisPeriod = _MetricCard(
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
      if (readiness.load.value case final r?)
        _MetricCard(
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
        _MetricCard(
          key: const Key('metric-training'),
          label: l10n.metricTrainingLoad,
          value: t.tss.round().toString(),
          detail: 'TSS · ${l10n.bikeRides(t.rides)}',
        ),
      if (power.load.value case final p? when p.hasPower)
        _MetricCard(
          key: const Key('metric-power'),
          label: l10n.metricPower,
          value: p.currentFtpW == null ? '–' : '${p.currentFtpW} W',
          detail: l10n.ftpCurrent,
        ),
      thisPeriod,
    ];

    final page = PageScaffold(
      eyebrow: l10n.eyebrowProgress,
      title: l10n.navProgress,
      subtitle: l10n.progressSubtitle,
      children: [
        if (wide) ToolbarRow(children: [periods, ...disciplines]),
        if (failures.isNotEmpty)
          ErrorState(
            message: failureText(l10n, failures.first),
            actionKey: const Key('progress-error'),
          ),
        _MetricRow(children: metrics),
        CardGrid(
          columns: 3,
          hero: analysis.isEmpty ? 0 : 2,
          children: analysis,
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
        WellbeingCard(
          wellbeing: wellbeing.today,
          checkIns: wellbeing.checkIns,
          saving: wellbeing.action.running,
          onConsent: () =>
              ref.read(wellbeingViewModelProvider.notifier).consent(),
          onWithdraw: () =>
              ref.read(wellbeingViewModelProvider.notifier).withdrawConsent(),
          onSave: (fatigue, soreness, mood, stress, motivation) => ref
              .read(wellbeingViewModelProvider.notifier)
              .saveCheckIn(fatigue, soreness, mood, stress, motivation),
        ),
      ],
    );
    if (wide) return page;
    return _PhoneFilterButton(active: filters.discipline != null, child: page);
  }
}

/// On a phone the filters open from the title bar, so the page registers that button while it is on
/// screen and takes it down when it leaves.
class _PhoneFilterButton extends ConsumerStatefulWidget {
  const _PhoneFilterButton({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  ConsumerState<_PhoneFilterButton> createState() => _PhoneFilterButtonState();
}

class _PhoneFilterButtonState extends ConsumerState<_PhoneFilterButton> {
  @override
  void initState() {
    super.initState();
    // After the first frame: the title bar then has its place, and the page is not changing under it.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Future.microtask(_publish),
    );
  }

  @override
  void didUpdateWidget(_PhoneFilterButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Future.microtask(_publish),
      );
    }
  }

  void _publish() {
    if (!mounted) return;
    final actions = [
      phoneFilterButton(
        key: const Key('progress-filter'),
        tooltip: context.l10n.progressFilterTitle,
        active: widget.active,
        onPressed: () =>
            showFiltersSheet(context, (_) => const _ProgressFilterSheet()),
      ),
    ];
    ref
        .read(pageActionsProvider.notifier)
        .set(GoRouterState.of(context).uri.path, actions);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A phone's filters in one sheet: the period and the discipline, applied as they are chosen.
class _ProgressFilterSheet extends ConsumerWidget {
  const _ProgressFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(progressFiltersViewModelProvider);
    final notifier = ref.read(progressFiltersViewModelProvider.notifier);
    final l10n = context.l10n;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.lg,
        children: [
          Text(
            l10n.progressFilterTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
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
      ),
    );
  }
}

/// A number and what it means, in a card of its own: the top of a dashboard.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.detail,
  });

  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Text(
              label.toUpperCase(),
              style: text.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.3,
                color: scheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w400),
            ),
            if (detail case final detail?)
              Text(
                detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

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
