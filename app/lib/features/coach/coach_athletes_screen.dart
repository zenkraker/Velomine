import '../../core/widgets/loading_state.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../l10n/generated/app_localizations.dart';
import 'coach_athletes_view_model.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';

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
    return PageScaffold(
      title: l10n.athletesTitle,
      parent: l10n.navClub,
      subtitle: l10n.athletesSubtitle,
      children: [
        if (s.load.failure case final failure?)
          ErrorState(
            message: failureText(l10n, failure),
            actionKey: const Key('coach-athletes-error'),
            onRetry: () => ref
                .read(coachAthletesViewModelProvider(clubId).notifier)
                .refresh(),
          ),
        if (s.load.running && s.athletes.isEmpty)
          const LoadingState.rows()
        else if (s.athletes.isEmpty)
          EmptyState(
            key: const Key('no-athletes'),
            message: l10n.athletesEmpty,
            icon: Icons.people_outline,
          )
        else
          // One list card: every athlete is a row, with what they share beside their name.
          AppCard(
            key: const Key('athletes-card'),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              children: [
                for (final (i, athlete) in s.athletes.indexed) ...[
                  if (i > 0) const Divider(),
                  ListTile(
                    key: Key('athlete-${athlete.userId}'),
                    contentPadding: EdgeInsets.zero,
                    leading: Avatar(athlete.displayName),
                    // The row's lines are the design's body and caption, not the tile's own defaults.
                    title: Text(
                      athlete.displayName,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    // What they share sits under the name, so a phone's narrow row keeps its width for the
                    // name instead of giving it to the badges.
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpacing.xs,
                      children: [
                        Text(
                          _loadLine(l10n, athlete),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            if (athlete.sharesRides) AppBadge(l10n.sharesRides),
                            if (athlete.sharesAnalytics)
                              AppBadge(l10n.sharesTraining),
                            if (athlete.sharesWellbeing)
                              AppBadge(l10n.sharesWellbeing),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => onOpen(athlete.userId),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// The last ride and the training load; what the athlete shares is a badge of its own.
String _loadLine(AppLocalizations l10n, CoachAthleteResponse athlete) => [
  if (athlete.lastRideAt != null) l10n.lastRideOn(dateTime(athlete.lastRideAt)),
  if (athlete.tss7 != null) '${l10n.days7}: ${athlete.tss7!.round()} TSS',
  if (athlete.tss42 != null) '${l10n.days42}: ${athlete.tss42!.round()} TSS',
].join(' · ');
