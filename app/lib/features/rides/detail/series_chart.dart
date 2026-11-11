import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/chart_chrome.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'lap_range.dart';
import 'ride_series.dart';
import 'scale.dart';
import '../../../core/tokens.dart';

/// The name of a signal in the language on screen. The id is what the ride file gave it.
String seriesName(AppLocalizations l10n, Series series) => switch (series.id) {
  'elevation' => l10n.seriesElevation,
  'speed' => l10n.seriesSpeed,
  'power' => l10n.seriesPower,
  'heartrate' => l10n.seriesHeartRate,
  'cadence' => l10n.seriesCadence,
  _ => series.name,
};

/// A line chart of one signal against time. Hovering or touching it selects a moment, shared with the other charts
/// and the map through [selected] (an index into the ride's samples).
class SeriesChart extends StatelessWidget {
  const SeriesChart({
    super.key,
    required this.series,
    required this.time,
    required this.selected,
    required this.selectedLap,
    required this.color,
  });

  final Series series;
  final List<double> time;
  final ValueNotifier<int?> selected;
  final ValueNotifier<LapRange?> selectedLap;
  final Color color;

  static const double height = 130;
  static const double _left = 46, _right = 10, _top = 6, _bottom = 20;

  void _select(double dx, double width) {
    final plot = width - _left - _right;
    if (plot <= 0 || time.isEmpty) return;
    final fraction = ((dx - _left) / plot).clamp(0.0, 1.0);
    final t = time.first + fraction * (time.last - time.first);
    selected.value = nearestIndex(time, t);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = seriesName(l10n, series);
    return Semantics(
      label: l10n.chartSemantics(
        name,
        series.format(series.min),
        series.format(series.average),
        series.format(series.max),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<int?>(
            valueListenable: selected,
            builder: (_, index, _) => ChartHeader(
              title: name,
              color: color,
              readoutKey: Key('readout-${series.id}'),
              readout: index == null
                  ? l10n.chartAverageMax(
                      series.format(series.average),
                      series.format(series.max),
                    )
                  : series.format(series.values[index]),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: height,
            child: LayoutBuilder(
              builder: (context, box) => MouseRegion(
                onHover: (e) => _select(e.localPosition.dx, box.maxWidth),
                onExit: (_) => selected.value = null,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _select(d.localPosition.dx, box.maxWidth),
                  onHorizontalDragUpdate: (d) =>
                      _select(d.localPosition.dx, box.maxWidth),
                  child: CustomPaint(
                    key: Key('chart-${series.id}'),
                    size: Size(box.maxWidth, height),
                    painter: _ChartPainter(
                      series: series,
                      time: time,
                      selected: selected,
                      selectedLap: selectedLap,
                      color: color,
                      textStyle: chartLabelStyle(context),
                      gridColor: Theme.of(context).colorScheme.outlineVariant,
                      background: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.series,
    required this.time,
    required this.selected,
    required this.selectedLap,
    required this.color,
    required this.textStyle,
    required this.gridColor,
    required this.background,
  }) : super(repaint: Listenable.merge([selected, selectedLap]));

  final Series series;
  final List<double> time;
  final ValueNotifier<int?> selected;
  final ValueNotifier<LapRange?> selectedLap;
  final Color color;
  final TextStyle textStyle;
  final Color gridColor;

  /// The ring around the selected point, so it stands out from the line.
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      SeriesChart._left,
      SeriesChart._top,
      size.width - SeriesChart._right,
      size.height - SeriesChart._bottom,
    );
    if (plot.width <= 0 || time.length < 2) return;

    final scale = niceScale(series.min, series.max);
    final t0 = time.first, t1 = time.last;
    double x(double t) => plot.left + (t - t0) / (t1 - t0) * plot.width;
    double y(double v) =>
        plot.bottom - (v - scale.min) / (scale.max - scale.min) * plot.height;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final tick in scale.ticks) {
      canvas.drawLine(
        Offset(plot.left, y(tick)),
        Offset(plot.right, y(tick)),
        grid,
      );
      _label(
        canvas,
        _number(tick, scale.step),
        Offset(plot.left - 6, y(tick)),
        alignRight: true,
        centerY: true,
      );
    }
    for (final t in timeTicks(t1 - t0)) {
      _label(
        canvas,
        timeLabel(t, hours: t1 - t0 >= 3600),
        Offset(x(t0 + t), plot.bottom + 4),
        alignRight: false,
        centerY: false,
        centerX: true,
      );
    }

    // The selected lap, shaded behind the line.
    final lap = selectedLap.value;
    if (lap != null) {
      final left = x(lap.startS.clamp(t0, t1));
      final right = x(lap.endS.clamp(t0, t1));
      canvas.drawRect(
        Rect.fromLTRB(left, plot.top, right, plot.bottom),
        Paint()..color = color.withValues(alpha: 0.1),
      );
    }

    // The line, broken where the file has no value, with a soft fill underneath.
    final line = Path();
    final fill = Path();
    var open = false;
    double? lastX;
    for (var i = 0; i < time.length; i++) {
      final v = series.values[i];
      if (v == null) {
        if (open && lastX != null) fill.lineTo(lastX, plot.bottom);
        open = false;
        continue;
      }
      final px = x(time[i]), py = y(v);
      if (!open) {
        line.moveTo(px, py);
        fill.moveTo(px, plot.bottom);
        fill.lineTo(px, py);
        open = true;
      } else {
        line.lineTo(px, py);
        fill.lineTo(px, py);
      }
      lastX = px;
    }
    if (open && lastX != null) fill.lineTo(lastX, plot.bottom);
    canvas.save();
    canvas.clipRect(plot.inflate(1));
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.12));
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    final index = selected.value;
    if (index != null && index < time.length) {
      final px = x(time[index]);
      canvas.drawLine(
        Offset(px, plot.top),
        Offset(px, plot.bottom),
        Paint()
          ..color = color.withValues(alpha: 0.7)
          ..strokeWidth = 1,
      );
      final v = series.values[index];
      if (v != null) {
        canvas.drawCircle(Offset(px, y(v)), 4.5, Paint()..color = background);
        canvas.drawCircle(Offset(px, y(v)), 3.2, Paint()..color = color);
      }
    }
  }

  String _number(double v, double step) => step >= 1 || v == v.roundToDouble()
      ? v.round().toString()
      : v.toStringAsFixed(1);

  void _label(
    Canvas canvas,
    String text,
    Offset at, {
    required bool alignRight,
    required bool centerY,
    bool centerX = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
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
  bool shouldRepaint(_ChartPainter old) =>
      old.series != series ||
      old.time != time ||
      old.color != color ||
      old.selectedLap != selectedLap ||
      old.background != background ||
      old.gridColor != gridColor ||
      old.textStyle != textStyle;
}
