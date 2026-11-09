import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../progress/power_summary.dart';
import '../progress/training_summary.dart';
import 'coach_athlete_view_model.dart';

/// One athlete as their coach sees them: shared summary, training load and recent rides.
class CoachAthleteScreen extends ConsumerWidget {
  const CoachAthleteScreen({
    super.key,
    required this.clubId,
    required this.userId,
    required this.onBack,
    required this.onOpenRide,
  });

  final String clubId;
  final String userId;
  final VoidCallback onBack;
  final void Function(String rideId) onOpenRide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(coachAthleteViewModelProvider(clubId, userId));
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
                    onPressed: onBack,
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
                else if (c.load.running && summary == null)
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
                      if (summary.sharesWellbeing)
                        Chip(label: Text(l10n.sharesWellbeing)),
                    ],
                  ),
                  if (c.load.failure case final failure?)
                    Text(
                      failureText(l10n, failure),
                      key: const Key('coach-athlete-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (c.training case final training?)
                    TrainingSummary(
                      training: training,
                      days: c.days,
                      onDays: (days) => ref
                          .read(
                            coachAthleteViewModelProvider(
                              clubId,
                              userId,
                            ).notifier,
                          )
                          .setDays(days),
                    ),
                  if (c.powerCurve case final curve?)
                    PowerSummary(
                      curve: curve,
                      days: c.days,
                      onDays: (days) => ref
                          .read(
                            coachAthleteViewModelProvider(
                              clubId,
                              userId,
                            ).notifier,
                          )
                          .setDays(days),
                      readOnly: true,
                    ),
                  if (c.wellbeing case final wellbeing?)
                    _CoachWellbeingCard(wellbeing: wellbeing),
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
                                  dateTime(ride.startTime ?? ride.uploadedAt),
                                ),
                                subtitle: Text(
                                  '${km(ride.distanceM)} · '
                                  '${duration(ride.movingS)}',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => onOpenRide(ride.id),
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
  }
}

/// What a coach may see of wellbeing: daily scores and per-ride RPE, never the member's notes.
class _CoachWellbeingCard extends StatelessWidget {
  const _CoachWellbeingCard({required this.wellbeing});

  final CoachWellbeingResponse wellbeing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    String date(DateTime value) => DateFormat.MMMd(locale).format(value);

    return Card(
      key: const Key('coach-wellbeing'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.coachWellbeing, style: text.titleMedium),
            const SizedBox(height: 4),
            Text(l10n.coachWellbeingNoNotes, style: text.bodySmall),
            if (wellbeing.checkIns.isEmpty && wellbeing.rides.isEmpty) ...[
              const SizedBox(height: 8),
              Text(l10n.coachWellbeingEmpty, style: text.bodyMedium),
            ],
            for (final checkIn in wellbeing.checkIns)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${date(checkIn.date)} · '
                  '${l10n.wellbeingShortFatigue} ${checkIn.fatigue} · '
                  '${l10n.wellbeingShortSoreness} ${checkIn.soreness} · '
                  '${l10n.wellbeingShortMood} ${checkIn.mood} · '
                  '${l10n.wellbeingShortStress} ${checkIn.stress} · '
                  '${l10n.wellbeingShortMotivation} ${checkIn.motivation}',
                  style: text.bodySmall,
                ),
              ),
            for (final ride in wellbeing.rides)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${date(ride.date)} · ${l10n.wellbeingRpeSaved(ride.rpe)}',
                  style: text.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
