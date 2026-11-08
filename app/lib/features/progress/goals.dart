import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../l10n/generated/app_localizations.dart';

const goalPeriodIds = ['week', 'month', 'year'];

/// What a goal can count, with the factor to the server's SI value.
const goalMetrics = {
  'distance': 1000.0,
  'elevation': 1.0,
  'time': 3600.0,
  'rides': 1.0,
};

String goalPeriodName(AppLocalizations l10n, String period) => switch (period) {
  'week' => l10n.goalWeekly,
  'month' => l10n.goalMonthly,
  _ => l10n.goalYearly,
};

String goalMetricName(AppLocalizations l10n, String metric) => switch (metric) {
  'distance' => l10n.goalMetricDistance,
  'elevation' => l10n.goalMetricElevation,
  'time' => l10n.goalMetricTime,
  'rides' => l10n.goalMetricRides,
  _ => metric,
};

String goalUnit(AppLocalizations l10n, String metric) => switch (metric) {
  'distance' => 'km',
  'elevation' => 'm',
  'time' => 'h',
  'rides' => l10n.goalUnitRides,
  _ => '',
};

/// A goal value (metres, seconds or a count) as the member reads it.
String goalValue(AppLocalizations l10n, String metric, double value) =>
    switch (metric) {
      'distance' => km(value),
      'elevation' => '${value.round()} m',
      'time' => duration(value),
      'rides' => l10n.goalRideCount(value.round()),
      _ => value.toString(),
    };

String _plain(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// Asks for a new goal (period, metric, target) or, when [goal] is given, a new target for it.
/// Returns the period, metric and target in SI units, or null when cancelled.
Future<({String period, String metric, double target})?> showGoalForm(
  BuildContext context, {
  GoalResponse? goal,
}) => showDialog(
  context: context,
  builder: (_) => _GoalForm(goal: goal),
);

class _GoalForm extends StatefulWidget {
  const _GoalForm({this.goal});

  final GoalResponse? goal;

  @override
  State<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<_GoalForm> {
  late String _period = widget.goal?.period ?? 'week';
  late String _metric = widget.goal?.metric ?? 'distance';
  late final _target = TextEditingController(
    text: widget.goal == null
        ? ''
        : _plain(widget.goal!.target / goalMetrics[_metric]!),
  );
  bool _badTarget = false;

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_target.text.trim().replaceAll(',', '.'));
    if (value == null || value <= 0) {
      setState(() => _badTarget = true);
      return;
    }
    Navigator.pop(context, (
      period: _period,
      metric: _metric,
      target: value * goalMetrics[_metric]!,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final editing = widget.goal != null;
    return AlertDialog(
      title: Text(editing ? l10n.goalChange : l10n.goalAdd),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            DropdownButtonFormField<String>(
              key: const Key('goal-period'),
              initialValue: _period,
              decoration: InputDecoration(labelText: l10n.goalEvery),
              items: [
                for (final p in goalPeriodIds)
                  DropdownMenuItem(
                    value: p,
                    child: Text(switch (p) {
                      'week' => l10n.goalEveryWeek,
                      'month' => l10n.goalEveryMonth,
                      _ => l10n.goalEveryYear,
                    }),
                  ),
              ],
              onChanged: editing
                  ? null
                  : (v) => setState(() => _period = v ?? _period),
            ),
            DropdownButtonFormField<String>(
              key: const Key('goal-metric'),
              initialValue: _metric,
              decoration: InputDecoration(labelText: l10n.goalCount),
              items: [
                for (final metric in goalMetrics.keys)
                  DropdownMenuItem(
                    value: metric,
                    child: Text(goalMetricName(l10n, metric)),
                  ),
              ],
              onChanged: editing
                  ? null
                  : (v) => setState(() => _metric = v ?? _metric),
            ),
            TextField(
              key: const Key('goal-target'),
              controller: _target,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.goalTarget,
                suffixText: goalUnit(l10n, _metric),
                errorText: _badTarget ? l10n.errorGoalTarget : null,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('goal-save'),
          onPressed: _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// One goal with a progress bar: "Weekly distance · 40 km of 100 km".
class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  final GoalResponse goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final metric = goalMetricName(l10n, goal.metric);
    final title = l10n.goalTitle(
      goalPeriodName(l10n, goal.period),
      metric.toLowerCase(),
    );
    return Card(
      key: Key('goal-${goal.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.isEmpty
                        ? title
                        : title[0].toUpperCase() + title.substring(1),
                    style: text.titleMedium,
                  ),
                ),
                if (goal.reached)
                  Chip(
                    label: Text(l10n.goalReached),
                    backgroundColor: scheme.primaryContainer,
                  ),
                IconButton(
                  key: Key('goal-edit-${goal.id}'),
                  tooltip: l10n.goalChangeTarget,
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                ),
                IconButton(
                  key: Key('goal-delete-${goal.id}'),
                  tooltip: l10n.goalDelete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: LinearProgressIndicator(
                value: (goal.percent / 100).clamp(0, 1).toDouble(),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                semanticsLabel: l10n.goalSemantics(metric),
              ),
            ),
            Text(
              l10n.goalProgress(
                goalValue(l10n, goal.metric, goal.current),
                goalValue(l10n, goal.metric, goal.target),
                goal.percent,
              ),
              key: Key('goal-progress-${goal.id}'),
            ),
          ],
        ),
      ),
    );
  }
}
