import 'package:intl/intl.dart';

import 'units.dart';

/// A number in the language the app is showing (set through `Intl.defaultLocale`): "42.3", "42,3".
/// No grouping separators, so a big distance still reads "1200 km" rather than "1,200 km".
String _decimal(double value, int digits) =>
    NumberFormat(digits == 0 ? '0' : '0.${'0' * digits}').format(value);

const _metresPerMile = 1609.344;
const _feetPerMetre = 3.280839895;
const _poundsPerKg = 2.2046226218;

/// 1609.344: the exact definition of a statute mile. Screens that type or check a
/// length in the member's unit convert with it.
const metresPerMile = _metresPerMile;

/// 2.2046226218: the exact definition of a pound, for the weight field.
const poundsPerKg = _poundsPerKg;

/// Distances, durations and speeds for display. The server always sends metres, seconds and metres per second.
/// A distance: "42.3 km" or "26.3 mi".
String km(Units units, double? metres) {
  if (metres == null) return '–';
  if (units == Units.imperial) {
    final miles = metres / _metresPerMile;
    return '${_decimal(miles, miles >= 100 ? 0 : 1)} mi';
  }
  return '${_decimal(metres / 1000, metres >= 100000 ? 0 : 1)} km';
}

/// A speed: "28.1 km/h" or "17.5 mph".
String kmh(Units units, double? metresPerSecond) {
  if (metresPerSecond == null) return '–';
  return units == Units.imperial
      ? '${_decimal(metresPerSecond * 3600 / _metresPerMile, 1)} mph'
      : '${_decimal(metresPerSecond * 3.6, 1)} km/h';
}

/// A height or a climb in metres: "620 m" or "2034 ft". [up] adds the arrow of a climb.
String elevation(Units units, double? metres, {bool up = false}) {
  if (metres == null) return '–';
  final value = units == Units.imperial
      ? '${(metres * _feetPerMetre).round()} ft'
      : '${metres.round()} m';
  return up ? '$value ↑' : value;
}

/// The symbol a distance is shown in: "km" or "mi". For strings that put the
/// unit after a number the app builds itself.
String distanceUnit(Units units) => units == Units.imperial ? 'mi' : 'km';

/// The symbol a height is shown in: "m" or "ft".
String elevationUnit(Units units) => units == Units.imperial ? 'ft' : 'm';

/// A weight in kilograms: "72.0 kg" or "158.7 lb".
String weight(Units units, double? kg) => kg == null
    ? '–'
    : units == Units.imperial
    ? '${_decimal(kg * _poundsPerKg, 1)} lb'
    : '${_decimal(kg, 1)} kg';

/// A short length such as a privacy-zone radius or a trim, kept in metres in the
/// database: "500 m", "0.3 mi". Metres stay readable below a kilometre.
String length(Units units, double? metres) {
  if (metres == null) return '–';
  if (units == Units.imperial) {
    final miles = metres / _metresPerMile;
    return miles >= 0.1
        ? '${_decimal(miles, 1)} mi'
        : '${(metres * _feetPerMetre).round()} ft';
  }
  return '${metres.round()} m';
}

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

/// A calendar day, as the server sent it: it is a date, not an instant, so it is not moved to the local zone.
String dateOnly(DateTime? value) =>
    value == null ? '–' : DateFormat.yMMMd().format(value);

/// A moment with its weekday, for a log of when something happened: "Tue, Nov 3 14:10".
String weekdayTime(DateTime? value) =>
    value == null ? '–' : DateFormat.MMMEd().add_Hm().format(value.toLocal());

/// A size on disk: "0 B", "12 KB", "3.4 MB", "1.2 GB".
String bytes(num size) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = size.toDouble();
  var unit = 0;
  while (value >= 1000 && unit < units.length - 1) {
    value /= 1000;
    unit++;
  }
  return '${_decimal(value, unit == 0 || value >= 100 ? 0 : 1)} ${units[unit]}';
}
