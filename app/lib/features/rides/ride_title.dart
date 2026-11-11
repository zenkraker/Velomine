import 'package:velomine_api/api.dart';

import '../../l10n/generated/app_localizations.dart';

/// The name a ride shows: the member's own title, or one made from when and what kind of ride it was
/// ("Morning gravel ride"). The made-up name is worked out here, at display time, and never stored, so
/// it follows the language the app is showing.
String rideTitle(AppLocalizations l10n, RideResponse ride) {
  final own = ride.title?.trim();
  if (own != null && own.isNotEmpty) return own;
  return l10n.rideDefaultTitle(ridePeriod(ride), rideKind(ride));
}

/// Morning, afternoon, evening or night on the rider's own clock: the ride's recorded offset when the
/// server has one, otherwise this device's zone.
String ridePeriod(RideResponse ride) {
  final start = ride.startTime ?? ride.uploadedAt;
  final offset = ride.utcOffsetMinutes;
  final local = offset == null
      ? start.toLocal()
      : start.toUtc().add(Duration(minutes: offset));
  final hour = local.hour;
  if (hour >= 5 && hour < 12) return 'morning';
  if (hour >= 12 && hour < 17) return 'afternoon';
  if (hour >= 17 && hour < 22) return 'evening';
  return 'night';
}

/// The one word that says most about the ride: a commute or an indoor ride says more than the surface.
String rideKind(RideResponse ride) {
  if (ride.commute == true) return 'commute';
  if (ride.environment == 'virtual') return 'virtual';
  if (ride.environment == 'indoor') return 'indoor';
  if (ride.discipline case final discipline?
      when const ['road', 'gravel', 'mountain', 'track'].contains(discipline)) {
    return discipline;
  }
  if (ride.assist == 'ebike') return 'ebike';
  return 'other';
}
