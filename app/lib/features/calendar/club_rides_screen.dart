import '../../core/widgets/loading_state.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_card.dart';
import 'club_ride_widgets.dart';
import 'club_rides_view_model.dart';

class ClubRidesScreen extends ConsumerWidget {
  const ClubRidesScreen({
    super.key,
    required this.canPlan,
    required this.onOpen,
    required this.onPlan,
    required this.onCalendar,
  });

  final bool canPlan;
  final void Function(String id) onOpen;
  final VoidCallback onPlan;
  final VoidCallback onCalendar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(clubRidesViewModelProvider);

    listenUserMessages(
      ref,
      context,
      clubRidesViewModelProvider.select((s) => s.messages),
      ref.read(clubRidesViewModelProvider.notifier).messageShown,
    );

    return PageScaffold(
      title: l10n.clubRidesTitle,
      parent: l10n.clubCalendarCaption,
      subtitle: l10n.clubRidesSubtitle,
      primaryAction: canPlan
          ? FilledButton.icon(
              key: const Key('plan-ride'),
              onPressed: onPlan,
              icon: const Icon(Icons.add),
              label: Text(l10n.clubPlanRide),
            )
          : null,
      menu: PageMenu(
        buttonKey: const Key('club-rides-actions'),
        entries: [
          PageMenuEntry(
            key: const Key('open-calendar-feed'),
            icon: Icons.calendar_month_outlined,
            label: l10n.calendarTitle,
            onSelected: onCalendar,
          ),
        ],
      ),
      children: [
        if (s.load.failure case final failure?)
          ErrorState(
            message: failureText(l10n, failure),
            actionKey: const Key('club-rides-error'),
            onRetry: () =>
                ref.read(clubRidesViewModelProvider.notifier).refresh(),
          ),
        if (s.load.running && s.upcoming.isEmpty && s.past.isEmpty)
          const LoadingState()
        else if (s.upcoming.isEmpty && s.past.isEmpty && s.load.failure == null)
          EmptyState(
            key: const Key('no-club-rides'),
            message: l10n.ridesEmpty,
            icon: Icons.event_available,
            action: canPlan
                ? OutlinedButton.icon(
                    key: const Key('plan-ride-empty'),
                    onPressed: onPlan,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.clubPlanRide),
                  )
                : null,
          )
        else ...[
          if (s.upcoming.isNotEmpty)
            SectionCard(
              key: const Key('club-rides-upcoming'),
              title: l10n.ridesUpcoming,
              children: [
                for (final (i, ride) in s.upcoming.indexed) ...[
                  if (i > 0) const Divider(),
                  _RideRow(ride: ride, onOpen: onOpen),
                ],
              ],
            ),
          if (s.past.isNotEmpty)
            SectionCard(
              key: const Key('club-rides-past'),
              title: l10n.ridesPast,
              children: [
                for (final (i, ride) in s.past.indexed) ...[
                  if (i > 0) const Divider(),
                  _RideRow(ride: ride, onOpen: onOpen),
                ],
              ],
            ),
        ],
      ],
    );
  }
}

/// One ride in its list's card: its date block leads, then the name, the states and the details.
class _RideRow extends StatelessWidget {
  const _RideRow({required this.ride, required this.onOpen});

  final ClubRideSummaryResponse ride;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    // The mock-up draws the states as badges after the fact and keeps pace and place in the line.
    final badges = [
      if (ride.isCancelled)
        AppBadge(l10n.rideCancelled, tone: AppBadgeTone.bad)
      else ...[
        if (ride.noDrop) AppBadge(l10n.rideNoDrop),
        if (ride.isSignedUp)
          AppBadge(l10n.rideSignedUp, tone: AppBadgeTone.good)
        else if (ride.isFull)
          AppBadge(l10n.rideFull, tone: AppBadgeTone.care)
        else
          AppBadge(ridePlaces(l10n, ride)),
      ],
    ];
    return InkWell(
      key: Key('club-ride-${ride.id}'),
      onTap: () => onOpen(ride.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            _RideDateBlock(ride: ride),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ride.title,
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        [
                          rideRowTime(
                            context,
                            ride.startsAt,
                            ride.utcOffsetMinutes,
                          ),
                          rideSubtitle(l10n, ride),
                          if (ride.createdByName != null)
                            l10n.ridePlannedBy(ride.createdByName!),
                        ].join(' · '),
                        style: text.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: badges,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The day and the month of the ride's wall clock, as the row's leading block.
class _RideDateBlock extends StatelessWidget {
  const _RideDateBlock({required this.ride});

  final ClubRideSummaryResponse ride;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final date = rideDateBlock(
      ride.startsAt,
      ride.utcOffsetMinutes,
      locale: Localizations.localeOf(context).toLanguageTag(),
    );
    return Container(
      key: Key('club-ride-date-${ride.id}'),
      width: AppTraining.dateWidth,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: VelomineColors.of(context).cardRaised,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(date.day, style: VelomineText.of(context).stat),
          Text(
            date.month,
            style: text.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
