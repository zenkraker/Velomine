import 'package:material_ui/material_ui.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/app_map.dart';
import 'lap_range.dart';
import 'ride_series.dart';

/// Low heart rate in the route colour, high heart rate in the chart's heart-rate colour.
Color heartRateColor(
  double bpm,
  double min,
  double max,
  VelomineColors colors,
) {
  final high = colors.series['heartrate'] ?? colors.finish;
  final t = max > min ? ((bpm - min) / (max - min)).clamp(0.0, 1.0) : 1.0;
  return Color.lerp(colors.route, high, t)!;
}

/// The heart-rate colours a route is cut into: a line per run of one colour, not one per sample.
const _heartRateSteps = 16;

/// The route's own point indexes in runs, a new run starting where samples were hidden.
List<List<int>> _runs(RideSeries data, bool Function(int i) keep) {
  final runs = <List<int>>[];
  List<int>? open;
  for (var i = 0; i < data.route.length; i++) {
    if (data.routeBreaks.contains(i)) open = null;
    if (!keep(i)) {
      open = null;
      continue;
    }
    if (open == null) runs.add(open = []);
    open.add(i);
  }
  return runs;
}

/// The route as lines: a glow and a pale halo under the line, so the route is the brightest thing on a dimmed map,
/// then the line itself, in the route colour or coloured by [heartRate] when [showHeartRate].
List<AppMapLine> routeLines(
  RideSeries data,
  VelomineColors colors, {
  required Series? heartRate,
  required bool showHeartRate,
}) {
  final runs = _runs(data, (_) => true);
  List<AppMapLine> under(double width, Color color) => [
    for (final run in runs)
      AppMapLine(
        points: [for (final i in run) data.route[i]],
        color: color,
        width: width,
      ),
  ];
  final lines = [
    ...under(14, colors.routeGlow),
    ...under(7, colors.halo.withValues(alpha: 0.9)),
  ];
  if (!showHeartRate || heartRate == null) {
    return [...lines, ...under(4, colors.route)];
  }
  for (final run in runs) {
    // The segment ending at sample i takes the colour of its heart rate; a missing rate takes the route colour.
    Color colourAt(int i) {
      final value = heartRate.values[data.routeIndex[i]];
      if (value == null) return colors.route;
      final range = heartRate.max - heartRate.min;
      final step = range > 0
          ? ((value - heartRate.min) / range * _heartRateSteps).round()
          : _heartRateSteps;
      return heartRateColor(
        heartRate.min + range * step / _heartRateSteps,
        heartRate.min,
        heartRate.max,
        colors,
      );
    }

    var points = [data.route[run.first]];
    Color? current;
    for (var k = 1; k < run.length; k++) {
      final colour = colourAt(run[k]);
      if (current != null && colour != current) {
        lines.add(AppMapLine(points: points, color: current, width: 4));
        points = [points.last];
      }
      current = colour;
      points.add(data.route[run[k]]);
    }
    if (current != null) {
      lines.add(AppMapLine(points: points, color: current, width: 4));
    }
  }
  return lines;
}

/// The start and the finish, unless the rider hid them.
List<AppMapDot> routeEnds(RideSeries data, VelomineColors colors) => [
  if (!data.startHidden)
    AppMapDot(
      at: data.route.first,
      color: colors.route,
      ringColor: colors.halo,
      size: 18,
      ringWidth: 2,
    ),
  if (!data.endHidden)
    AppMapDot(
      at: data.route.last,
      color: colors.finish,
      ringColor: colors.halo,
      size: 18,
      ringWidth: 2,
    ),
];

/// The selected lap drawn over the route.
List<AppMapLine> lapLines(
  RideSeries data,
  VelomineColors colors,
  LapRange? lap,
) => lap == null
    ? const []
    : [
        for (final run in _runs(data, (i) {
          final t = data.time[data.routeIndex[i]];
          return t >= lap.startS && t <= lap.endS;
        }))
          AppMapLine(
            points: [for (final i in run) data.route[i]],
            color: colors.finish,
            width: 6,
          ),
      ];

/// The marker at the selected moment, when one is selected and has a place on the route.
List<AppMapDot> selectedDot(
  RideSeries data,
  VelomineColors colors,
  int? selected,
) {
  final at = selected == null ? null : data.routePointAt(selected);
  return at == null
      ? const []
      : [
          AppMapDot(
            at: at,
            color: colors.finish,
            ringColor: colors.halo,
            size: 22,
            ringWidth: 3,
          ),
        ];
}
