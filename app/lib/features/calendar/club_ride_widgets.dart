import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/map_defaults.dart';
import '../../core/widgets/chart_chrome.dart';
import '../../l10n/generated/app_localizations.dart';
import '../rides/detail/geo.dart';

String ridePaceName(AppLocalizations l10n, String pace) => switch (pace) {
  'easy' => l10n.ridePaceEasy,
  'fast' => l10n.ridePaceFast,
  _ => l10n.ridePaceSteady,
};

/// The wall clock the ride was planned at, not the clock of the phone looking at it: an eight o'clock ride is eight
/// wherever the member is, because the offset was kept with the instant.
String rideStartText(
  BuildContext context,
  DateTime startsAt,
  int utcOffsetMinutes,
) {
  final local = startsAt.toUtc().add(Duration(minutes: utcOffsetMinutes));
  final date = MaterialLocalizations.of(context).formatMediumDate(local);
  final time = TimeOfDay.fromDateTime(local).format(context);
  return '$date · $time';
}

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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: LayoutBuilder(
          builder: (context, box) {
            final size = Size(box.maxWidth, box.maxHeight);
            final view = MapView.centered(
              center: (lat: latitude, lon: longitude),
              size: size,
              zoom: 15,
            );
            return ColoredBox(
              color: scheme.surfaceContainerHighest,
              child: Stack(
                children: [
                  if (tileUrl != null)
                    for (final tile in view.tiles(tileUrl!))
                      Positioned(
                        left: tile.left,
                        top: tile.top,
                        width: view.tilePixels,
                        height: view.tilePixels,
                        child: Image.network(
                          tile.url,
                          key: Key('meeting-tile-${tile.url}'),
                          headers: mapTileHeaders,
                          fit: BoxFit.fill,
                          webHtmlElementStrategy:
                              WebHtmlElementStrategy.fallback,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                  Center(
                    child: Icon(
                      Icons.place,
                      key: const Key('meeting-pin'),
                      size: 40,
                      color: scheme.error,
                    ),
                  ),
                  if (tileUrl != null &&
                      attribution != null &&
                      attribution!.isNotEmpty)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: MapAttribution(text: attribution!),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The line under a ride's title: the meeting point, the pace and how many are in.
String rideSubtitle(AppLocalizations l10n, ClubRideSummaryResponse ride) => [
  ride.meetingName,
  ridePaceName(l10n, ride.pace),
  if (ride.noDrop) l10n.rideNoDrop,
  if (ride.routeName != null) ride.routeName!,
  ridePlaces(l10n, ride),
].join(' · ');
