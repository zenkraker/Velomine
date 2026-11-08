import 'package:flutter/material.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../progress/training_summary.dart';
import 'coach_controllers.dart';

/// One athlete as their coach sees them: shared summary, training load and recent rides.
class CoachAthleteScreen extends StatefulWidget {
  const CoachAthleteScreen({
    super.key,
    required this.controller,
    required this.clubId,
    required this.userId,
    required this.onBack,
    required this.onOpenRide,
  });

  final CoachAthleteController controller;
  final String clubId;
  final String userId;
  final VoidCallback onBack;
  final void Function(String rideId) onOpenRide;

  @override
  State<CoachAthleteScreen> createState() => _CoachAthleteScreenState();
}

class _CoachAthleteScreenState extends State<CoachAthleteScreen> {
  CoachAthleteController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.load(widget.clubId, widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final l10n = context.l10n;
        final text = Theme.of(context).textTheme;
        final summary = c.summary;
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const Key('coach-back-to-athletes'),
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back),
                        label: Text(l10n.athletesTitle),
                      ),
                    ),
                    if (c.notFound)
                      Text(
                        l10n.coachAthleteNotFound,
                        key: const Key('coach-athlete-not-found'),
                        style: text.titleMedium,
                      )
                    else if (c.loading && summary == null)
                      const Center(child: CircularProgressIndicator())
                    else if (summary != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              summary.displayName,
                              style: text.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                      Text(l10n.coachReadOnly, style: text.bodySmall),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (summary.sharesRides)
                            Chip(label: Text(l10n.sharesRides)),
                          if (summary.sharesAnalytics)
                            Chip(label: Text(l10n.sharesTraining)),
                          if (summary.sharesRoutes)
                            Chip(label: Text(l10n.sharesRoutes)),
                        ],
                      ),
                      if (c.error != null)
                        Text(
                          failureText(l10n, c.error!),
                          key: const Key('coach-athlete-error'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      if (c.training case final training?)
                        TrainingSummary(
                          training: training,
                          days: c.days,
                          onDays: (days) =>
                              c.setDays(widget.clubId, widget.userId, days),
                        ),
                      if (summary.sharesRides) ...[
                        Text(l10n.shareRides, style: text.titleMedium),
                        if (c.rides.isEmpty)
                          Text(l10n.coachNoRides)
                        else
                          Card(
                            child: Column(
                              children: [
                                for (final ride in c.rides)
                                  ListTile(
                                    key: Key('coach-ride-${ride.id}'),
                                    leading: const Icon(Icons.directions_bike),
                                    title: Text(
                                      dateTime(
                                        ride.startTime ?? ride.uploadedAt,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${km(ride.distanceM)} · '
                                      '${duration(ride.movingS)}',
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => widget.onOpenRide(ride.id),
                                  ),
                              ],
                            ),
                          ),
                      ],
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
