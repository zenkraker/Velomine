import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
import 'goals.dart';
import 'progress_controller.dart';
import 'totals_chart.dart';

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
                  Text('Progress', style: text.titleLarge),
                  if (c.error != null)
                    Text(
                      c.error!,
                      key: const Key('progress-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  SegmentedButton<String>(
                    key: const Key('progress-period'),
                    segments: const [
                      ButtonSegment(value: 'week', label: Text('Weeks')),
                      ButtonSegment(value: 'month', label: Text('Months')),
                      ButtonSegment(value: 'year', label: Text('Years')),
                    ],
                    selected: {c.period},
                    onSelectionChanged: (s) => c.setPeriod(s.single),
                  ),
                  if (c.totals case final totals?) ...[
                    TotalsChart(period: totals.period, totals: totals.totals),
                    _TotalsTable(totals: totals),
                  ] else if (c.loading)
                    const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Text('Goals', style: text.titleLarge)),
                      FilledButton.tonalIcon(
                        key: const Key('add-goal'),
                        onPressed: _addGoal,
                        icon: const Icon(Icons.flag),
                        label: const Text('Add goal'),
                      ),
                    ],
                  ),
                  if (c.goals.isEmpty && !c.loading)
                    const Text(
                      'No goals yet. Set a target for each week, month or year: distance, climbing, riding time or number of rides.',
                      key: Key('no-goals'),
                    ),
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
                    ? 'This ${totals.period}'
                    : periodTitle(totals.period, t.start, t.end),
              ),
              subtitle: Text(
                t.rides == 0
                    ? 'No rides'
                    : '${t.rides} ${t.rides == 1 ? 'ride' : 'rides'} · ${duration(t.movingS)} · ${t.elevationGainM.round()} m climbing',
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
