import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/units.dart';
import '../../core/widgets/bar_chart.dart';
import '../../l10n/generated/app_localizations.dart';

/// What the totals chart counts: one measure at a time, chosen on the page.
enum TotalsMeasure { distance, time, elevation }

String _periodWord(AppLocalizations l10n, String period) => switch (period) {
  'week' => l10n.periodWordWeek,
  'month' => l10n.periodWordMonth,
  _ => l10n.periodWordYear,
};

/// The short name of a period under its bar: "2 Nov" for a week, "Nov" for a month, "2026" for a year.
String periodLabel(String period, DateTime start) => switch (period) {
  'week' => DateFormat.MMMd().format(start),
  'month' => DateFormat.MMM().format(start),
  _ => DateFormat.y().format(start),
};

/// The full name of a period: "2 – 8 Nov 2026", "November 2026", "2026".
String periodTitle(
  String period,
  DateTime start,
  DateTime end,
) => switch (period) {
  'week' =>
    '${DateFormat.MMMd().format(start)} – ${DateFormat.yMMMd().format(end)}',
  'month' => DateFormat.yMMMM().format(start),
  _ => DateFormat.y().format(start),
};

/// The name of a measure as the control offers it.
String totalsMeasureName(AppLocalizations l10n, TotalsMeasure measure) =>
    switch (measure) {
      TotalsMeasure.distance => l10n.statDistance,
      TotalsMeasure.time => l10n.goalMetricTime,
      TotalsMeasure.elevation => l10n.statClimbing,
    };

/// How the chosen measure reads: "69.7 km", "2 h 35 min", "620 m".
String totalsMeasureValue(
  AppLocalizations l10n,
  Units units,
  TotalsMeasure measure,
  PeriodTotals totals,
) => switch (measure) {
  TotalsMeasure.distance => km(units, totals.distanceM),
  TotalsMeasure.time => duration(totals.movingS),
  TotalsMeasure.elevation => elevation(units, totals.elevationGainM),
};

/// The period's total in the chart's own unit: kilometres and miles, hours, metres and feet.
double _measureValue(Units units, TotalsMeasure measure, PeriodTotals totals) =>
    switch (measure) {
      TotalsMeasure.distance => distanceIn(units, totals.distanceM),
      TotalsMeasure.time => totals.movingS / 3600,
      TotalsMeasure.elevation => elevationIn(units, totals.elevationGainM),
    };

/// Today's browser language has no part in it; the chart reads the member's units.
String _measureReading(
  AppLocalizations l10n,
  Units units,
  TotalsMeasure measure,
  double value,
) => switch (measure) {
  TotalsMeasure.distance => km(
    units,
    value * (units == Units.imperial ? metresPerMile : 1000),
  ),
  TotalsMeasure.time => duration(value * 3600),
  TotalsMeasure.elevation => elevation(
    units,
    value / (units == Units.imperial ? metresPerFoot : 1),
  ),
};

/// The mean of the periods as the card says it beside the title: "Average 19.8 km". Null when there is
/// nothing to average.
String? totalsAverage(
  AppLocalizations l10n,
  Units units,
  TotalsMeasure measure,
  List<PeriodTotals> totals,
) {
  if (totals.isEmpty) return null;
  final values = [for (final t in totals) _measureValue(units, measure, t)];
  final mean = values.reduce((a, b) => a + b) / values.length;
  return l10n.chartAverage(_measureReading(l10n, units, measure, mean));
}

/// The chosen measure per period as bars, oldest on the left, the current period last, its mean as a
/// dashed line.
class TotalsChart extends ConsumerWidget {
  const TotalsChart({
    super.key,
    required this.period,
    required this.totals,
    this.measure = TotalsMeasure.distance,
  });

  final String period;
  final List<PeriodTotals> totals;
  final TotalsMeasure measure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final units = ref.watch(unitsChoiceViewModelProvider);
    final current = totals.isEmpty ? null : totals.last;
    final values = [for (final t in totals) _measureValue(units, measure, t)];
    final average = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a + b) / values.length;
    return BarChart(
      values: values,
      labels: [for (final t in totals) periodLabel(period, t.start)],
      format: (value) => _measureReading(l10n, units, measure, value),
      // The line only: its value sits in the card's title row, where no bar label can reach it.
      average: average,
      semanticLabel: l10n.totalsSemanticsMeasure(
        totalsMeasureName(l10n, measure),
        _periodWord(l10n, period),
        current == null
            ? '–'
            : totalsMeasureValue(l10n, units, measure, current),
      ),
      emptyMessage: l10n.totalsEmpty,
    );
  }
}
