import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart' as fl;
import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../tokens.dart';
import 'chart_chrome.dart';
import 'empty_state.dart';
import 'nice_ticks.dart';

/// One value over time: a line with a fading area under it, its latest point marked with its value.
///
/// Drawn by `fl_chart` (see `docs/dependencies/fl_chart.md`): the line, its area, the grid, the axis
/// labels and the dot are its own, and every colour and style the design fixes is passed in here,
/// because fl_chart's theme is Flutter-Material's fallback and not Velomine's.
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
    final axis = chartLabelStyle(context);
    final compact =
        MediaQuery.sizeOf(context).width < AppBreakpoint.compactWidth;

    // A flat run fills the middle of the box instead of sitting on the bottom edge.
    var low = values.reduce(math.min);
    var high = values.reduce(math.max);
    if (high - low < 1e-9) {
      final pad = math.max(high.abs() * 0.1, 0.1);
      low -= pad;
      high += pad;
    }
    final ticks = niceTicks(low, high);
    final bottom = ticks.first;
    final top = ticks.last;
    final interval = ticks.length > 1 ? ticks[1] - ticks[0] : top - bottom;
    final last = values.length - 1;
    // One value is a dot in the middle rather than a line along the edge.
    final maxX = math.max(last, 1).toDouble();

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            key: paintKey,
            builder: (context, constraints) {
              final plot = math.max(
                constraints.maxWidth - AppChart.gutterLeft,
                1.0,
              );
              final plotHeight = math.max(
                constraints.maxHeight - AppChart.dateLabelHeight,
                1.0,
              );
              final step = barLabelStep(
                slot: plot / values.length,
                compact: compact,
              );
              final latestY =
                  plotHeight -
                  (values.last - bottom) / (top - bottom) * plotHeight;
              return Stack(
                children: [
                  Positioned.fill(
                    child: fl.LineChart(
                      fl.LineChartData(
                        minX: 0,
                        maxX: maxX,
                        minY: bottom,
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
                          leftTitles: fl.AxisTitles(
                            sideTitles: fl.SideTitles(
                              showTitles: true,
                              reservedSize: AppChart.gutterLeft,
                              interval: interval,
                              getTitlesWidget: (value, meta) => Text(
                                format(value),
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
                                // Fewer dates when the points crowd together.
                                if ((last - index) % step != 0) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.xs,
                                  ),
                                  child: Text(labels[index], style: axis),
                                );
                              },
                            ),
                          ),
                        ),
                        lineTouchData: fl.LineTouchData(enabled: false),
                        lineBarsData: [
                          fl.LineChartBarData(
                            spots: [
                              for (var i = 0; i < values.length; i++)
                                fl.FlSpot(
                                  last == 0 ? 0.5 : i.toDouble(),
                                  values[i],
                                ),
                            ],
                            color: line,
                            barWidth: AppChart.lineWidth,
                            isStrokeCapRound: true,
                            isStrokeJoinRound: true,
                            dotData: fl.FlDotData(
                              checkToShowDot: (spot, bar) =>
                                  spot.x == bar.spots.last.x,
                              getDotPainter: (spot, x, bar, index) =>
                                  fl.FlDotCirclePainter(
                                    radius: AppChart.dotRadius,
                                    color: line,
                                    strokeWidth: 3,
                                    strokeColor: scheme.surfaceContainer,
                                  ),
                            ),
                            belowBarData: fl.BarAreaData(
                              show: true,
                              // The design's fill: 35 % at the line, gone at the base.
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
                  // The latest value, beside its dot: fl_chart labels a bar, not a line.
                  Positioned(
                    left: AppChart.gutterLeft,
                    right: AppSpacing.sm,
                    top: math.max(
                      latestY - AppChart.valueLabelHeight - AppSpacing.xs,
                      0,
                    ),
                    child: Text(
                      format(values.last),
                      textAlign: TextAlign.end,
                      style: axis.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
