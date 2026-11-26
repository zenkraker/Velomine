import '../../core/widgets/loading_state.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../rides/detail/ride_selection.dart';
import '../rides/detail/route_map.dart';
import 'coach_athlete_view_model.dart';
import 'coach_ride_view_model.dart';
import '../../core/tokens.dart';
import '../../core/units.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/stat_card.dart';

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
    // Whose ride it is names the page's caption; the ride's own name is the title, the date when it has none.
    final athlete = ref.watch(
      coachAthleteViewModelProvider(
        clubId,
        userId,
      ).select((s) => s.summary?.displayName),
    );
    return PageScaffold(
      parent: athlete,
      title: ride == null
          ? l10n.rideDetailTitle
          : ride.title ?? dateTime(ride.startTime ?? ride.uploadedAt),
      subtitle: l10n.coachReadOnly,
      children: [
        if (c.notFound)
          EmptyState(
            key: const Key('coach-ride-not-found'),
            message: l10n.coachRideNotFound,
            icon: Icons.search_off,
          )
        else if (c.load.running && ride == null)
          const LoadingState()
        else if (ride != null) ...[
          // The map sits right under the header, before the numbers it belongs to.
          if (c.data != null && c.data!.hasRoute)
            RouteMap(
              data: c.data!,
              selected: selection.selected,
              selectedLap: selection.selectedLap,
              tileUrl: tileUrl,
              attribution: attribution,
              virtualWorld: ride.environment == 'virtual',
            )
          else if (c.data != null)
            Text(
              l10n.routeNotShared,
              key: const Key('route-not-shared'),
              style: text.bodySmall,
            ),
          // The mock-up's Numbers card: the four the coach leads with, then the four that follow them.
          SectionCard(
            key: const Key('coach-ride-numbers'),
            title: l10n.rideNumbers,
            children: [
              Wrap(
                spacing: AppSpacing.xl,
                runSpacing: AppSpacing.md,
                children: [
                  StatFigure(
                    label: l10n.statDistance,
                    value: km(units, ride.distanceM),
                  ),
                  StatFigure(
                    label: l10n.statMovingTime,
                    value: duration(ride.movingS),
                  ),
                  if (ride.avgPowerW != null)
                    StatFigure(
                      label: l10n.statAveragePower,
                      value: '${ride.avgPowerW} W',
                    ),
                  if (ride.tss != null)
                    StatFigure(
                      label: l10n.statTss,
                      value: ride.tss!.round().toString(),
                    ),
                ],
              ),
              Wrap(
                spacing: AppSpacing.xl,
                runSpacing: AppSpacing.md,
                children: [
                  StatFigure(
                    label: l10n.statAverageSpeed,
                    value: kmh(units, ride.avgSpeedMs),
                  ),
                  if (ride.normalizedPowerW != null)
                    StatFigure(
                      label: l10n.statNormalizedPower,
                      value: '${ride.normalizedPowerW} W',
                    ),
                  if (ride.avgHeartRate != null)
                    StatFigure(
                      label: l10n.statAverageHeartRate,
                      value: '${ride.avgHeartRate} bpm',
                    ),
                  if (ride.trimp != null)
                    StatFigure(
                      label: l10n.statTrimp,
                      value: ride.trimp!.round().toString(),
                    ),
                ],
              ),
            ],
          ),
          if (c.load.failure case final failure?)
            ErrorState(
              message: failureText(l10n, failure),
              actionKey: const Key('coach-ride-error'),
            ),
        ],
      ],
    );
  }
}
