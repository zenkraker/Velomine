import 'package:material_ui/material_ui.dart';

import '../../../core/l10n.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/chart_chrome.dart';
import '../../../core/widgets/line_chart.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'lap_range.dart';
import 'ride_series.dart';
import 'scale.dart';

/// The name of a signal in the language on screen. The id is what the ride file gave it.
String seriesName(AppLocalizations l10n, Series series) => switch (series.id) {
  'elevation' => l10n.seriesElevation,
  'speed' => l10n.seriesSpeed,
  'power' => l10n.seriesPower,
  'estimatedpower' => l10n.seriesEstimatedPower,
  'heartrate' => l10n.seriesHeartRate,
  'cadence' => l10n.seriesCadence,
  'wprime' => l10n.seriesWPrimeBalance,
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = seriesName(l10n, series);
    final span = time.isEmpty ? 0.0 : time.last - time.first;
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
          // The drawing says nothing a screen reader needs: the label above already read every
          // number on this chart.
          ExcludeSemantics(
            child: ValueListenableBuilder<LapRange?>(
              valueListenable: selectedLap,
              builder: (_, lap, _) => SeriesLineChart(
                paintKey: Key('chart-${series.id}'),
                time: time,
                values: series.values,
                // The time marks are the page's, so a ride under an hour reads 5:30 and a longer one 1:15.
                marks: [
                  for (final t in timeTicks(span))
                    (
                      seconds: time.isEmpty ? 0.0 : time.first + t,
                      label: timeLabel(t, hours: span >= 3600),
                    ),
                ],
                color: color,
                emptyMessage: l10n.rideNoData,
                selected: selected,
                baseline: series.baseline,
                highlight: lap == null
                    ? null
                    : (from: lap.startS, to: lap.endS),
                height: height,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
