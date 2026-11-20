import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/units.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bar_chart.dart';
import '../../core/widgets/chart_chrome.dart';
import '../../core/widgets/nice_ticks.dart';
import '../../core/widgets/range_selector.dart';
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
          const SizedBox(height: AppSpacing.md),
          // The range control above already names the chart; this row says the dates and the colours.
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: 6,
                  children: [
                    _LegendDot(color: fitnessColor, label: l10n.fitness),
                    _LegendDot(color: fatigueColor, label: l10n.fatigue),
                    _LegendDot(
                      color: fitnessColor,
                      below: palette.signal,
                      label: l10n.form,
                    ),
                  ],
                ),
              ),
              // Twice the text does not fit beside the legend; it wraps instead of overflowing.
              Flexible(
                child: Text(
                  '${DateFormat.MMMd(locale).format(training.from)} – '
                  '${DateFormat.MMMd(locale).format(training.to)}',
                  style: text.labelSmall,
                  textAlign: TextAlign.end,
                ),
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
            child: SizedBox(
              height: AppProgress.fitnessChartHeight,
              child: CustomPaint(
                key: const Key('fitness-chart'),
                size: Size.infinite,
                painter: _FitnessPainter(
                  days: training.days,
                  grid: Theme.of(context).colorScheme.outlineVariant,
                  labelStyle: chartLabelStyle(context),
                  ink: Theme.of(context).colorScheme.onSurface,
                  muted: Theme.of(context).colorScheme.onSurfaceVariant,
                  fitness: fitnessColor,
                  fatigue: fatigueColor,
                  formAbove: palette.accentStrong,
                  formBelow: palette.signal,
                  locale: locale,
                ),
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
                label: 'TRIMP',
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
            height: AppProgress.loadChartHeight,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.trainingLoadHelp, style: text.bodySmall),
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
          width: 9,
          height: 9,
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
        Flexible(
          child: Text(label, style: Theme.of(context).textTheme.labelSmall),
        ),
      ],
    );
  }
}

/// Fitness as a line with a fading area, fatigue as a dashed line, and form as bars round a zero line.
class _FitnessPainter extends CustomPainter {
  _FitnessPainter({
    required this.days,
    required this.grid,
    required this.labelStyle,
    required this.ink,
    required this.muted,
    required this.fitness,
    required this.fatigue,
    required this.formAbove,
    required this.formBelow,
    required this.locale,
  });

  final List<TrainingDay> days;
  final Color grid;
  final TextStyle labelStyle;
  final Color ink;
  final Color muted;
  final Color fitness;
  final Color fatigue;
  final Color formAbove;
  final Color formBelow;
  final String locale;

  static const _left = 34.0, _right = 8.0, _top = 8.0, _bottom = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (days.length < 2) return;
    final plot = Rect.fromLTRB(
      _left,
      _top,
      size.width - _right,
      size.height - _bottom,
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    var min = 0.0, max = 0.0;
    for (final day in days) {
      for (final value in [day.fitness, day.fatigue, day.form]) {
        min = math.min(min, value);
        max = math.max(max, value);
      }
    }
    if (max <= min) max = min + 1;

    double x(int index) => plot.left + index / (days.length - 1) * plot.width;
    double y(double value) =>
        plot.bottom - (value - min) / (max - min) * plot.height;

    final hairline = Paint()
      ..color = grid
      ..strokeWidth = 1;
    final ticks = niceTicks(min, max);
    for (final tick in ticks) {
      canvas.drawLine(
        Offset(plot.left, y(tick)),
        Offset(plot.right, y(tick)),
        hairline,
      );
      _label(
        canvas,
        tick.round().toString(),
        Offset(plot.left - 4, y(tick)),
        alignRight: true,
        centerY: true,
      );
    }

    final zero = y(0);
    canvas.drawLine(
      Offset(plot.left, zero),
      Offset(plot.right, zero),
      Paint()
        ..color = grid
        ..strokeWidth = 1.5,
    );

    // Form: bars hanging off the zero line, up in the accent and down in the signal colour.
    final slot = plot.width / days.length;
    final barWidth = slot * 0.5;
    for (var i = 0; i < days.length; i++) {
      final value = days[i].form;
      if (value == 0) continue;
      final top = math.min(y(value), zero);
      final height = math.max((y(value) - zero).abs(), 1.0);
      final rect = Rect.fromLTWH(
        plot.left + i * slot + (slot - barWidth) / 2,
        top,
        barWidth,
        height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(AppRadius.small)),
        Paint()
          ..color = (value > 0 ? formAbove : formBelow).withValues(alpha: 0.55),
      );
    }

    Path line(double Function(TrainingDay day) pick) {
      final path = Path();
      for (var i = 0; i < days.length; i++) {
        final point = Offset(x(i), y(pick(days[i])));
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      return path;
    }

    // Fitness: the line with a fading area under it.
    final fitnessPath = line((day) => day.fitness);
    final area = Path.from(fitnessPath)
      ..lineTo(plot.right, plot.bottom)
      ..lineTo(plot.left, plot.bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            fitness.withValues(alpha: 0.35),
            fitness.withValues(alpha: 0),
          ],
        ).createShader(plot),
    );
    canvas.drawPath(
      fitnessPath,
      Paint()
        ..color = fitness
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    // Fatigue: dashed, so the eye never mistakes it for fitness.
    _drawDashed(
      canvas,
      line((day) => day.fatigue),
      Paint()
        ..color = fatigue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );

    // The two lines say their latest number beside their last point.
    _label(
      canvas,
      days.last.fitness.round().toString(),
      Offset(plot.right, y(days.last.fitness) - 14),
      alignRight: true,
      centerY: true,
      color: fitness,
    );
    _label(
      canvas,
      days.last.fatigue.round().toString(),
      Offset(plot.right, y(days.last.fatigue) + 2),
      alignRight: true,
      centerY: true,
      color: fatigue,
    );
    canvas.drawCircle(
      Offset(plot.right, y(days.last.fitness)),
      3,
      Paint()..color = ink,
    );

    for (final index in [0, days.length ~/ 2, days.length - 1]) {
      _label(
        canvas,
        DateFormat.MMMd(locale).format(days[index].date),
        Offset(x(index), plot.bottom + 3),
        alignRight: false,
        centerY: false,
        centerX: true,
      );
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dash = 5.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  void _label(
    Canvas canvas,
    String text,
    Offset at, {
    required bool alignRight,
    required bool centerY,
    bool centerX = false,
    Color? color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: color == null ? labelStyle : labelStyle.copyWith(color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignRight
        ? at.dx - painter.width
        : (centerX ? at.dx - painter.width / 2 : at.dx);
    painter.paint(
      canvas,
      Offset(dx, centerY ? at.dy - painter.height / 2 : at.dy),
    );
  }

  @override
  bool shouldRepaint(_FitnessPainter old) =>
      old.days != days ||
      old.grid != grid ||
      old.labelStyle != labelStyle ||
      old.fitness != fitness ||
      old.fatigue != fatigue ||
      old.locale != locale;
}
