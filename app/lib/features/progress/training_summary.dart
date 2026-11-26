import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/units.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bar_chart.dart';
import '../../core/widgets/line_chart.dart';
import '../../core/widgets/range_selector.dart';
import '../../core/widgets/source_note.dart';
import '../../core/widgets/stat_card.dart';

/// Load over a date range: fitness, fatigue and form, the totals behind them and the daily TSS.
class TrainingSummary extends ConsumerWidget {
  const TrainingSummary({
    super.key,
    required this.training,
    required this.days,
    required this.onDays,
  });

  final TrainingResponse training;
  final int days;
  final Future<void> Function(int days) onDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final palette = VelomineColors.of(context);
    final fitnessColor = palette.accentStrong;
    final fatigueColor = palette.series['power']!;
    // One sentence, and only what the chart already shows: the last fitness value against the first.
    final trend = training.days.length < 2
        ? null
        : training.days.last.fitness > training.days.first.fitness
        ? l10n.fitnessTrendRising
        : training.days.last.fitness < training.days.first.fitness
        ? l10n.fitnessTrendFalling
        : null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RangeSelector<int>(
            title: l10n.fitnessFatigueForm,
            segmentKey: const Key('training-range'),
            segments: [
              ButtonSegment(value: 30, label: Text(l10n.range30Days)),
              ButtonSegment(value: 90, label: Text(l10n.range90Days)),
              ButtonSegment(value: 365, label: Text(l10n.rangeOneYear)),
            ],
            selected: days,
            onChanged: onDays,
          ),
          // A caution, not a fault: the week was the same every day, or much heavier than usual.
          if (training.monotonous.orElse(false) ?? false)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: _CautionNote(
                l10n.trainingMonotonous,
                key: const Key('training-monotonous'),
              ),
            ),
          if (training.heavyWeek.orElse(false) ?? false)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: _CautionNote(
                l10n.trainingHeavyWeek,
                key: const Key('training-heavy-week'),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          // The range control above already names the chart; this row says the colours and the dates.
          // One wrap, so a phone puts the dates on their own line instead of running "Form" into
          // "Fatigue".
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _LegendDot(color: fitnessColor, label: l10n.fitness),
              _LegendDot(color: fatigueColor, label: l10n.fatigue),
              _LegendDot(
                color: fitnessColor,
                below: palette.signal,
                label: l10n.form,
              ),
              Text(
                '${DateFormat.MMMd(locale).format(training.from)} – '
                '${DateFormat.MMMd(locale).format(training.to)}',
                style: text.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: l10n.fitnessSemantics(
              training.days.isEmpty ? 0 : training.days.last.fitness.round(),
              training.days.isEmpty ? 0 : training.days.last.fatigue.round(),
              training.days.isEmpty ? 0 : training.days.last.form.round(),
            ),
            child: ExcludeSemantics(
              child: FitnessChart(
                paintKey: const Key('fitness-chart'),
                labels: [
                  for (final day in training.days)
                    DateFormat.MMMd(locale).format(day.date),
                ],
                fitness: [for (final day in training.days) day.fitness],
                fatigue: [for (final day in training.days) day.fatigue],
                form: [for (final day in training.days) day.form],
                // A range with one day or none is said in words, not drawn as bare axes.
                emptyMessage: l10n.dailyLoadEmpty,
              ),
            ),
          ),
          if (trend != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                trend,
                key: const Key('fitness-trend'),
                style: text.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

/// Load over the range: TSS, TRIMP, rides and distance, with the hint when TSS could not be counted.
class TrainingLoadCard extends ConsumerWidget {
  const TrainingLoadCard({super.key, required this.training});

  final TrainingResponse training;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final l10n = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.trainingLoad, style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: 8,
            children: [
              StatFigure(
                label: 'TSS',
                value: training.tss.round().toString(),
                valueKey: const Key('training-tss'),
              ),
              StatFigure(
                label: l10n.statTrimp,
                value: training.trimp.round().toString(),
                valueKey: const Key('training-trimp'),
              ),
              StatFigure(
                label: l10n.statRides,
                value: training.rides.toString(),
                valueKey: const Key('training-rides'),
              ),
              StatFigure(
                label: l10n.statDistance,
                value: km(
                  ref.watch(unitsChoiceViewModelProvider),
                  training.distanceM,
                ),
                valueKey: const Key('training-distance'),
              ),
            ],
          ),
          // TRIMP is Edwards' zone-weighted score; name the method where the number is shown.
          if (training.trimp > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: SourceNote(
                l10n.trimpHelp,
                key: const Key('training-trimp-note'),
              ),
            ),
          // Some rides in the range had no power: their effort came from heart rate.
          if ((training.heartRateLoadRides.orElse(0) ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: SourceNote(
                l10n.fitnessHeartRateLoad,
                key: const Key('fitness-heart-rate-note'),
              ),
            ),
          if (training.tss == 0 && training.rides > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                l10n.trainingLoadHint,
                key: const Key('training-hint'),
                style: text.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

/// The daily training load as bars, the latest in the accent colour.
class DailyLoadCard extends StatelessWidget {
  const DailyLoadCard({super.key, required this.training});

  final TrainingResponse training;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dailyLoad, style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          BarChart(
            paintKey: const Key('tss-chart'),
            values: [for (final day in training.days) day.tss],
            labels: [
              for (final day in training.days)
                DateFormat.MMMd(locale).format(day.date),
            ],
            format: (value) => value.round().toString(),
            semanticLabel: l10n.dailyLoadSemantics(training.dayCount),
            emptyMessage: l10n.dailyLoadEmpty,
            currentIndex: training.days.length - 1,
            height: AppProgress.loadChartHeight,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.trainingLoadHelp, style: text.bodySmall),
          if (training.monotony.orElse(null) case final monotony?)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                l10n.trainingStrain(
                  NumberFormat('0.00').format(monotony),
                  NumberFormat('0').format(training.strain.orElse(0) ?? 0),
                ),
                key: const Key('training-strain'),
                style: text.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label, this.below});

  final Color color;

  /// The colour of the same series on the other side of the zero line, for bars that change with it.
  final Color? below;
  final String label;

  @override
  Widget build(BuildContext context) {
    final below = this.below;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppChart.legendDotSmall,
          height: AppChart.legendDotSmall,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            // A two-tone series shows both of its colours, top to bottom.
            gradient: below == null
                ? null
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color, below],
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _CautionNote extends StatelessWidget {
  const _CautionNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.tertiary;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.info_outline,
              size: AppLoading.errorIcon,
              color: color,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
