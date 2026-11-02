import 'package:intl/intl.dart';

/// Distances, durations and speeds for display. The server always sends metres, seconds and metres per second.
String km(double? metres) => metres == null
    ? '–'
    : '${(metres / 1000).toStringAsFixed(metres >= 100000 ? 0 : 1)} km';

String kmh(double? metresPerSecond) => metresPerSecond == null
    ? '–'
    : '${(metresPerSecond * 3.6).toStringAsFixed(1)} km/h';

String duration(double? seconds) {
  if (seconds == null) return '–';
  final minutes = (seconds / 60).round();
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return h > 0 ? '$h h ${m.toString().padLeft(2, '0')} min' : '$m min';
}

String dateTime(DateTime? value) =>
    value == null ? '–' : DateFormat.yMMMd().add_Hm().format(value.toLocal());
