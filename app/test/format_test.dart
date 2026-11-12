import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:velomine/core/format.dart';
import 'package:velomine/core/units.dart';

void main() {
  test('Format_ShouldShowDistancesInKmAndKmh_WhenGivenMetres', () {
    expect(km(Units.metric, 42300), '42.3 km');
    expect(km(Units.metric, 150000), '150 km');
    expect(km(Units.metric, null), '–');
    expect(kmh(Units.metric, 7.8), '28.1 km/h');
  });

  test('Distance_ShouldShowMiles_WhenUnitsAreImperial', () {
    expect(km(Units.imperial, 1609.344), '1.0 mi');
    expect(km(Units.imperial, 42300), '26.3 mi');
    expect(km(Units.imperial, null), '–');
  });

  test('Speed_ShouldShowMph_WhenUnitsAreImperial', () {
    expect(kmh(Units.imperial, 10), '22.4 mph');
    expect(kmh(Units.imperial, null), '–');
  });

  test('Elevation_ShouldShowFeet_WhenUnitsAreImperial', () {
    expect(elevation(Units.metric, 620), '620 m');
    expect(elevation(Units.imperial, 620), '2034 ft');
    expect(elevation(Units.imperial, 620, up: true), '2034 ft ↑');
    expect(elevation(Units.imperial, null), '–');
  });

  test('Weight_ShouldShowPounds_WhenUnitsAreImperial', () {
    expect(weight(Units.metric, 72), '72.0 kg');
    expect(weight(Units.imperial, 72), '158.7 lb');
    expect(weight(Units.imperial, null), '–');
  });

  test('Length_ShouldKeepMetresBelowAKilometre_WhenUnitsAreMetric', () {
    expect(length(Units.metric, 500), '500 m');
  });

  test('Length_ShouldShowMilesOrFeet_WhenUnitsAreImperial', () {
    // A privacy radius lives between 200 and 1609 m, so both shapes are reachable.
    expect(length(Units.imperial, 1609.344), '1.0 mi');
    expect(length(Units.imperial, 500), '0.3 mi');
    expect(length(Units.imperial, 100), '328 ft');
    expect(length(Units.imperial, null), '–');
  });

  test('DistanceUnit_ShouldNameTheUnitTheMemberReads', () {
    expect(distanceUnit(Units.metric), 'km');
    expect(distanceUnit(Units.imperial), 'mi');
    expect(elevationUnit(Units.metric), 'm');
    expect(elevationUnit(Units.imperial), 'ft');
  });

  test('Format_ShouldUseCommaDecimals_WhenLanguageIsItalian', () {
    Intl.defaultLocale = 'it';
    addTearDown(() => Intl.defaultLocale = null);
    expect(km(Units.metric, 42300), '42,3 km');
    expect(kmh(Units.metric, 7.8), '28,1 km/h');
    // The imperial symbols are the same in both languages.
    expect(weight(Units.imperial, 72), '158,7 lb');
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
