import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart' as fl;
import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../tokens.dart';
import 'chart_chrome.dart';
import 'empty_state.dart';
import 'nice_ticks.dart';

/// A total per period: rounded bars that fade toward the base, the current one in the accent and
/// only the current and the peak carrying a value.
///
/// Drawn by `fl_chart` (see `docs/dependencies/fl_chart.md`): the bars, axis lines, grid, dashes and
/// the value labels are its widgets. Everything the design fixes — the colours, the two labels, the
/// tick step, the label step — is passed in here, because fl_chart's own theme is Flutter-Material's
/// fallback and not Velomine's.
class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.format,
    required this.semanticLabel,
    required this.emptyMessage,
    required this.currentIndex,
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

  /// The bar drawn in the accent: the caller names the period it means, so a chart never assumes
  /// its last bar is the current one.
  final int currentIndex;

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
    final current = currentIndex.clamp(0, values.length - 1);
    final peak = values.indexOf(values.reduce(math.max));
    final ticks = niceTicks(0, values.reduce(math.max));
    final top = ticks.last;
    final interval = ticks.length > 1 ? ticks[1] - ticks[0] : top;
    final axis = chartLabelStyle(context);

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
                1,
              );
              final slot = plot / values.length;
              final step = barLabelStep(
                slot: slot,
                compact:
                    MediaQuery.sizeOf(context).width <
                    AppBreakpoint.compactWidth,
              );
              return fl.BarChart(
                fl.BarChartData(
                  minY: 0,
                  maxY: top,
                  alignment: fl.BarChartAlignment.spaceAround,
                  borderData: fl.FlBorderData(show: false),
                  barTouchData: fl.BarTouchData(enabled: false),
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
                          _plain(value),
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
                          if (index < 0 || index >= values.length) {
                            return const SizedBox.shrink();
                          }
                          // Fewer labels on a phone: the step keeps them from touching.
                          if ((values.length - 1 - index) % step != 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(labels[index], style: axis),
                          );
                        },
                      ),
                    ),
                  ),
                  extraLinesData: fl.ExtraLinesData(
                    horizontalLines: [
                      if (average case final average? when average > 0)
                        fl.HorizontalLine(
                          y: math.min(average, top),
                          color: scheme.onSurfaceVariant,
                          strokeWidth: 1.2,
                          dashArray: const [6, 4],
                          // Above the start of the line, not its end: the last bar stands at the
                          // right edge, and a label there sat on the bar and ran off the card.
                          label: fl.HorizontalLineLabel(
                            show: averageText != null,
                            alignment: Alignment.topLeft,
                            padding: const EdgeInsets.only(
                              bottom: AppChart.valueLabelHeight,
                              left: AppSpacing.sm,
                            ),
                            style: axis,
                            labelResolver: (_) => averageText ?? '',
                          ),
                        ),
                    ],
                  ),
                  barGroups: [
                    for (var i = 0; i < values.length; i++)
                      fl.BarChartGroupData(
                        x: i,
                        barRods: [
                          fl.BarChartRodData(
                            // The current period always says its value; the peak says its own
                            // unless the two are one bar or their labels would run together.
                            label: fl.BarChartRodLabel(
                              show:
                                  i == current ||
                                  (i == peak &&
                                      i != current - 1 &&
                                      i != current + 1),
                              text: format(values[i]),
                              style: axis.copyWith(
                                color: i == current
                                    ? scheme.onSurface
                                    : scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                              offset: const Offset(0, AppSpacing.xs),
                            ),
                            // A bar too short to see still reads as a value on the axis.
                            toY: values[i] <= 0
                                ? 0
                                : math.max(values[i], top * 0.01),
                            width: slot * AppChart.barFraction,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                i == current
                                    ? colors.accentStrong
                                    : colors.barMuted,
                                (i == current
                                        ? colors.accentStrong
                                        : colors.barMuted)
                                    .withValues(alpha: 0.55),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppRadius.small),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// A tick as it reads: whole numbers where it can, so 40 is "40" and not "40.0".
  static String _plain(double value) =>
      value == value.roundToDouble() ? value.round().toString() : '$value';
}

/// One share of a whole as a horizontal bar, as `docs/design/pages/progress/FitnessPage.html` draws the
/// easy, moderate and hard rows: a 10 px pill filled to [share] percent of the room it is given, in the
/// caller's colour. It carries no axis: a row names its own share beside it.
class ShareBar extends StatelessWidget {
  const ShareBar({
    super.key,
    required this.share,
    required this.color,
    this.height = AppProgress.intensityBarHeight,
  });

  /// The part of the whole this bar stands for, from 0 to 100.
  final double share;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: (share / 100).clamp(0.0, 1.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    ),
  );
}
