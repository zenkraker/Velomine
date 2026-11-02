import 'dart:math' as math;

/// An axis range with round numbers: [min] and [max] are multiples of [step].
class NiceScale {
  const NiceScale(this.min, this.max, this.step);

  final double min;
  final double max;
  final double step;

  List<double> get ticks => [
    for (var v = min; v <= max + step / 2; v += step) v,
  ];
}

/// A scale for data between [low] and [high] with about [target] ticks, using steps of 1, 2, 2.5 or 5 times a power of ten.
NiceScale niceScale(double low, double high, {int target = 4}) {
  if (high - low < 1e-9) {
    // A flat line: give it some room so it is drawn in the middle instead of on an edge.
    final pad = low == 0 ? 1.0 : low.abs() * 0.1;
    low -= pad;
    high += pad;
  }
  final rough = (high - low) / target;
  final magnitude = math
      .pow(10, (math.log(rough) / math.ln10).floor())
      .toDouble();
  final step = [
    1,
    2,
    2.5,
    5,
    10,
  ].map((m) => m * magnitude).firstWhere((s) => s >= rough);
  return NiceScale(
    (low / step).floor() * step,
    (high / step).ceil() * step,
    step,
  );
}

/// Round time marks for an axis of [totalSeconds]: every 30 s, 1 min, 5 min, 15 min, 1 h and so on, at most [maxTicks].
List<double> timeTicks(double totalSeconds, {int maxTicks = 6}) {
  const steps = [30.0, 60, 120, 300, 600, 900, 1800, 3600, 7200, 14400];
  final step = steps.firstWhere(
    (s) => totalSeconds / s <= maxTicks,
    orElse: () => steps.last,
  );
  return [for (var t = 0.0; t <= totalSeconds; t += step) t];
}

/// A label for a time mark on an axis. A ride under an hour is marked in minutes and seconds (5:30); a longer one is
/// marked in hours and minutes (1:15) on every mark, so "1:00" never means an hour next to marks in minutes.
String timeLabel(double seconds, {bool hours = false}) {
  final total = seconds.round();
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  return hours
      ? '$h:${m.toString().padLeft(2, '0')}'
      : '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
}

/// A full clock reading for one moment: 5:30, or 1:15:30 once past the hour.
String clock(double seconds) {
  final total = seconds.round();
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  return h > 0
      ? '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
      : '$m:${s.toString().padLeft(2, '0')}';
}

/// The index of the sample nearest to [t] in [time], which is in ascending order.
int nearestIndex(List<double> time, double t) {
  var lo = 0, hi = time.length - 1;
  while (lo < hi) {
    final mid = (lo + hi) ~/ 2;
    if (time[mid] < t) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  if (lo > 0 && (t - time[lo - 1]).abs() <= (time[lo] - t).abs()) return lo - 1;
  return lo;
}
