import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart' as fl;
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../theme.dart';
import '../tokens.dart';
import 'chart_chrome.dart';
import 'empty_state.dart';
import 'nice_ticks.dart';

// The line charts the screens draw with fl_chart, kept in core/widgets/ so no feature imports the
// library (`AGENTS.md`, *App*). Every colour, label and style the design fixes is passed in, because
// fl_chart's own theme is Flutter-Material's fallback and not Velomine's.

/// Fitness as a line with a fading area, fatigue as a dashed line, and form as bars round a zero line.
///
/// The bars are `fl_chart` line segments standing on the zero line: they share the lines' x axis
/// exactly, which two stacked charts could not.
class FitnessChart extends StatelessWidget {
  const FitnessChart({
    super.key,
    required this.labels,
    required this.fitness,
    required this.fatigue,
    required this.form,
    required this.emptyMessage,
    this.height = AppProgress.fitnessChartHeight,
    this.paintKey,
  });

  /// One x label per day, in the same order as the three series.
  final List<String> labels;
  final List<double> fitness;
  final List<double> fatigue;

  /// The form per day: bars above zero when it is positive, below it when negative.
  final List<double> form;

  /// What fewer than two days says, instead of bare axes.
  final String emptyMessage;

  final double height;

  /// A key on the drawing, for a test that looks for it.
  final Key? paintKey;

