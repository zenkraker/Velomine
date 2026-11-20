import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:velomine_api/api.dart';

import '../../core/confirm.dart';
import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/card_grid.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../progress/events.dart';
import '../progress/progress_view_models.dart';
import 'goals.dart';
import 'goals_view_models.dart';

/// Goals: a destination of its own, so a goal is not something to scroll for. Each goal is a card with its
/// gauge and one sentence, and the next event sits under them.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

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

  Future<void> _deleteGoal(
    BuildContext context,
    WidgetRef ref,
    GoalResponse goal,
  ) async {
    final l10n = context.l10n;
    final sure = await confirmDestructive(
      context,
      title: l10n.goalDeleteTitle,
      body: l10n.goalDeleteBody,
      action: l10n.goalDelete,
      key: const Key('goal-delete-confirm'),
    );
    if (!sure) return;
    await ref.read(goalsViewModelProvider.notifier).delete(goal.id);
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
    final goals = ref.watch(goalsViewModelProvider);
    final events = ref.watch(eventsViewModelProvider);

    listenUserMessages(
      ref,
      context,
      goalsViewModelProvider.select((s) => s.messages),
      ref.read(goalsViewModelProvider.notifier).messageShown,
    );

    final failure = goals.load.failure;
    // Running goals first, the reached ones after: what still needs the rider comes first.
    final ordered = [
      ...goals.goals.where((goal) => !goal.reached),
      ...goals.goals.where((goal) => goal.reached),
    ];
    final running = goals.goals.where((goal) => !goal.reached).length;
    final reached = goals.goals.length - running;
    return PageScaffold(
      title: l10n.navGoals,
      primaryAction: FilledButton.icon(
        key: const Key('add-goal'),
        onPressed: () => _addGoal(context, ref),
        icon: const Icon(Icons.flag),
        label: Text(l10n.addGoal),
      ),
      children: [
        // One sentence that sums the goals up; with no goals the empty state does the talking.
        if (goals.goals.isNotEmpty)
          Text(
            // The generator sorts the placeholders by name, so the reached count comes first.
            l10n.goalsSummary(reached, running),
            key: const Key('goals-summary'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        if (events.next case final next?)
          NextEventCard(
            next: next,
            onAll: () => context.push('/progress/events'),
          ),
        if (failure != null)
          ErrorState(
            message: failureText(l10n, failure),
            onRetry: ref.read(goalsViewModelProvider.notifier).load,
            actionKey: const Key('goals-error'),
          ),
        if (goals.goals.isEmpty &&
            !goals.load.running &&
            goals.load.failure == null)
          EmptyState(
            key: const Key('no-goals'),
            message: l10n.noGoals,
            icon: Icons.flag_outlined,
          ),
        CardGrid(
          columns: 3,
          tabletColumns: 2,
          children: [
            for (final goal in ordered)
              GoalCard(
                goal: goal,
                onEdit: () => _editGoal(context, ref, goal),
                onDelete: () => _deleteGoal(context, ref, goal),
              ),
          ],
        ),
      ],
    );
  }
}
