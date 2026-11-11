import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../rides/detail/lap_table.dart';
import '../rides/detail/ride_selection.dart';
import '../rides/detail/route_map.dart';
import '../rides/detail/series_chart.dart';
import '../rides/ride_type_chips.dart';
import 'coach_ride_view_model.dart';
import '../../core/tokens.dart';
import '../../core/widgets/stat_tile.dart';

/// One shared ride, read-only: numbers, charts and (only when shared) the route.
class CoachRideScreen extends ConsumerWidget {
  const CoachRideScreen({
    super.key,
    required this.clubId,
    required this.userId,
    required this.rideId,
    this.tileUrl,
    this.attribution,
  });

  final String clubId;
  final String userId;
  final String rideId;
  final String? tileUrl;
  final String? attribution;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(coachRideViewModelProvider(clubId, userId, rideId));
    final selection = ref.watch(
      rideSelectionProvider('coach:$clubId:$userId:$rideId'),
    );
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final ride = c.ride;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                if (c.notFound)
                  Text(
                    l10n.coachRideNotFound,
                    key: const Key('coach-ride-not-found'),
                    style: text.titleMedium,
                  )
                else if (c.load.running && ride == null)
                  const Center(child: CircularProgressIndicator())
                else if (ride != null) ...[
                  Text(
                    dateTime(ride.startTime ?? ride.uploadedAt),
                    style: text.headlineSmall,
                  ),
                  Text(l10n.coachReadOnly, style: text.bodySmall),
                  if (rideTypeIsSet(ride)) RideTypeChips(ride: ride),
                  Wrap(
                    spacing: AppSpacing.xl,
                    runSpacing: 12,
                    children: [
                      StatTile(
                        label: l10n.statDistance,
                        value: km(ride.distanceM),
                      ),
                      StatTile(
                        label: l10n.statMovingTime,
                        value: duration(ride.movingS),
                      ),
                      StatTile(
                        label: l10n.statAverageSpeed,
                        value: kmh(ride.avgSpeedMs),
                      ),
                      if (ride.avgPowerW != null)
                        StatTile(
                          label: l10n.statAveragePower,
                          value: '${ride.avgPowerW} W',
                        ),
                      if (ride.normalizedPowerW != null)
                        StatTile(
                          label: l10n.statNormalizedPower,
                          value: '${ride.normalizedPowerW} W',
                        ),
                      if (ride.avgHeartRate != null)
                        StatTile(
                          label: l10n.statAverageHeartRate,
                          value: '${ride.avgHeartRate} bpm',
                        ),
                      if (ride.tss != null)
                        StatTile(
                          label: l10n.statTss,
                          value: ride.tss!.round().toString(),
                        ),
                      if (ride.trimp != null)
                        StatTile(
                          label: l10n.statTrimp,
                          value: ride.trimp!.round().toString(),
                        ),
                    ],
                  ),
                  if (c.load.failure case final failure?)
                    Text(
                      failureText(l10n, failure),
                      key: const Key('coach-ride-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (c.laps.isNotEmpty)
                    LapTable(laps: c.laps, selectedLap: selection.selectedLap),
                  if (c.data != null && c.data!.hasRoute)
                    RouteMap(
                      data: c.data!,
                      selected: selection.selected,
                      selectedLap: selection.selectedLap,
                      tileUrl: tileUrl,
                      attribution: attribution,
                    )
                  else if (c.data != null)
                    Text(
                      l10n.routeNotShared,
                      key: const Key('route-not-shared'),
                      style: text.bodySmall,
                    ),
                  if (c.data != null && c.data!.series.isNotEmpty)
                    for (final series in c.data!.series)
                      SeriesChart(
                        series: series,
                        time: c.data!.time,
                        selected: selection.selected,
                        selectedLap: selection.selectedLap,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
