import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';

/// Load over a date range: totals, the daily TSS bars, and fitness/fatigue/form over time.
class TrainingSummary extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final colors = [
      scheme.primary,
      const Color(0xFFE07A3F),
      const Color(0xFF8E44AD),
    ];
    final labelStyle = (text.labelSmall ?? const TextStyle(fontSize: 11))
        .copyWith(color: scheme.onSurfaceVariant);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.trainingLoad, style: text.titleMedium),
                ),
                SegmentedButton<int>(
                  key: const Key('training-range'),
                  segments: [
                    ButtonSegment(value: 30, label: Text(l10n.range30Days)),
                    ButtonSegment(value: 90, label: Text(l10n.range90Days)),
                    ButtonSegment(value: 365, label: Text(l10n.rangeOneYear)),
                  ],
                  selected: {days},
                  onSelectionChanged: (selection) => onDays(selection.single),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _Value(
                  label: 'TSS',
                  value: training.tss.round().toString(),
                  valueKey: const Key('training-tss'),
                ),
                _Value(
                  label: 'TRIMP',
                  value: training.trimp.round().toString(),
                  valueKey: const Key('training-trimp'),
                ),
                _Value(
                  label: l10n.statRides,
                  value: training.rides.toString(),
                  valueKey: const Key('training-rides'),
                ),
                _Value(
                  label: l10n.statDistance,
                  value: km(training.distanceM),
                  valueKey: const Key('training-distance'),
                ),
              ],
            ),
            if (training.tss == 0 && training.rides > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.trainingLoadHint,
                  key: const Key('training-hint'),
                  style: text.bodySmall,
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(l10n.fitnessFatigueForm, style: text.titleSmall),
                ),
                Text(
                  '${DateFormat.MMMd().format(training.from)} – '
                  '${DateFormat.MMMd().format(training.to)}',
                  style: text.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              spacing: 16,
              children: [
                _LegendDot(color: colors[0], label: l10n.fitness),
                _LegendDot(color: colors[1], label: l10n.fatigue),
                _LegendDot(color: colors[2], label: l10n.form),
              ],
            ),
            const SizedBox(height: 6),
            Semantics(
              label: l10n.fitnessSemantics(
                training.days.isEmpty ? 0 : training.days.last.fitness.round(),
                training.days.isEmpty ? 0 : training.days.last.fatigue.round(),
                training.days.isEmpty ? 0 : training.days.last.form.round(),
              ),
              child: SizedBox(
                height: 170,
                child: CustomPaint(
                  key: const Key('fitness-chart'),
                  size: Size.infinite,
                  painter: _FitnessPainter(
                    days: training.days,
                    grid: scheme.outlineVariant,
                    labelStyle: labelStyle,
                    colors: colors,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.dailyLoad, style: text.titleSmall),
            const SizedBox(height: 6),
            Semantics(
              label: l10n.dailyLoadSemantics(training.dayCount),
              child: SizedBox(
                height: 120,
                child: CustomPaint(
                  key: const Key('tss-chart'),
                  size: Size.infinite,
                  painter: _LoadPainter(
                    days: training.days,
                    bar: scheme.primary.withValues(alpha: 0.55),
                    peak: scheme.primary,
                    labelStyle: labelStyle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(l10n.trainingLoadHelp, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value, this.valueKey});

  final String label;
  final String value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(
          value,
          key: valueKey,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _FitnessPainter extends CustomPainter {
  _FitnessPainter({
    required this.days,
    required this.grid,
    required this.labelStyle,
    required this.colors,
  });

  final List<TrainingDay> days;
  final Color grid;
  final TextStyle labelStyle;
  final List<Color> colors;

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

    final line = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final value in [min, (min + max) / 2, max]) {
      canvas.drawLine(
        Offset(plot.left, y(value)),
        Offset(plot.right, y(value)),
        line,
      );
      _label(
        canvas,
        value.round().toString(),
        Offset(plot.left - 4, y(value)),
        alignRight: true,
        centerY: true,
      );
    }
    if (min < 0 && max > 0) {
      canvas.drawLine(
        Offset(plot.left, y(0)),
        Offset(plot.right, y(0)),
        Paint()
          ..color = grid
          ..strokeWidth = 1.5,
      );
    }

    void draw(double Function(TrainingDay day) pick, Color color) {
      final path = Path();
      for (var i = 0; i < days.length; i++) {
        final point = Offset(x(i), y(pick(days[i])));
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeJoin = StrokeJoin.round,
      );
    }

    draw((day) => day.form, colors[2]);
    draw((day) => day.fatigue, colors[1]);
    draw((day) => day.fitness, colors[0]);

    for (final index in [0, days.length ~/ 2, days.length - 1]) {
      _label(
        canvas,
        DateFormat.MMMd().format(days[index].date),
        Offset(x(index), plot.bottom + 3),
        alignRight: false,
        centerY: false,
        centerX: true,
      );
    }
  }

  void _label(
    Canvas canvas,
    String text,
    Offset at, {
    required bool alignRight,
    required bool centerY,
    bool centerX = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
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
      old.colors != colors;
}

class _LoadPainter extends CustomPainter {
  _LoadPainter({
    required this.days,
    required this.bar,
    required this.peak,
    required this.labelStyle,
  });

  final List<TrainingDay> days;
  final Color bar;
  final Color peak;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;
    const labelHeight = 16.0;
    final top = days.fold<double>(0, (m, day) => math.max(m, day.tss));
    final slot = size.width / days.length;
    final chartHeight = size.height - labelHeight;
    final every = (60 / slot).ceil().clamp(1, days.length);

    for (var i = 0; i < days.length; i++) {
      final value = days[i].tss;
      if (value > 0) {
        final height = top <= 0 ? 0.0 : value / top * chartHeight;
        final rect = Rect.fromLTWH(
          i * slot + slot * 0.15,
          chartHeight - height,
          math.max(slot * 0.7, 1),
          math.max(height, 2),
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: const Radius.circular(2),
            topRight: const Radius.circular(2),
          ),
          Paint()..color = value == top ? peak : bar,
        );
      }
      if ((days.length - 1 - i) % every == 0) {
        final painter = TextPainter(
          text: TextSpan(
            text: DateFormat.MMMd().format(days[i].date),
            style: labelStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(
          canvas,
          Offset(
            i * slot + slot / 2 - painter.width / 2,
            size.height - labelHeight + 2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LoadPainter old) =>
      old.days != days ||
      old.bar != bar ||
      old.peak != peak ||
      old.labelStyle != labelStyle;
}
