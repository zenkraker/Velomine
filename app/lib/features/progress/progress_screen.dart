import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/user_message_text.dart';
import '../rides/ride_type_chips.dart';
import 'goals.dart';
import 'power_summary.dart';
import 'progress_view_models.dart';
import 'readiness_card.dart';
import 'totals_chart.dart';
import 'training_summary.dart';
import 'wellbeing_card.dart';

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
    final text = Theme.of(context).textTheme;
    final filters = ref.watch(progressFiltersViewModelProvider);
    final totals = ref.watch(totalsViewModelProvider);
    final goals = ref.watch(goalsViewModelProvider);
    final training = ref.watch(trainingViewModelProvider);
    final power = ref.watch(powerCurveViewModelProvider);
    final readiness = ref.watch(readinessViewModelProvider);
    final wellbeing = ref.watch(wellbeingViewModelProvider);

    ref.listen(goalsViewModelProvider.select((s) => s.messages), (_, messages) {
      for (final message in messages) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userMessageText(l10n, message))));
        ref.read(goalsViewModelProvider.notifier).messageShown(message.id);
      }
    });
    ref.listen(powerCurveViewModelProvider.select((s) => s.messages), (
      _,
      messages,
    ) {
      for (final message in messages) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userMessageText(l10n, message))));
        ref.read(powerCurveViewModelProvider.notifier).messageShown(message.id);
      }
    });
    ref.listen(wellbeingViewModelProvider.select((s) => s.messages), (
      _,
      messages,
    ) {
      for (final message in messages) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userMessageText(l10n, message))));
        ref.read(wellbeingViewModelProvider.notifier).messageShown(message.id);
      }
    });

    final failures = [
      totals.load.failure,
      goals.load.failure,
      training.load.failure,
      power.load.failure,
      readiness.load.failure,
      wellbeing.load.failure,
    ].whereType<Failure>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Text(l10n.navProgress, style: text.titleLarge),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ChoiceChip(
                      key: const Key('progress-filter-all'),
                      label: Text(l10n.rideFilterAll),
                      selected: filters.discipline == null,
                      onSelected: (_) => ref
                          .read(progressFiltersViewModelProvider.notifier)
                          .setDiscipline(null),
                    ),
                    for (final discipline in [
                      'road',
                      'gravel',
                      'mountain',
                      'track',
                    ])
                      ChoiceChip(
                        key: Key('progress-filter-$discipline'),
                        label: Text(disciplineName(l10n, discipline)),
                        selected: filters.discipline == discipline,
                        onSelected: (_) => ref
                            .read(progressFiltersViewModelProvider.notifier)
                            .setDiscipline(discipline),
                      ),
                  ],
                ),
                if (failures.isNotEmpty)
                  Text(
                    failureText(l10n, failures.first),
                    key: const Key('progress-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                SegmentedButton<String>(
                  key: const Key('progress-period'),
                  segments: [
                    ButtonSegment(value: 'week', label: Text(l10n.periodWeeks)),
                    ButtonSegment(
                      value: 'month',
                      label: Text(l10n.periodMonths),
                    ),
                    ButtonSegment(value: 'year', label: Text(l10n.periodYears)),
                  ],
                  selected: {filters.period},
                  onSelectionChanged: (s) => ref
                      .read(progressFiltersViewModelProvider.notifier)
                      .setPeriod(s.single),
                ),
                WellbeingCard(
                  wellbeing: wellbeing.today,
                  checkIns: wellbeing.checkIns,
                  saving: wellbeing.action.running,
                  onConsent: () =>
                      ref.read(wellbeingViewModelProvider.notifier).consent(),
                  onWithdraw: () => ref
                      .read(wellbeingViewModelProvider.notifier)
                      .withdrawConsent(),
                  onSave: (fatigue, soreness, mood, stress, motivation) => ref
                      .read(wellbeingViewModelProvider.notifier)
                      .saveCheckIn(fatigue, soreness, mood, stress, motivation),
                ),
                if (readiness.load.value case final readinessData?)
                  ReadinessCard(readiness: readinessData),
                if (power.load.value case final curve?)
                  PowerSummary(
                    curve: curve,
                    days: filters.powerDays,
                    onDays: (days) async => ref
                        .read(progressFiltersViewModelProvider.notifier)
                        .setPowerDays(days),
                    onUseFtp: (watts) => ref
                        .read(powerCurveViewModelProvider.notifier)
                        .useFtp(watts),
                  ),
                if (totals.load.value case final totalsData?) ...[
                  TotalsChart(
                    period: totalsData.period,
                    totals: totalsData.totals,
                  ),
                  _TotalsTable(totals: totalsData),
                ] else if (totals.load.running)
                  const Center(child: CircularProgressIndicator()),
                if (training.load.value case final trainingData?)
                  TrainingSummary(
                    training: trainingData,
                    days: filters.trainingDays,
                    onDays: (days) async => ref
                        .read(progressFiltersViewModelProvider.notifier)
                        .setTrainingDays(days),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: Text(l10n.goals, style: text.titleLarge)),
                    FilledButton.tonalIcon(
                      key: const Key('add-goal'),
                      onPressed: () => _addGoal(context, ref),
                      icon: const Icon(Icons.flag),
                      label: Text(l10n.addGoal),
                    ),
                  ],
                ),
                if (goals.goals.isEmpty &&
                    !goals.load.running &&
                    goals.load.failure == null)
                  Text(l10n.noGoals, key: const Key('no-goals')),
                for (final goal in goals.goals)
                  GoalCard(
                    goal: goal,
                    onEdit: () => _editGoal(context, ref, goal),
                    onDelete: () => ref
                        .read(goalsViewModelProvider.notifier)
                        .delete(goal.id),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The same totals as the chart, newest first, with every number.
class _TotalsTable extends StatelessWidget {
  const _TotalsTable({required this.totals});

  final TotalsResponse totals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = totals.totals.reversed.toList();
    return Card(
      child: Column(
        children: [
          for (final (i, t) in rows.indexed)
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
                  t.elevationGainM.round(),
                ),
              ),
              trailing: Text(
                km(t.distanceM),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
        ],
      ),
    );
  }
}