  @override
  Widget build(BuildContext context) {
    if (fitness.length < 2) {
      return EmptyState(framed: false, message: emptyMessage);
    }
    final scheme = Theme.of(context).colorScheme;
    final colors = VelomineColors.of(context);
    final axis = chartLabelStyle(context);
    final fatigueColor = colors.series['power']!;
    final compact =
        MediaQuery.sizeOf(context).width < AppBreakpoint.compactWidth;

    var low = form.isEmpty ? 0.0 : math.min(0.0, form.reduce(math.min));
    var high = 0.0;
    for (final value in [...fitness, ...fatigue, ...form]) {
      low = math.min(low, value);
      high = math.max(high, value);
    }
    if (high - low < 1e-9) high = low + 1;
    final ticks = niceTicks(low, high);
    final bottom = ticks.first;
    final top = ticks.last;
    final interval = ticks.length > 1 ? ticks[1] - ticks[0] : top - bottom;

    List<fl.FlSpot> bars(bool up) => [
      for (var i = 0; i < form.length; i++)
        if (up ? form[i] > 0 : form[i] < 0) ...[
          fl.FlSpot(i.toDouble(), 0),
          fl.FlSpot(i.toDouble(), form[i]),
          fl.FlSpot.nullSpot,
        ],
    ];
    final above = bars(true), below = bars(false);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        key: paintKey,
        builder: (context, constraints) {
          final plot = math.max(
            constraints.maxWidth - AppChart.gutterLeft,
            1.0,
          );
          final step = barLabelStep(
            slot: plot / fitness.length,
            compact: compact,
          );
          final barWidth = math.max(
            plot / fitness.length * AppChart.barFraction,
            1.0,
          );
          return fl.LineChart(
            fl.LineChartData(
              minX: 0,
              maxX: (fitness.length - 1).toDouble(),
              minY: bottom,
              maxY: top,
              borderData: fl.FlBorderData(show: false),
              gridData: fl.FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (_) =>
                    fl.FlLine(color: scheme.outlineVariant, strokeWidth: 1),
              ),
              titlesData: fl.FlTitlesData(
                topTitles: const fl.AxisTitles(
                  sideTitles: fl.SideTitles(showTitles: false),
                ),
                rightTitles: const fl.AxisTitles(
                  sideTitles: fl.SideTitles(showTitles: false),
                ),
                leftTitles: fl.AxisTitles(
                  sideTitles: fl.SideTitles(
                    showTitles: true,
                    reservedSize: AppChart.gutterLeft,
                    interval: interval,
                    getTitlesWidget: (value, meta) => Text(
                      _round(value),
                      style: axis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                bottomTitles: fl.AxisTitles(
                  sideTitles: fl.SideTitles(
                    showTitles: true,
                    reservedSize: AppChart.dateLabelHeight,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 || index >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      if ((labels.length - 1 - index) % step != 0) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(labels[index], style: axis),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: fl.LineTouchData(enabled: false),
              extraLinesData: fl.ExtraLinesData(
                horizontalLines: [
                  if (low < 0)
                    fl.HorizontalLine(
                      y: 0,
                      color: scheme.onSurfaceVariant,
                      strokeWidth: 1,
                    ),
                ],
              ),
              lineBarsData: [
                // The form bars first, so the lines are read over them.
                if (above.isNotEmpty)
                  _bars(above, colors.accentStrong, barWidth),
                if (below.isNotEmpty) _bars(below, colors.signal, barWidth),
                fl.LineChartBarData(
                  spots: [
                    for (var i = 0; i < fitness.length; i++)
                      fl.FlSpot(i.toDouble(), fitness[i]),
                  ],
                  color: colors.accentStrong,
                  barWidth: AppChart.lineWidth,
                  isStrokeCapRound: true,
                  isStrokeJoinRound: true,
                  dotData: fl.FlDotData(
                    checkToShowDot: (spot, bar) => spot.x == bar.spots.last.x,
                    getDotPainter: (spot, x, bar, index) =>
                        fl.FlDotCirclePainter(
                          radius: AppSpacing.xs,
                          color: colors.accentStrong,
                          strokeWidth: 3,
                          strokeColor: scheme.surfaceContainer,
                        ),
                  ),
                  belowBarData: fl.BarAreaData(
                    show: true,
                    applyCutOffY: true,
                    cutOffY: 0,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors.accentStrong.withValues(alpha: 0.35),
                        colors.accentStrong.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                fl.LineChartBarData(
                  spots: [
                    for (var i = 0; i < fatigue.length; i++)
                      fl.FlSpot(i.toDouble(), fatigue[i]),
                  ],
                  color: fatigueColor,
                  barWidth: 1.6,
                  isStrokeJoinRound: true,
                  dashArray: const [6, 4],
                  dotData: fl.FlDotData(
                    checkToShowDot: (spot, bar) => spot.x == bar.spots.last.x,
                    getDotPainter: (spot, x, bar, index) =>
                        fl.FlDotCirclePainter(
                          radius: AppSpacing.xs,
                          color: fatigueColor,
                          strokeWidth: 3,
                          strokeColor: scheme.surfaceContainer,
                        ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// One colour of form bars: a round-capped segment from the zero line to each value.
  static fl.LineChartBarData _bars(
    List<fl.FlSpot> spots,
    Color color,
    double width,
  ) => fl.LineChartBarData(
    spots: spots,
    color: color,
    barWidth: width,
    isStrokeCapRound: true,
    dotData: const fl.FlDotData(show: false),
  );

  static String _round(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : decimal(value, 1);
}

/// The mean-max power curve on a log time axis, with a dot on every best effort and the FTP in use as
/// a dashed line the curve is read against.
class PowerCurveChart extends StatelessWidget {
  const PowerCurveChart({
    super.key,
    required this.seconds,
    required this.watts,
    required this.marks,
    required this.emptyMessage,
    this.ftp,
    this.ftpLabel,
    this.height = AppChart.height,
    this.paintKey,
  });

  /// The duration and the watts of each best effort, in the same order.
  final List<double> seconds;
  final List<double> watts;

  /// Where the duration axis is marked: a log axis has no room for a label at every point.
  final List<({double seconds, String label})> marks;

  /// What a rider with no power data reads instead of the curve.
  final String emptyMessage;

  /// The FTP in use, drawn as a dashed line across the curve.
  final int? ftp;
  final String? ftpLabel;

  final double height;

  /// A key on the drawing, for a test that looks for it.
  final Key? paintKey;

  /// The log time axis runs from one second to an hour, as the design says.
  static const double _logMax = 3600;

  static double _x(double seconds) =>
      math.log(seconds.clamp(1, _logMax).toDouble()) / math.log(_logMax);

  @override
  Widget build(BuildContext context) {
    if (seconds.isEmpty) {
      return EmptyState(framed: false, message: emptyMessage);
    }
    final scheme = Theme.of(context).colorScheme;
    final colors = VelomineColors.of(context);
    final line = colors.series['power']!;
    final axis = chartLabelStyle(context);
    final ticks = niceTicks(0, watts.reduce(math.max));
    final top = ticks.last;
    final interval = ticks.length > 1 ? ticks[1] - ticks[0] : top;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        key: paintKey,
        builder: (context, constraints) {
          final plot = math.max(
            constraints.maxWidth - AppChart.gutterLeft - AppSpacing.sm,
            1.0,
          );
          final chartHeight = math.max(
            constraints.maxHeight - AppChart.dateLabelHeight,
            1.0,
          );
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: AppSpacing.sm,
                top: 0,
                height: chartHeight,
                child: fl.LineChart(
                  fl.LineChartData(
                    minX: 0.0,
                    maxX: 1.0,
                    minY: 0.0,
                    maxY: top,
                    borderData: fl.FlBorderData(show: false),
                    gridData: fl.FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: interval,
                      getDrawingHorizontalLine: (_) => fl.FlLine(
                        color: scheme.outlineVariant,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: fl.FlTitlesData(
                      topTitles: const fl.AxisTitles(
                        sideTitles: fl.SideTitles(showTitles: false),
                      ),
                      rightTitles: const fl.AxisTitles(
                        sideTitles: fl.SideTitles(showTitles: false),
                      ),
                      bottomTitles: const fl.AxisTitles(
                        sideTitles: fl.SideTitles(showTitles: false),
                      ),
                      leftTitles: fl.AxisTitles(
                        sideTitles: fl.SideTitles(
                          showTitles: true,
                          reservedSize: AppChart.gutterLeft,
                          interval: interval,
                          getTitlesWidget: (value, meta) => Text(
                            _round(value),
                            style: axis,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ),
                    lineTouchData: fl.LineTouchData(enabled: false),
                    extraLinesData: fl.ExtraLinesData(
                      horizontalLines: [
                        if (ftp case final ftp? when ftp > 0)
                          fl.HorizontalLine(
                            y: math.min(ftp.toDouble(), top),
                            color: scheme.onSurfaceVariant,
                            strokeWidth: 1.2,
                            dashArray: const [6, 4],
                            label: fl.HorizontalLineLabel(
                              show: ftpLabel != null,
                              alignment: Alignment.topLeft,
                              padding: const EdgeInsets.only(
                                top: AppSpacing.xs,
                                left: AppSpacing.sm,
                              ),
                              style: axis,
                              labelResolver: (_) => ftpLabel ?? '',
                            ),
                          ),
                      ],
                    ),
                    lineBarsData: [
                      fl.LineChartBarData(
                        spots: [
                          for (var i = 0; i < seconds.length; i++)
                            fl.FlSpot(_x(seconds[i]), watts[i]),
                        ],
                        color: line,
                        barWidth: AppChart.lineWidth,
                        isStrokeCapRound: true,
                        isStrokeJoinRound: true,
                        dotData: fl.FlDotData(
                          getDotPainter: (spot, x, bar, index) =>
                              fl.FlDotCirclePainter(
                                radius: AppSpacing.xs,
                                color: line,
                                strokeWidth: 2,
                                strokeColor: scheme.surfaceContainer,
                              ),
                        ),
                        belowBarData: fl.BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              line.withValues(alpha: 0.35),
                              line.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // The duration axis: marks at their own place on the log scale, which fl_chart's evenly
              // stepped titles cannot put them.
              for (final mark in marks)
                Positioned(
                  // Centred on its mark, and kept inside the chart at both ends.
                  left: _markLeft(
                    AppChart.gutterLeft + _x(mark.seconds) * plot,
                    plot,
                  ),
                  width: AppChart.minLabelWidth,
                  top: chartHeight,
                  height: AppChart.dateLabelHeight,
                  child: Text(
                    mark.label,
                    style: axis,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _round(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : decimal(value, 1);
}

/// One signal of a ride against time, with the moment the rider points at marked and shared with the
/// other charts through [selected].
class SeriesLineChart extends StatelessWidget {
  const SeriesLineChart({
    super.key,
    required this.time,
    required this.values,
    required this.marks,
    required this.color,
    required this.emptyMessage,
    required this.selected,
    this.baseline = false,
    this.highlight,
    this.height = 130,
    this.paintKey,
  });

  /// The moment of each sample, in seconds, ascending.
  final List<double> time;

  /// The signal at each sample, null where the file had none.
  final List<double?> values;

  /// Where the time axis is marked, in seconds, with the label it reads.
  final List<({double seconds, String label})> marks;

  /// The signal's own colour from `VelomineColors.series`.
  final Color color;

  /// What a signal with nothing to draw says.
  final String emptyMessage;

  /// The sample the cursor sits on, shared with the map and the other charts.
  final ValueNotifier<int?> selected;

  /// Mark zero: the W′ balance is the one signal where 0 itself means something.
  final bool baseline;

  /// A lap or a selected stretch, shaded behind the line, in seconds.
  final ({double from, double to})? highlight;

  final double height;

  /// A key on the drawing, for a test that looks for it.
  final Key? paintKey;

  @override
  Widget build(BuildContext context) {
    if (time.length < 2 || values.every((v) => v == null)) {
      return EmptyState(framed: false, message: emptyMessage);
    }
    final scheme = Theme.of(context).colorScheme;
    final axis = chartLabelStyle(context);
    var low = baseline ? 0.0 : values.whereType<double>().reduce(math.min);
    var high = values.whereType<double>().reduce(math.max);
    if (high - low < 1e-9) {
      final pad = low == 0 ? 1.0 : low.abs() * 0.1;
      low -= pad;
      high += pad;
    }
    final ticks = niceTicks(low, high);
    final bottom = ticks.first;
    final top = ticks.last;
    final interval = ticks.length > 1 ? ticks[1] - ticks[0] : top - bottom;
    final first = time.first, last = time.last;

    // The spots fl_chart draws, and which sample each one came from: a null breaks the line.
    final spots = <fl.FlSpot>[];
    final samples = <int>[];
    for (var i = 0; i < time.length; i++) {
      final value = values[i];
      if (value == null) {
        if (spots.isNotEmpty && spots.last.isNotNull()) {
          spots.add(fl.FlSpot.nullSpot);
        }
        continue;
      }
      spots.add(fl.FlSpot(time[i], value));
      samples.add(i);
    }
    while (spots.isNotEmpty && spots.last.isNull()) {
      spots.removeLast();
    }

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        key: paintKey,
        builder: (context, constraints) {
          final plot = math.max(
            constraints.maxWidth - AppChart.gutterLeft - AppSpacing.sm,
            1.0,
          );
          final chartHeight = math.max(
            constraints.maxHeight - AppChart.dateLabelHeight,
            1.0,
          );
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: AppSpacing.sm,
                top: 0,
                height: chartHeight,
                child: ValueListenableBuilder<int?>(
                  valueListenable: selected,
                  builder: (context, index, child) {
                    final shown = index == null ? -1 : samples.indexOf(index);
                    return fl.LineChart(
                      fl.LineChartData(
                        minX: first,
                        maxX: last,
                        minY: bottom,
                        maxY: top,
                        borderData: fl.FlBorderData(show: false),
                        clipData: const fl.FlClipData.none(),
                        gridData: fl.FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: interval,
                          getDrawingHorizontalLine: (_) => fl.FlLine(
                            color: scheme.outlineVariant,
                            strokeWidth: 1,
                          ),
                        ),
                        rangeAnnotations: fl.RangeAnnotations(
                          verticalRangeAnnotations: [
                            if (highlight case final lap?)
                              fl.VerticalRangeAnnotation(
                                x1: lap.from.clamp(first, last),
                                x2: lap.to.clamp(first, last),
                                color: color.withValues(alpha: 0.1),
                              ),
                          ],
                        ),
                        titlesData: fl.FlTitlesData(
                          topTitles: const fl.AxisTitles(
                            sideTitles: fl.SideTitles(showTitles: false),
                          ),
                          rightTitles: const fl.AxisTitles(
                            sideTitles: fl.SideTitles(showTitles: false),
                          ),
                          bottomTitles: const fl.AxisTitles(
                            sideTitles: fl.SideTitles(showTitles: false),
                          ),
                          leftTitles: fl.AxisTitles(
                            sideTitles: fl.SideTitles(
                              showTitles: true,
                              reservedSize: AppChart.gutterLeft,
                              interval: interval,
                              getTitlesWidget: (value, meta) => Text(
                                _round(value),
                                style: axis,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                        ),
                        // The cursor is the page's, not the library's: a tap or a hover moves the
                        // shared selection, and the marked spot is drawn from it.
                        lineTouchData: fl.LineTouchData(
                          touchTooltipData: fl.LineTouchTooltipData(
                            getTooltipItems: (_) => const [],
                          ),
                          handleBuiltInTouches: false,
                          touchCallback: (event, response) {
                            if (event is fl.FlPointerExitEvent) {
                              selected.value = null;
                              return;
                            }
                            final spot = response?.lineBarSpots?.firstOrNull;
                            if (spot == null ||
                                spot.spotIndex >= samples.length) {
                              return;
                            }
                            selected.value = samples[spot.spotIndex];
                          },
                          getTouchedSpotIndicator: (bar, indices) => [
                            for (final _ in indices)
                              fl.TouchedSpotIndicatorData(
                                fl.FlLine(
                                  color: color.withValues(alpha: 0.7),
                                  strokeWidth: 1,
                                ),
                                fl.FlDotData(
                                  getDotPainter: (spot, x, bar, index) =>
                                      fl.FlDotCirclePainter(
                                        radius: AppSpacing.xs,
                                        color: color,
                                        strokeWidth: 1.2,
                                        strokeColor: scheme.surface,
                                      ),
                                ),
                              ),
                          ],
                        ),
                        extraLinesData: fl.ExtraLinesData(
                          horizontalLines: [
                            if (baseline)
                              fl.HorizontalLine(
                                y: 0,
                                color: scheme.outlineVariant,
                                strokeWidth: 1.5,
                              ),
                          ],
                        ),
                        lineBarsData: [
                          fl.LineChartBarData(
                            spots: spots,
                            color: color,
                            barWidth: 1.8,
                            isStrokeJoinRound: true,
                            dotData: const fl.FlDotData(show: false),
                            showingIndicators: [
                              if (shown >= 0 && shown < spots.length) shown,
                            ],
                            belowBarData: fl.BarAreaData(
                              show: true,
                              // The design's fill: 35 % under the line, gone at the base.
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  color.withValues(alpha: 0.35),
                                  color.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              for (final mark in marks)
                Positioned(
                  left: _markLeft(
                    AppChart.gutterLeft +
                        (mark.seconds - first) /
                            math.max(last - first, 1) *
                            plot,
                    plot,
                  ),
                  width: AppChart.minLabelWidth,
                  top: chartHeight,
                  height: AppChart.dateLabelHeight,
                  child: Text(
                    mark.label,
                    style: axis,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _round(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : decimal(value, 1);
}

/// Where a marked label starts, so a mark at either end of the axis still reads whole.
double _markLeft(double centre, double plot) =>
    (centre - AppChart.minLabelWidth / 2).clamp(
      0.0,
      math.max(AppChart.gutterLeft + plot - AppChart.minLabelWidth, 0.0),
    );
