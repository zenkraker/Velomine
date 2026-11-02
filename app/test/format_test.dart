import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/format.dart';

void main() {
  test('distances and speeds are shown in km and km/h', () {
    expect(km(42300), '42.3 km');
    expect(km(150000), '150 km');
    expect(km(null), '–');
    expect(kmh(7.8), '28.1 km/h');
  });

  test('durations are rounded to the nearest minute', () {
    expect(duration(299), '5 min'); // not "4 min"
    expect(duration(5400), '1 h 30 min');
    expect(duration(3720), '1 h 02 min');
    expect(duration(3599), '1 h 00 min'); // 59.98 min rounds up to the hour
    expect(duration(null), '–');
  });
}
