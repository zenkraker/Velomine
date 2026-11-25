import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/confirm.dart';
import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_card.dart';
import '../profile/profile_screen.dart' show weekDayName;
import 'training_goals.dart';
import 'training_view_model.dart';

/// Training: the rider's auto-training plan. It is a destination of its own while auto training is on, and its
/// menu changes the setup or turns it off. This story adds the destination, the goal and the switch: today's
/// session and this week's rows are the planning story.
class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  Future<void> _turnOff(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final sure = await confirmDestructive(
      context,
      title: l10n.autoTrainingOffTitle,
      body: l10n.autoTrainingOffBody,
      action: l10n.autoTrainingOffAction,
      key: const Key('training-off-confirm'),
    );
    if (!sure || !context.mounted) return;
    final turnedOff = await ref
        .read(trainingViewModelProvider.notifier)
        .turnOff();
    // The destination goes with the switch: the rider lands on their rides.
    if (turnedOff && context.mounted) context.go('/rides');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(trainingViewModelProvider);
    listenUserMessages(
      ref,
      context,
      trainingViewModelProvider.select((s) => s.messages),
      ref.read(trainingViewModelProvider.notifier).messageShown,
    );

    final plan = state.plan;
    final goal = plan?.goal ?? plan?.suggestedGoal ?? 'fitter';
    final failure = state.load.failure;
    return PageScaffold(
      title: l10n.navTraining,
      subtitle: [
        trainingGoalName(l10n, goal),
        if (plan?.hoursPerWeek case final hours?) l10n.trainingHoursLine(hours),
      ].join(' · '),
      menu: PageMenu(
        buttonKey: const Key('training-menu'),
        entries: [
          PageMenuEntry(
            key: const Key('training-change-setup'),
            label: l10n.trainingChangeSetup,
            icon: Icons.tune,
            onSelected: () => context.push('/training/setup'),
          ),
          PageMenuEntry(
            key: const Key('training-turn-off'),
            label: l10n.autoTrainingOffAction,
            icon: Icons.power_settings_new,
            destructive: true,
            onSelected: () => _turnOff(context, ref),
          ),
        ],
      ),
      children: [
        if (state.load.running && plan == null)
          const LoadingState.rows()
        else if (failure != null)
          ErrorState(
            message: failureText(l10n, failure),
            onRetry: ref.read(trainingViewModelProvider.notifier).load,
            actionKey: const Key('training-error'),
          )
        else ...[
          SectionCard(
            key: const Key('training-goal'),
            title: l10n.trainingGoalCard,
            children: [
              Text(
                trainingGoalName(l10n, goal),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                trainingGoalLine(l10n, goal),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Text(
            l10n.trainingPlanStarts(
              weekDayName(l10n, plan?.firstDayOfWeek ?? 'monday'),
            ),
            key: const Key('training-plan-starts'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
