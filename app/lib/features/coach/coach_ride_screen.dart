import 'package:material_ui/material_ui.dart';
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
import '../../core/units.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';
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
    final units = ref.watch(unitsChoiceViewModelProvider);
    final ride = c.ride;
    return PageScaffold(
      eyebrow: l10n.athletesTitle,
      title: ride == null
          ? l10n.rideDetailTitle
          : dateTime(ride.startTime ?? ride.uploadedAt),
      subtitle: l10n.coachReadOnly,
      children: [
        if (c.notFound)
          EmptyState(
            key: const Key('coach-ride-not-found'),
            message: l10n.coachRideNotFound,
            icon: Icons.search_off,
          )
        else if (c.load.running && ride == null)
          const Center(child: CircularProgressIndicator())
        else if (ride != null) ...[
          if (rideTypeIsSet(ride)) RideTypeChips(ride: ride),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: 12,
            children: [
              StatTile(
                label: l10n.statDistance,
                value: km(units, ride.distanceM),
              ),
              StatTile(
                label: l10n.statMovingTime,
                value: duration(ride.movingS),
              ),
              StatTile(
                label: l10n.statAverageSpeed,
                value: kmh(units, ride.avgSpeedMs),
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
            ErrorState(
              message: failureText(l10n, failure),
              actionKey: const Key('coach-ride-error'),
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
    );
  }
}
