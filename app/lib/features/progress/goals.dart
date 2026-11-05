import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velomine_api/api.dart';

import '../../core/format.dart';

const periodNames = {'week': 'Weekly', 'month': 'Monthly', 'year': 'Yearly'};

/// What a goal can count, with the unit the member types the target in and the factor to the server's SI value.
const goalMetrics = {
  'distance': (name: 'Distance', unit: 'km', factor: 1000.0),
  'elevation': (name: 'Climbing', unit: 'm', factor: 1.0),
  'time': (name: 'Riding time', unit: 'h', factor: 3600.0),
  'rides': (name: 'Rides', unit: 'rides', factor: 1.0),
};

/// A goal value (metres, seconds or a count) as the member reads it.
String goalValue(String metric, double value) => switch (metric) {
  'distance' => km(value),
  'elevation' => '${value.round()} m',
  'time' => duration(value),
  'rides' => '${value.round()} ${value.round() == 1 ? 'ride' : 'rides'}',
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
        : _plain(widget.goal!.target / goalMetrics[_metric]!.factor),
  );
  String? _error;

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_target.text.trim().replaceAll(',', '.'));
    if (value == null || value <= 0) {
      setState(() => _error = 'Enter a target above 0.');
      return;
    }
    Navigator.pop(context, (
      period: _period,
      metric: _metric,
      target: value * goalMetrics[_metric]!.factor,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.goal != null;
    return AlertDialog(
      title: Text(editing ? 'Change goal' : 'Add goal'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            DropdownButtonFormField<String>(
              key: const Key('goal-period'),
              initialValue: _period,
              decoration: const InputDecoration(labelText: 'Every'),
              items: [
                for (final p in ['week', 'month', 'year'])
                  DropdownMenuItem(value: p, child: Text(p)),
              ],
              onChanged: editing
                  ? null
                  : (v) => setState(() => _period = v ?? _period),
            ),
            DropdownButtonFormField<String>(
              key: const Key('goal-metric'),
              initialValue: _metric,
              decoration: const InputDecoration(labelText: 'Count'),
              items: [
                for (final e in goalMetrics.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value.name)),
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
                labelText: 'Target',
                suffixText: goalMetrics[_metric]!.unit,
                errorText: _error,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('goal-save'),
          onPressed: _submit,
          child: const Text('Save'),
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
    final metric = goalMetrics[goal.metric]?.name ?? goal.metric;
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
                    '${periodNames[goal.period] ?? goal.period} ${metric.toLowerCase()}',
                    style: text.titleMedium,
                  ),
                ),
                if (goal.reached)
                  Chip(
                    label: const Text('Reached'),
                    backgroundColor: scheme.primaryContainer,
                  ),
                IconButton(
                  key: Key('goal-edit-${goal.id}'),
                  tooltip: 'Change target',
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                ),
                IconButton(
                  key: Key('goal-delete-${goal.id}'),
                  tooltip: 'Delete goal',
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
                semanticsLabel: '$metric goal',
              ),
            ),
            Text(
              '${goalValue(goal.metric, goal.current)} of ${goalValue(goal.metric, goal.target)} · ${goal.percent} %',
              key: Key('goal-progress-${goal.id}'),
            ),
          ],
        ),
      ),
    );
  }
}
