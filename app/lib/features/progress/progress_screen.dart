import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../rides/ride_type_chips.dart';
import 'goals.dart';
import 'power_summary.dart';
import 'progress_controller.dart';
import 'readiness_card.dart';
import 'totals_chart.dart';
import 'training_summary.dart';
import 'wellbeing_card.dart';

/// Totals per week, month or year, and goals.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.controller});

  final ProgressController controller;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.refresh();
  }

  Future<void> _addGoal() async {
    final g = await showGoalForm(context);
    if (g == null) return;
    await widget.controller.addGoal(
      CreateGoalRequest(period: g.period, metric: g.metric, target: g.target),
    );
  }

  Future<void> _editGoal(GoalResponse goal) async {
    final g = await showGoalForm(context, goal: goal);
    if (g == null) return;
    await widget.controller.setTarget(goal.id, g.target);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Text(context.l10n.navProgress, style: text.titleLarge),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ChoiceChip(
                        key: const Key('progress-filter-all'),
                        label: Text(context.l10n.rideFilterAll),
                        selected: c.discipline == null,
                        onSelected: (_) => c.setDiscipline(null),
                      ),
                      for (final discipline in [
                        'road',
                        'gravel',
                        'mountain',
                        'track',
                      ])
                        ChoiceChip(
                          key: Key('progress-filter-$discipline'),
                          label: Text(disciplineName(context.l10n, discipline)),
                          selected: c.discipline == discipline,
                          onSelected: (_) => c.setDiscipline(discipline),
                        ),
                    ],
                  ),
                  if (c.error != null)
                    Text(
                      failureText(context.l10n, c.error!),
                      key: const Key('progress-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  SegmentedButton<String>(
                    key: const Key('progress-period'),
                    segments: [
                      ButtonSegment(
                        value: 'week',
                        label: Text(context.l10n.periodWeeks),
                      ),
                      ButtonSegment(
                        value: 'month',
                        label: Text(context.l10n.periodMonths),
                      ),
                      ButtonSegment(
                        value: 'year',
                        label: Text(context.l10n.periodYears),
                      ),
                    ],
                    selected: {c.period},
                    onSelectionChanged: (s) => c.setPeriod(s.single),
                  ),
                  WellbeingCard(
                    wellbeing: c.wellbeingToday,
                    checkIns: c.checkIns,
                    saving: c.savingWellbeing,
                    onConsent: c.giveWellbeingConsent,
                    onSave: c.saveCheckIn,
                  ),
                  if (c.readiness case final readiness?)
                    ReadinessCard(readiness: readiness),
                  if (c.powerCurve case final curve?)
                    PowerSummary(
                      curve: curve,
                      days: c.powerDays,
                      onDays: c.setPowerDays,
                      onUseFtp: c.useFtp,
                    ),
                  if (c.totals case final totals?) ...[
                    TotalsChart(period: totals.period, totals: totals.totals),
                    _TotalsTable(totals: totals),
                  ] else if (c.loading)
                    const Center(child: CircularProgressIndicator()),
                  if (c.training case final training?)
                    TrainingSummary(
                      training: training,
                      days: c.trainingDays,
                      onDays: c.setTrainingDays,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(context.l10n.goals, style: text.titleLarge),
                      ),
                      FilledButton.tonalIcon(
                        key: const Key('add-goal'),
                        onPressed: _addGoal,
                        icon: const Icon(Icons.flag),
                        label: Text(context.l10n.addGoal),
                      ),
                    ],
                  ),
                  if (c.goals.isEmpty && !c.loading)
                    Text(context.l10n.noGoals, key: const Key('no-goals')),
                  for (final goal in c.goals)
                    GoalCard(
                      goal: goal,
                      onEdit: () => _editGoal(goal),
                      onDelete: () => c.deleteGoal(goal.id),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
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
