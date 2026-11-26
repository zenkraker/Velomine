import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:velomine/l10n/generated/app_localizations_en.dart';
import 'package:velomine/l10n/generated/app_localizations_it.dart';
import 'package:velomine/core/format.dart';
import 'package:velomine/core/units.dart';

void main() {
  setUpAll(() async {
    // The Italian month and weekday names, which a `DateFormat` pattern needs; `Intl.defaultLocale`
    // alone only reaches the number symbols.
    await initializeDateFormatting('en');
    await initializeDateFormatting('it');
  });
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

  test('Decimal_ShouldUseCommaAndFullStop_WhenTheLanguageChanges', () {
    expect(decimal(69.7, 1), '69.7');
    expect(decimal(1.03, 2), '1.03');
    Intl.defaultLocale = 'it';
    addTearDown(() => Intl.defaultLocale = null);
    expect(decimal(69.7, 1), '69,7');
    expect(decimal(1.03, 2), '1,03');
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

  test('distanceParts_ShouldSplitValueAndUnit_WhenMetric', () {
    final parts = distanceParts(Units.metric, 69700);
    expect(parts.value, '69.7');
    expect(parts.unit, 'km');
    expect(distanceIn(Units.metric, 69700), closeTo(69.7, 0.001));
  });

  test('distanceParts_ShouldSplitValueAndUnit_WhenImperial', () {
    final parts = distanceParts(Units.imperial, 42300);
    expect(parts.value, '26.3');
    expect(parts.unit, 'mi');
    expect(distanceIn(Units.imperial, 42300), closeTo(26.28, 0.01));
  });

  test('distanceParts_ShouldReturnADashAndNoUnit_WhenDistanceIsNull', () {
    expect(distanceParts(Units.metric, null), (value: '–', unit: null));
    expect(distanceParts(Units.imperial, null), (value: '–', unit: null));
  });

  test('km_ShouldKeepItsText_WhenBuiltOnDistanceParts', () {
    for (final (units, metres) in [
      (Units.metric, 42300.0),
      (Units.metric, 150000.0),
      (Units.metric, 999.0),
      (Units.imperial, 1609.344),
      (Units.imperial, 42300.0),
      (Units.imperial, 200000.0),
    ]) {
      final parts = distanceParts(units, metres);
      expect(
        km(units, metres),
        '${parts.value} ${parts.unit}',
        reason: '$metres',
      );
    }
  });

  test('WeekdayShort_ShouldShowTheDayWithItsWeekday_WhenLanguageIsEnglish', () {
    // A Sunday, so the weekday is unambiguous.
    final sunday = DateTime(2026, 11, 1);
    expect(weekdayShort(sunday), 'Sun 1 Nov');
    expect(weekdayShort(null), '–');
  });

  test('WeekdayShort_ShouldShowTheDayWithItsWeekday_WhenLanguageIsItalian', () {
    Intl.defaultLocale = 'it';
    addTearDown(() => Intl.defaultLocale = null);
    expect(weekdayShort(DateTime(2026, 11, 1)), 'dom 1 nov');
  });

  test('MonthShort_ShouldAbbreviateTheMonth_WhenLanguageChanges', () {
    expect(monthShort(DateTime(2026, 11, 16)), 'Nov');
    expect(monthShort(null), '–');
    Intl.defaultLocale = 'it';
    addTearDown(() => Intl.defaultLocale = null);
    expect(monthShort(DateTime(2026, 11, 16)), 'nov');
  });

  test('DayNumber_ShouldGiveTheDayOfTheMonth_WhenGivenADate', () {
    expect(dayNumber(DateTime(2026, 11, 16)), '16');
    expect(dayNumber(DateTime(2026, 11, 1)), '1');
    expect(dayNumber(null), '–');
  });

  // The relative words live in the `.arb` files; the date fallback still follows the locale.
  final en = AppLocalizationsEn();
  final it = AppLocalizationsIt();

  test('RelativeTime_ShouldSayNow_WhenTheMomentIsWithinTheMinute', () {
    final now = DateTime(2026, 11, 16, 12);
    expect(relativeTime(en, now, now: now), 'now');
    expect(
      relativeTime(en, now.subtract(const Duration(seconds: 30)), now: now),
      'now',
    );
  });

  test('RelativeTime_ShouldCountMinutesAndHours_WhenTheMomentIsToday', () {
    final now = DateTime(2026, 11, 16, 12);
    expect(
      relativeTime(en, now.subtract(const Duration(minutes: 40)), now: now),
      '40 min ago',
    );
    expect(
      relativeTime(en, now.subtract(const Duration(hours: 2)), now: now),
      '2 h ago',
    );
  });

  test('RelativeTime_ShouldSpeakItalian_WhenLanguageIsItalian', () {
    Intl.defaultLocale = 'it';
    addTearDown(() => Intl.defaultLocale = null);
    final now = DateTime(2026, 11, 16, 12);
    expect(
      relativeTime(it, now.subtract(const Duration(hours: 2)), now: now),
      '2 h fa',
    );
    expect(
      relativeTime(it, now.subtract(const Duration(days: 1)), now: now),
      'ieri',
    );
  });

  test('RelativeTime_ShouldSayYesterday_WhenTheMomentWasTheDayBefore', () {
    final now = DateTime(2026, 11, 16, 9);
    expect(
      relativeTime(en, now.subtract(const Duration(hours: 20)), now: now),
      'yesterday',
    );
  });

  test('RelativeTime_ShouldShowTheDate_WhenTheMomentIsOlderThanYesterday', () {
    final now = DateTime(2026, 11, 16, 9);
    expect(relativeTime(en, DateTime(2026, 11, 2, 8), now: now), 'Nov 2');
    // A plan is a date, not a memory.
    expect(relativeTime(en, DateTime(2026, 11, 20), now: now), 'Nov 20');
    // A year has passed: the year comes back.
    expect(relativeTime(en, DateTime(2024, 11, 2), now: now), 'Nov 2, 2024');
    expect(relativeTime(en, null), '–');
  });

  test('RelativeTime_ShouldShowTheDate_WhenLanguageIsItalian', () {
    Intl.defaultLocale = 'it';
    addTearDown(() => Intl.defaultLocale = null);
    final now = DateTime(2026, 11, 16, 9);
    expect(relativeTime(it, DateTime(2026, 11, 2), now: now), '2 nov');
  });
}
