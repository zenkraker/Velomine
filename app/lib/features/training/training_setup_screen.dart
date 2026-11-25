import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/badge.dart';
import '../../core/widgets/bottom_action_bar.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/inline_error.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_card.dart';
import '../../l10n/generated/app_localizations.dart';
import '../profile/profile_screen.dart' show weekDayName;
import 'auto_training_note.dart';
import 'training_goals.dart';
import 'training_setup_state.dart';
import 'training_setup_view_model.dart';

/// Set up auto training: the goal, when the rider rides, and their heart rate. A full page, opened by turning
/// the switch on in Profile and by Change setup on the Training page (then pre-filled). The back arrow cancels
/// and turns nothing on; Start is the form's submit on the bottom bar.
class TrainingSetupScreen extends ConsumerStatefulWidget {
  const TrainingSetupScreen({super.key});

  @override
  ConsumerState<TrainingSetupScreen> createState() =>
      _TrainingSetupScreenState();
}

class _TrainingSetupScreenState extends ConsumerState<TrainingSetupScreen> {
  final _hours = TextEditingController();
  final _maxHeartRate = TextEditingController();
  final _birthYear = TextEditingController();
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    // The field is the view's own; the ViewModel hears every keystroke, because Start validates it.
    _hours.addListener(_hoursChanged);
    _maxHeartRate.addListener(_maxHeartRateChanged);
    _birthYear.addListener(_birthYearChanged);
  }

  void _hoursChanged() =>
      ref.read(trainingSetupViewModelProvider.notifier).setHours(_hours.text);

  void _maxHeartRateChanged() => ref
      .read(trainingSetupViewModelProvider.notifier)
      .setMaxHeartRate(_maxHeartRate.text);

  void _birthYearChanged() => ref
      .read(trainingSetupViewModelProvider.notifier)
      .setBirthYear(_birthYear.text);

  @override
  void dispose() {
    _hours.removeListener(_hoursChanged);
    _maxHeartRate.removeListener(_maxHeartRateChanged);
    _birthYear.removeListener(_birthYearChanged);
    _hours.dispose();
    _maxHeartRate.dispose();
    _birthYear.dispose();
    super.dispose();
  }

  /// The plan as it arrived, once: the rider's own typing is never overwritten after that.
  void _fill(TrainingSetupState state) {
    if (_filled) return;
    _filled = true;
    _hours.text = state.hours;
    _maxHeartRate.text = state.maxHeartRate;
    _birthYear.text = state.birthYear;
  }

  Future<void> _start() async {
    final saved = await ref
        .read(trainingSetupViewModelProvider.notifier)
        .start();
    if (!saved || !mounted) return;
    // Started or changed: the Training page is where the week is. From Profile, the back arrow has no stack.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/training');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(trainingSetupViewModelProvider);
    ref.listen<TrainingSetupState>(trainingSetupViewModelProvider, (
      previous,
      next,
    ) {
      if (next.load.completed) _fill(next);
    });

    final saveFailure = state.save.failure;
    final problem = switch (state.problem) {
      TrainingSetupProblem.days => l10n.errorTrainingDays,
      TrainingSetupProblem.hours => l10n.errorTrainingHours,
      TrainingSetupProblem.maxHeartRate => l10n.errorTrainingMaxHeartRate,
      TrainingSetupProblem.birthYear => l10n.errorTrainingBirthYear,
      null => saveFailure == null ? null : failureText(l10n, saveFailure),
    };
    final loadFailure = state.load.failure;

    return PageScaffold(
      parent: l10n.navTraining,
      title: l10n.trainingSetupTitle,
      maxWidth: AppLayout.contentNarrow,
      bottomAction: BottomActionBar.button(
        buttonKey: const Key('training-start'),
        label: l10n.trainingStart,
        busy: state.save.running,
        onPressed: state.canStart ? _start : null,
        maxWidth: AppLayout.contentNarrow,
      ),
      children: [
        const AutoTrainingNote(),
        if (state.loading)
          const LoadingState.rows()
        else if (loadFailure != null)
          ErrorState(
            message: failureText(l10n, loadFailure),
            onRetry: ref.read(trainingSetupViewModelProvider.notifier).load,
            actionKey: const Key('training-setup-error-retry'),
          )
        else ...[
          if (problem != null)
            InlineError(problem, key: const Key('training-setup-error')),
          _GoalCard(state: state),
          _RideCard(state: state, hours: _hours),
          _HeartRateCard(
            state: state,
            maxHeartRate: _maxHeartRate,
            birthYear: _birthYear,
          ),
          Text(
            l10n.trainingHealthNote,
            key: const Key('training-health-note'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// 1 · Your goal: one row per goal, the suggested one selected with its reason and its badge.
class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.state});

  final TrainingSetupState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SectionCard(
      key: const Key('training-goal-card'),
      title: l10n.trainingGoalStep,
      children: [
        RadioGroup<String>(
          groupValue: state.goal,
          onChanged: (goal) {
            if (goal != null) {
              ref.read(trainingSetupViewModelProvider.notifier).setGoal(goal);
            }
          },
          child: Column(
            children: [
              for (final goal in trainingGoalIds)
                RadioListTile<String>(
                  key: Key('training-goal-$goal'),
                  value: goal,
                  contentPadding: EdgeInsets.zero,
                  title: Text(trainingGoalName(l10n, goal)),
                  subtitle: switch (_line(l10n, goal)) {
                    final line? => Text(line),
                    null => null,
                  },
                  secondary: goal == state.suggestedGoal
                      ? AppBadge(l10n.goalSuggested, tone: AppBadgeTone.good)
                      : null,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// The one line under a goal: the suggested goal's reason, or what the goal itself means.
  String? _line(AppLocalizations l10n, String goal) {
    if (goal == state.suggestedGoal) {
      return trainingSuggestionReason(l10n, state.suggestionReason ?? '');
    }
    if (goal == 'faster') return l10n.goalFasterLine;
    if (goal == 'event') {
      return state.nextEventName == null
          ? l10n.goalAddEvent
          : l10n.goalNextEvent(
              state.nextEventName!,
              DateFormat.MMMd(l10n.localeName).format(state.nextEventDate!),
            );
    }
    return null;
  }
}

/// 2 · When you ride: the free days as chips, the hours, and the long-ride day among those days.
class _RideCard extends ConsumerWidget {
  const _RideCard({required this.state, required this.hours});

  final TrainingSetupState state;
  final TextEditingController hours;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(trainingSetupViewModelProvider.notifier);
    final picked = defaultLongRideDay(state.days);
    final longRide =
        state.longRideDay != null && state.days.contains(state.longRideDay)
        ? state.longRideDay
        : null;
    final fields = (
      AppTextField(
        fieldKey: const Key('training-hours'),
        controller: hours,
        label: l10n.trainingHoursLabel,
        suffix: 'h',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 2,
        onDone: notifier.setHours,
      ),
      DropdownButtonFormField<String?>(
        key: Key(
          'training-long-ride-${longRide ?? 'picks'}-${state.days.length}',
        ),
        initialValue: longRide,
        isExpanded: true,
        decoration: InputDecoration(labelText: l10n.trainingLongRideLabel),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(
              picked == null
                  ? l10n.trainingLongRidePicks
                  : l10n.trainingLongRidePicksDay(weekDayName(l10n, picked)),
            ),
          ),
          for (final day in orderedDays(state.days))
            DropdownMenuItem<String?>(
              value: day,
              child: Text(weekDayName(l10n, day)),
            ),
        ],
        onChanged: notifier.setLongRideDay,
      ),
    );
    return SectionCard(
      key: const Key('training-ride-card'),
      title: l10n.trainingRideStep,
      children: [
        Text(
          l10n.trainingDaysLabel,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final day in trainingDayIds)
              FilterChip(
                key: Key('training-day-$day'),
                label: Text(trainingDayShort(l10n, day)),
                selected: state.days.contains(day),
                onSelected: (_) => notifier.toggleDay(day),
              ),
          ],
        ),
        _FieldPair(first: fields.$1, second: fields.$2),
      ],
    );
  }
}

/// 3 · Your heart rate: "I don't know" (on until a number was typed or measured), else the number, and the year
/// of birth when the account has none.
class _HeartRateCard extends ConsumerWidget {
  const _HeartRateCard({
    required this.state,
    required this.maxHeartRate,
    required this.birthYear,
  });

  final TrainingSetupState state;
  final TextEditingController maxHeartRate;
  final TextEditingController birthYear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(trainingSetupViewModelProvider.notifier);
    return SectionCard(
      key: const Key('training-heart-card'),
      title: l10n.trainingHeartStep,
      children: [
        SwitchListTile(
          key: const Key('training-heart-unknown'),
          contentPadding: EdgeInsets.zero,
          value: state.maxHeartRateUnknown,
          title: Text(l10n.trainingHeartUnknown),
          subtitle: Text(l10n.trainingHeartUnknownHelp),
          onChanged: notifier.setMaxHeartRateUnknown,
        ),
        if (!state.maxHeartRateUnknown)
          AppTextField(
            fieldKey: const Key('training-max-heart-rate'),
            controller: maxHeartRate,
            label: l10n.trainingMaxHeartRate,
            suffix: 'bpm',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 3,
            onDone: notifier.setMaxHeartRate,
          ),
        if (state.needsBirthYear)
          AppTextField(
            fieldKey: const Key('training-birth-year'),
            controller: birthYear,
            label: l10n.trainingBirthYear,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 4,
            onDone: notifier.setBirthYear,
          ),
      ],
    );
  }
}

/// Two short fields side by side from the tablet width, one under the other on a phone.
class _FieldPair extends StatelessWidget {
  const _FieldPair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoint.compactWidth;
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [first, second],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        Expanded(child: first),
        Expanded(child: second),
      ],
    );
  }
}
