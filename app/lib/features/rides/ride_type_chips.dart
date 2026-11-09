import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/l10n.dart';
import '../../l10n/generated/app_localizations.dart';

/// The member-facing name of a surface.
String disciplineName(AppLocalizations l10n, String discipline) =>
    switch (discipline) {
      'road' => l10n.bikeKindRoad,
      'gravel' => l10n.bikeKindGravel,
      'mountain' => l10n.bikeKindMountain,
      'track' => l10n.bikeKindTrack,
      _ => discipline,
    };

/// Whether any of the four dimensions has been set.
bool rideTypeIsSet(RideResponse ride) =>
    ride.discipline != null ||
    ride.assist != null ||
    ride.environment != null ||
    ride.commute != null;

/// One small label per dimension that is set and worth showing. Outdoor and "no e-bike" are the defaults,
/// so they are left out instead of filling the card with noise.
List<(String, String)> rideTypeLabels(
  AppLocalizations l10n,
  RideResponse ride,
) {
  final labels = <(String, String)>[];
  if (ride.discipline case final discipline?) {
    labels.add(('discipline-$discipline', disciplineName(l10n, discipline)));
  }
  if (ride.assist == 'ebike') labels.add(('assist-ebike', l10n.bikeKindEbike));
  if (ride.environment == 'indoor') {
    labels.add(('environment-indoor', l10n.rideTypeIndoor));
  }
  if (ride.environment == 'virtual') {
    labels.add(('environment-virtual', l10n.rideTypeVirtual));
  }
  if (ride.commute == true) labels.add(('commute', l10n.rideTypeCommute));
  return labels;
}

/// The ride's dimensions as compact chips. Renders nothing when all four are unset.
class RideTypeChips extends StatelessWidget {
  const RideTypeChips({super.key, required this.ride});

  final RideResponse ride;

  @override
  Widget build(BuildContext context) {
    final labels = rideTypeLabels(context.l10n, ride);
    if (labels.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final (key, label) in labels)
          Container(
            key: Key('ride-type-$key'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: colors.onSecondaryContainer),
            ),
          ),
      ],
    );
  }
}
