import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../tokens.dart';
import 'chart_chrome.dart';
import 'empty_state.dart';
import 'nice_ticks.dart';

/// One value over time: a line with a fading area under it, its latest point marked with its value.
class AreaChart extends StatelessWidget {
  const AreaChart({
    super.key,
    required this.values,
    required this.labels,
    required this.format,
    required this.semanticLabel,
    required this.emptyMessage,
    this.color,
    this.height = AppChart.height,
    this.paintKey,
  });

  final List<double> values;
  final List<String> labels;

  /// A value as it reads beside the latest point, in the same unit as [values].
  final String Function(double) format;

  /// What a screen reader hears instead of the drawing.
  final String semanticLabel;

  /// What a chart with nothing to show says, instead of empty axes.
  final String emptyMessage;

  /// The line's colour: the accent unless a ride signal is shown.
  final Color? color;

  final double height;

  /// A key on the drawing, for a test that looks for it.
  final Key? paintKey;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return EmptyState(framed: false, message: emptyMessage);
    final scheme = Theme.of(context).colorScheme;
    final line = color ?? VelomineColors.of(context).accentStrong;
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: CustomPaint(
            key: paintKey,
            size: Size.infinite,
            painter: _AreaChartPainter(
              values: values,
              labels: labels,
              format: format,
              compact:
                  MediaQuery.sizeOf(context).width < AppBreakpoint.compactWidth,
              line: line,
              grid: scheme.outlineVariant,
              ink: scheme.onSurface,
              card: scheme.surfaceContainer,
              muted: scheme.onSurfaceVariant,
              labelStyle: chartLabelStyle(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  _AreaChartPainter({
    required this.values,
    required this.labels,
    required this.format,
    required this.compact,
    required this.line,
    required this.grid,
    required this.ink,
    required this.card,
    required this.muted,
    required this.labelStyle,
  });

  final List<double> values;
  final List<String> labels;
  final String Function(double) format;
  final bool compact;
  final Color line;
  final Color grid;
  final Color ink;
  final Color card;
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

    // A flat run fills the middle of the box instead of sitting on the bottom edge.
    var min = values.reduce(math.min);
    var max = values.reduce(math.max);
    if (max - min < 1e-9) {
      final pad = math.max(max.abs() * 0.1, 0.1);
      min -= pad;
      max += pad;
    }
    final ticks = niceTicks(min, max);
    final low = ticks.first;
    final high = ticks.last;
    double y(double value) =>
        plot.bottom - (value - low) / (high - low) * plot.height;
    double x(int index) => values.length == 1
        ? plot.center.dx
        : plot.left + index / (values.length - 1) * plot.width;

    for (final tick in ticks) {
      final at = y(tick);
      canvas.drawLine(
        Offset(plot.left, at),
        Offset(plot.right, at),
        Paint()
          ..color = grid
          ..strokeWidth = 1,
      );
      _text(canvas, format(tick), Offset(plot.left - 6, at - 8), right: true);
    }

    final points = [
      for (var i = 0; i < values.length; i++) Offset(x(i), y(values[i])),
    ];
    if (points.length > 1) {
      final area = Path()..moveTo(points.first.dx, plot.bottom);
      for (final point in points) {
        area.lineTo(point.dx, point.dy);
      }
      area
        ..lineTo(points.last.dx, plot.bottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [line.withValues(alpha: 0.35), line.withValues(alpha: 0)],
          ).createShader(plot),
      );
      canvas.drawPath(
        Path()..addPolygon(points, false),
        Paint()
          ..color = line
          ..strokeWidth = AppChart.lineWidth
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    // Fewer dates when the points crowd together; the newest one always has one.
    final step = barLabelStep(
      slot: plot.width / values.length,
      compact: compact,
    );
    for (var i = 0; i < values.length; i++) {
      if ((values.length - 1 - i) % step == 0) {
        _text(canvas, labels[i], Offset(x(i), size.height - 14), centre: true);
      }
    }

    final last = points.last;
    canvas.drawCircle(last, AppChart.dotRadius, Paint()..color = line);
    canvas.drawCircle(
      last,
      AppChart.dotRadius,
      Paint()
        ..color = card
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    _text(
      canvas,
      format(values.last),
      Offset(last.dx - 2, math.max(last.dy - AppChart.valueLabelHeight - 4, 0)),
      right: true,
      color: ink,
    );
  }

  void _text(
    Canvas canvas,
    String text,
    Offset at, {
    bool right = false,
    bool centre = false,
    Color? color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: color == null
            ? labelStyle
            : labelStyle.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
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
  bool shouldRepaint(_AreaChartPainter old) =>
      old.values != values ||
      old.labels != labels ||
      old.compact != compact ||
      old.line != line ||
      old.grid != grid ||
      old.ink != ink ||
      old.card != card ||
      old.labelStyle != labelStyle;
}
