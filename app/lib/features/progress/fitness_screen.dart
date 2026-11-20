import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/widgets/card_grid.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/heart_rate_note_card.dart';
import '../../core/widgets/page_scaffold.dart';
import 'efficiency_card.dart';
import 'intensity_card.dart';
import 'progress_tabs.dart';
import 'progress_view_models.dart';
import 'training_summary.dart';

/// Progress → Fitness answers "Is my fitness going up?": one chart of fitness, fatigue and form, and
/// under it what drives them.
class FitnessScreen extends ConsumerWidget {
  const FitnessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filters = ref.watch(progressFiltersViewModelProvider);
    final training = ref.watch(trainingViewModelProvider);
    final heartRate = ref.watch(heartRateSuggestionViewModelProvider);
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoint.compactWidth;
    final failure = training.load.failure;

    return PageScaffold(
      title: l10n.fitness,
      parent: wide ? l10n.navProgress : null,
      children: [
        // Under 600 dp the sub-pages are tabs; from there the shell and the caption carry them.
        if (!wide) ProgressTabs(location: '/progress/fitness'),
        if (failure != null)
          ErrorState(
            message: failureText(l10n, failure),
            onRetry: ref.read(trainingViewModelProvider.notifier).load,
            actionKey: const Key('fitness-error'),
          ),
        // A heart-rate number a ride beat is a question about the numbers below, answered here.
        for (final suggestion in heartRate.suggestions)
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
        if (training.load.value case final data?) ...[
          // The chart on its own, then what drives it: daily load beside the intensity split, and the
          // load's totals beside the efficiency, as the mock-up draws them.
          TrainingSummary(
            training: data,
            days: filters.trainingDays,
            onDays: (days) async => ref
                .read(progressFiltersViewModelProvider.notifier)
                .setTrainingDays(days),
          ),
          CardGrid(
            columns: 3,
            tabletColumns: 2,
            hero: 2,
            children: [
              DailyLoadCard(training: data),
              if (data.intensity case final intensity?)
                IntensityCard(intensity: intensity, weeks: data.intensityWeeks),
            ],
          ),
          CardGrid(
            columns: 2,
            tabletColumns: 2,
            children: [
              TrainingLoadCard(training: data),
              EfficiencyCard(weeks: data.efficiency),
            ],
          ),
        ],
      ],
    );
  }
}
