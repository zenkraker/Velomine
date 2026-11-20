import 'dart:math' as math;

import '../tokens.dart';

/// The round values a chart draws its gridlines at: ascending, at most four, the first at or under
/// [min] and the last at or over [max]. Steps are 1, 2, 4 or 5 times a power of ten.
List<double> niceTicks(double min, double max) {
  if (max <= min) return [min, min + 1];
  var step = _step((max - min) / (AppChart.maxGridLines - 1));
  var low = (min / step).floorToDouble() * step;
  var high = (max / step).ceilToDouble() * step;
  var count = ((high - low) / step).round();
  // Snapping the bounds can add a line; a wider step then brings it back under the cap.
  while (count > AppChart.maxGridLines - 1) {
    step = _next(step);
    low = (min / step).floorToDouble() * step;
    high = (max / step).ceilToDouble() * step;
    count = ((high - low) / step).round();
  }
  return [for (var i = 0; i <= count; i++) low + i * step];
}

/// How many bars carry a date under them, so the labels never touch: a fixed step on a wide bar,
/// and a wider one when the bars get narrow.
int barLabelStep({required double slot, required bool compact}) => math.max(
  compact ? AppChart.compactLabelStep : AppChart.mediumLabelStep,
  (AppChart.minLabelWidth / slot).ceil(),
);

/// The smallest round step that is not under [raw].
double _step(double raw) {
  if (raw <= 0) return 1;
  final power = _powerOfTen(raw);
  for (final multiple in const [1.0, 2.0, 4.0, 5.0]) {
    if (multiple * power >= raw * (1 - 1e-9)) return multiple * power;
  }
  return 10 * power;
}

/// The next round step above [step].
double _next(double step) {
  final power = _powerOfTen(step);
  for (final multiple in const [1.0, 2.0, 4.0, 5.0]) {
    if (multiple * power > step * (1 + 1e-9)) return multiple * power;
  }
  return 10 * power;
}

double _powerOfTen(double value) =>
    math.pow(10, (math.log(value) / math.ln10).floor()).toDouble();
