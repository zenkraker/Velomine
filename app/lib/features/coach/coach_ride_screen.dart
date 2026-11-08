import 'package:flutter/material.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../rides/detail/route_map.dart';
import '../rides/detail/series_chart.dart';
import 'coach_controllers.dart';

/// One shared ride, read-only: numbers, charts and (only when shared) the route.
class CoachRideScreen extends StatefulWidget {
  const CoachRideScreen({
    super.key,
    required this.controller,
    required this.clubId,
    required this.userId,
    required this.rideId,
    required this.onBack,
    this.tileUrl,
    this.attribution,
  });

  final CoachRideController controller;
  final String clubId;
  final String userId;
  final String rideId;
  final VoidCallback onBack;
  final String? tileUrl;
  final String? attribution;

  @override
  State<CoachRideScreen> createState() => _CoachRideScreenState();
}

class _CoachRideScreenState extends State<CoachRideScreen> {
  CoachRideController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.load(widget.clubId, widget.userId, widget.rideId);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final l10n = context.l10n;
        final text = Theme.of(context).textTheme;
        final ride = c.ride;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    Row(
                      children: [
                        TextButton.icon(
                          key: const Key('coach-ride-back'),
                          onPressed: widget.onBack,
                          icon: const Icon(Icons.arrow_back),
                          label: Text(l10n.athletesTitle),
                        ),
                        const Spacer(),
                      ],
                    ),
                    if (c.notFound)
                      Text(
                        l10n.coachRideNotFound,
                        key: const Key('coach-ride-not-found'),
                        style: text.titleMedium,
                      )
                    else if (c.loading && ride == null)
                      const Center(child: CircularProgressIndicator())
                    else if (ride != null) ...[
                      Text(
                        dateTime(ride.startTime ?? ride.uploadedAt),
                        style: text.headlineSmall,
                      ),
                      Text(l10n.coachReadOnly, style: text.bodySmall),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          _Value(l10n.statDistance, km(ride.distanceM)),
                          _Value(l10n.statMovingTime, duration(ride.movingS)),
                          _Value(l10n.statAverageSpeed, kmh(ride.avgSpeedMs)),
                          if (ride.avgPowerW != null)
                            _Value(
                              l10n.statAveragePower,
                              '${ride.avgPowerW} W',
                            ),
                          if (ride.normalizedPowerW != null)
                            _Value(
                              l10n.statNormalizedPower,
                              '${ride.normalizedPowerW} W',
                            ),
                          if (ride.avgHeartRate != null)
                            _Value(
                              l10n.statAverageHeartRate,
                              '${ride.avgHeartRate} bpm',
                            ),
                          if (ride.tss != null)
                            _Value(l10n.statTss, ride.tss!.round().toString()),
                          if (ride.trimp != null)
                            _Value(
                              l10n.statTrimp,
                              ride.trimp!.round().toString(),
                            ),
                        ],
                      ),
                      if (c.error != null)
                        Text(
                          failureText(l10n, c.error!),
                          key: const Key('coach-ride-error'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      if (c.data != null && c.data!.hasRoute)
                        RouteMap(
                          data: c.data!,
                          selected: c.selected,
                          tileUrl: widget.tileUrl,
                          attribution: widget.attribution,
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
                            selected: c.selected,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}
