import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:velomine/core/format.dart';

void main() {
  test('Format_ShouldShowDistancesInKmAndKmh_WhenGivenMetres', () {
    expect(km(42300), '42.3 km');
    expect(km(150000), '150 km');
    expect(km(null), '–');
    expect(kmh(7.8), '28.1 km/h');
  });

  test('Format_ShouldUseCommaDecimals_WhenLanguageIsItalian', () {
    Intl.defaultLocale = 'it';
    addTearDown(() => Intl.defaultLocale = null);
    expect(km(42300), '42,3 km');
    expect(kmh(7.8), '28,1 km/h');
  });

  test('duration_ShouldRoundToTheNearestMinute_WhenGivenSeconds', () {
    expect(duration(299), '5 min'); // not "4 min"
    expect(duration(5400), '1 h 30 min');
    expect(duration(3720), '1 h 02 min');
    expect(duration(3599), '1 h 00 min'); // 59.98 min rounds up to the hour
    expect(duration(null), '–');
  });

  test('stopwatch_ShouldShowSeconds_WhenGivenElapsedSeconds', () {
    expect(stopwatch(0), '0:00');
    expect(stopwatch(65), '1:05');
    expect(stopwatch(3723), '1:02:03');
    expect(stopwatch(null), '–');
  });
}
