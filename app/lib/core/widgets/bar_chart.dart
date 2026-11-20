import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../tokens.dart';
import 'chart_chrome.dart';
import 'empty_state.dart';
import 'nice_ticks.dart';

/// A total per period: rounded bars that fade toward the base, the current one in the accent and
/// only the current and the peak carrying a value.
class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.format,
    required this.semanticLabel,
    required this.emptyMessage,
    this.currentIndex,
    this.average,
    this.averageText,
    this.height = AppChart.height,
    this.paintKey,
  });

  final List<double> values;
  final List<String> labels;

  /// A value as it reads above its bar, in the same unit as [values].
  final String Function(double) format;

  /// What a screen reader hears instead of the drawing.
  final String semanticLabel;

  /// What a chart with nothing to show says, instead of empty axes.
  final String emptyMessage;

  /// The bar drawn in the accent; the last one by default.
  final int? currentIndex;

  /// A mean drawn across the bars as a dashed line, in the same unit as [values].
  final double? average;

  /// What the average line says beside it: "Average 45.3 km".
  final String? averageText;

  final double height;

  /// A key on the drawing, for a test that looks for it.
  final Key? paintKey;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty || values.every((value) => value <= 0)) {
      return EmptyState(framed: false, message: emptyMessage);
    }
    final scheme = Theme.of(context).colorScheme;
    final colors = VelomineColors.of(context);
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: CustomPaint(
            key: paintKey,
            size: Size.infinite,
            painter: _BarChartPainter(
              values: values,
              labels: labels,
              format: format,
              average: average,
              averageText: averageText,
              current: currentIndex ?? values.length - 1,
              compact:
                  MediaQuery.sizeOf(context).width < AppBreakpoint.compactWidth,
              bar: colors.barMuted,
              currentBar: colors.accentStrong,
              grid: scheme.outlineVariant,
              ink: scheme.onSurface,
              muted: scheme.onSurfaceVariant,
              labelStyle: chartLabelStyle(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.values,
    required this.labels,
    required this.format,
    required this.average,
    required this.averageText,
    required this.current,
    required this.compact,
    required this.bar,
    required this.currentBar,
    required this.grid,
    required this.ink,
    required this.muted,
    required this.labelStyle,
  });

  final List<double> values;
  final List<String> labels;
  final String Function(double) format;
  final double? average;
  final String? averageText;
  final int current;
  final bool compact;
  final Color bar;
  final Color currentBar;
  final Color grid;
  final Color ink;
  final Color muted;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      AppChart.gutterLeft,
      AppChart.valueLabelHeight,
      size.width,
      size.height - AppChart.dateLabelHeight,
    );
    if (plot.width <= 0 || plot.height <= 0) return;
    final max = values.reduce(math.max);
    final ticks = niceTicks(0, max);
    final top = ticks.last;
    final slot = plot.width / values.length;
    final barWidth = slot * AppChart.barFraction;
    final step = barLabelStep(slot: slot, compact: compact);
    final peak = values.lastIndexOf(max);

    for (final tick in ticks) {
      final y = plot.bottom - tick / top * plot.height;
      canvas.drawLine(
        Offset(plot.left, y),
        Offset(plot.right, y),
        Paint()
          ..color = grid
          ..strokeWidth = 1,
      );
      _text(canvas, _plain(tick), Offset(plot.left - 6, y - 8), right: true);
    }

    double barTop(int i) =>
        plot.bottom - math.max(values[i] / top * plot.height, 2);

    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value <= 0) continue;
      final rect = Rect.fromLTWH(
        plot.left + i * slot + (slot - barWidth) / 2,
        barTop(i),
        barWidth,
        plot.bottom - barTop(i),
      );
      final color = i == current ? currentBar : bar;
      canvas.drawPath(
        Path()..addRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: const Radius.circular(AppRadius.small),
            topRight: const Radius.circular(AppRadius.small),
          ),
        ),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, color.withValues(alpha: 0.55)],
          ).createShader(rect),
      );
      if ((values.length - 1 - i) % step == 0) {
        _text(
          canvas,
          labels[i],
          Offset(plot.left + i * slot + slot / 2, size.height - 14),
          centre: true,
        );
      }
    }

    // The mean, dashed and muted so it never reads as a bar.
    if (average case final average? when average > 0) {
      final y = plot.bottom - math.min(average / top, 1) * plot.height;
      _dashedLine(canvas, plot.left, plot.right, y, muted);
      final text = averageText;
      if (text != null) {
        _text(
          canvas,
          text,
          Offset(plot.right - AppSpacing.sm, y - AppChart.valueLabelHeight),
          right: true,
        );
      }
    }

    // The current period always says its value; the peak says its own unless the two are one bar or
    // the labels would run into each other.
    final currentLabel = _label(format(values[current]));
    Offset centred(TextPainter label, int index) => Offset(
      // A label wider than its slot stays inside the plot instead of running off the edge.
      (plot.left + index * slot + slot / 2 - label.width / 2).clamp(
        plot.left,
        math.max(plot.left, plot.right - label.width),
      ),
      barTop(index) - AppChart.valueLabelHeight,
    );
    final currentAt = centred(currentLabel, current);
    currentLabel.paint(canvas, currentAt);
    if (peak != current) {
      final peakLabel = _label(format(values[peak]), color: muted);
      final peakAt = centred(peakLabel, peak);
      if (!(peakAt & peakLabel.size).overlaps(currentAt & currentLabel.size)) {
        peakLabel.paint(canvas, peakAt);
      }
    }
  }

  /// A line drawn in dashes, so it reads as a reference and not as another series.
  void _dashedLine(
    Canvas canvas,
    double from,
    double to,
    double y,
    Color color,
  ) {
    const dash = 6.0, gap = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    var x = from;
    while (x < to) {
      final end = math.min(x + dash, to);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x = end + gap;
    }
  }

  TextPainter _label(String text, {Color? color}) => TextPainter(
    text: TextSpan(
      text: text,
      style: labelStyle.copyWith(
        color: color ?? ink,
        fontWeight: FontWeight.w600,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  /// A tick as it reads: whole numbers where it can, so 40 is "40" and not "40.0".
  String _plain(double value) =>
      value == value.roundToDouble() ? value.round().toString() : '$value';

  void _text(
    Canvas canvas,
    String text,
    Offset at, {
    bool right = false,
    bool centre = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        right
            ? at.dx - painter.width
            : centre
            ? at.dx - painter.width / 2
            : at.dx,
        at.dy,
      ),
    );
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.values != values ||
      old.average != average ||
      old.averageText != averageText ||
      old.labels != labels ||
      old.current != current ||
      old.compact != compact ||
      old.bar != bar ||
      old.currentBar != currentBar ||
      old.grid != grid ||
      old.ink != ink ||
      old.labelStyle != labelStyle;
}
