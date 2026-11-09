import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import 'coach_athletes_view_model.dart';

/// The athletes in this club who share rides or training.
class CoachAthletesScreen extends ConsumerWidget {
  const CoachAthletesScreen({
    super.key,
    required this.clubId,
    required this.onOpen,
  });

  final String clubId;
  final void Function(String userId) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(coachAthletesViewModelProvider(clubId));
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Text(
                  l10n.athletesTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (s.load.failure case final failure?)
                  Text(
                    failureText(l10n, failure),
                    key: const Key('coach-athletes-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (s.load.running && s.athletes.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (s.athletes.isEmpty)
                  Text(l10n.athletesEmpty, key: const Key('no-athletes')),
                for (final athlete in s.athletes)
                  Card(
                    key: Key('athlete-${athlete.userId}'),
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(athlete.displayName),
                      subtitle: Text(
                        [
                          if (athlete.lastRideAt != null)
                            l10n.lastRideOn(dateTime(athlete.lastRideAt)),
                          if (athlete.tss7 != null)
                            '${l10n.days7}: ${athlete.tss7!.round()} TSS',
                          if (athlete.tss42 != null)
                            '${l10n.days42}: ${athlete.tss42!.round()} TSS',
                          if (athlete.lastRideAt == null &&
                              athlete.tss7 == null) ...[
                            if (athlete.sharesRides) l10n.sharesRides,
                            if (athlete.sharesAnalytics) l10n.sharesTraining,
                            if (athlete.sharesWellbeing) l10n.sharesWellbeing,
                          ],
                        ].join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => onOpen(athlete.userId),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
