import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/features/rides/ride_title.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';
import 'package:velomine_api/api.dart';

import 'fake_server.dart';

RideResponse ride({
  String? title,
  String startTime = '2026-11-01T07:30:00Z',
  int? utcOffsetMinutes,
  String? discipline,
  String? assist,
  String? environment,
  bool? commute,
}) => RideResponse.fromJson(
  rideJson(
    'r1',
    'ready',
    title: title,
    startTime: startTime,
    utcOffsetMinutes: utcOffsetMinutes,
    discipline: discipline,
    assist: assist,
    environment: environment,
    commute: commute,
  ),
)!;

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final it = lookupAppLocalizations(const Locale('it'));

  test('RideTitle_ShouldPreferTheMembersWords_WhenTheRideHasATitle', () {
    expect(
      rideTitle(en, ride(title: 'Dawn patrol', discipline: 'gravel')),
      'Dawn patrol',
    );
  });

  test('RideTitle_ShouldNameTheRideByItsHourAndType_WhenItHasNoTitle', () {
    // 07:30 UTC with no recorded offset is read on the device's clock; the offset here keeps it morning.
    expect(
      rideTitle(en, ride(discipline: 'gravel', utcOffsetMinutes: 0)),
      'Morning gravel ride',
    );
    expect(
      rideTitle(
        en,
        ride(
          discipline: 'road',
          startTime: '2026-11-01T18:00:00Z',
          utcOffsetMinutes: 0,
        ),
      ),
      'Evening road ride',
    );
    expect(
      rideTitle(
        en,
        ride(
          discipline: 'mountain',
          startTime: '2026-11-01T23:00:00Z',
          utcOffsetMinutes: 0,
        ),
      ),
      'Night mountain bike ride',
    );
  });

  test('RideTitle_ShouldSayWhatKindOfRideItWas_WhenSeveralKindsApply', () {
    // A commute says more than the surface; indoor or virtual says more than both.
    expect(
      rideTitle(
        en,
        ride(discipline: 'road', commute: true, utcOffsetMinutes: 0),
      ),
      'Morning commute',
    );
    expect(
      rideTitle(
        en,
        ride(discipline: 'road', environment: 'indoor', utcOffsetMinutes: 0),
      ),
      'Morning indoor ride',
    );
    expect(
      rideTitle(en, ride(assist: 'ebike', utcOffsetMinutes: 0)),
      'Morning e-bike ride',
    );
    expect(rideTitle(en, ride(utcOffsetMinutes: 0)), 'Morning ride');
  });

  test('RideTitle_ShouldFollowTheShownLanguage_WhenTheNameIsMadeUp', () {
    expect(
      rideTitle(it, ride(discipline: 'gravel', utcOffsetMinutes: 0)),
      'Uscita gravel del mattino',
    );
  });
}
