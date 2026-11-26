import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../core/tokens.dart';
import '../../core/widgets/app_map.dart';
import '../../l10n/generated/app_localizations.dart';

String ridePaceName(AppLocalizations l10n, String pace) => switch (pace) {
  'easy' => l10n.ridePaceEasy,
  'fast' => l10n.ridePaceFast,
  _ => l10n.ridePaceSteady,
};

/// The wall clock the ride was planned at, not the clock of the phone looking at it: an eight o'clock ride is eight
/// wherever the member is, because the offset was kept with the instant.
///
/// Every date on a club ride is `intl`'s `DateFormat` in the language on screen, so one page never shows two styles
/// side by side (`docs/design/pages/README.md`, *In Flutter*).
String rideStartText(
  BuildContext context,
  DateTime startsAt,
  int utcOffsetMinutes,
) =>
    DateFormat.MMMEd(Localizations.localeOf(context).toLanguageTag())
        .add_Hm()
        .format(_wallClock(startsAt, utcOffsetMinutes));

/// The ride's day number and short month, for the date block that leads its calendar row.
({String day, String month}) rideDateBlock(
  DateTime startsAt,
  int utcOffsetMinutes, {
  String? locale,
}) {
  final local = _wallClock(startsAt, utcOffsetMinutes);
  return (
    day: DateFormat.d(locale).format(local),
    month: DateFormat.MMM(locale).format(local),
  );
}

/// The ride's wall clock without the date, which its date block already carries: "Sat 08:30".
String rideRowTime(
  BuildContext context,
  DateTime startsAt,
  int utcOffsetMinutes,
) =>
    DateFormat.E(Localizations.localeOf(context).toLanguageTag())
        .add_jm()
        .format(_wallClock(startsAt, utcOffsetMinutes));

/// The ride's own clock: the instant moved by the offset kept with it.
DateTime _wallClock(DateTime startsAt, int utcOffsetMinutes) =>
    startsAt.toUtc().add(Duration(minutes: utcOffsetMinutes));

/// How many are in, or how many places are left.
String ridePlaces(AppLocalizations l10n, ClubRideSummaryResponse ride) =>
    ride.maxRiders == null
    ? l10n.rideCountIn(ride.signUpCount)
    : l10n.ridePlacesLeft(
        (ride.maxRiders! - ride.signUpCount).clamp(0, ride.maxRiders!),
        ride.maxRiders!,
      );

/// The meeting point on the project's own map, as a pin over tiles. Read-only.
class MeetingMap extends StatelessWidget {
  const MeetingMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.tileUrl,
    this.attribution,
  });

  final double latitude;
  final double longitude;
  final String? tileUrl;
  final String? attribution;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.medium),
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: AppMap(
        tileUrl: tileUrl,
        attribution: attribution,
        center: (lat: latitude, lon: longitude),
        zoom: 15,
        overlay: [
          Center(
            child: Icon(
              Icons.place,
              key: const Key('meeting-pin'),
              size: AppIconSize.large,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    ),
  );
}

/// The line under a ride's title: where it meets and at what pace, with the route it follows. No-drop and the places
/// are badges of their own, as the mock-up draws the row.
String rideSubtitle(AppLocalizations l10n, ClubRideSummaryResponse ride) => [
  ride.meetingName,
  ridePaceName(l10n, ride.pace),
  if (ride.routeName != null) ride.routeName!,
].join(' · ');
