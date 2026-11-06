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

/// A running clock, for the recorder: "7:05" or "1:02:03".
String stopwatch(double? seconds) {
  if (seconds == null) return '–';
  final total = seconds.round().clamp(0, 359999);
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$m:$ss';
}

String dateTime(DateTime? value) =>
    value == null ? '–' : DateFormat.yMMMd().add_Hm().format(value.toLocal());

/// A size on disk: "0 B", "12 KB", "3.4 MB", "1.2 GB".
String bytes(num size) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = size.toDouble();
  var unit = 0;
  while (value >= 1000 && unit < units.length - 1) {
    value /= 1000;
    unit++;
  }
  return '${value.toStringAsFixed(unit == 0 || value >= 100 ? 0 : 1)} ${units[unit]}';
}
