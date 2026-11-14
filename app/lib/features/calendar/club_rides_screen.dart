import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_heading.dart';
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

    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoint.compactWidth;
    final page = PageScaffold(
      eyebrow: l10n.clubRidesEyebrow,
      title: l10n.clubRidesTitle,
      subtitle: l10n.clubRidesSubtitle,
      actions: wide
          ? Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  key: const Key('open-calendar-feed'),
                  onPressed: onCalendar,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(l10n.calendarTitle),
                ),
                if (canPlan)
                  FilledButton.icon(
                    key: const Key('plan-ride'),
                    onPressed: onPlan,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.clubPlanRide),
                  ),
              ],
            )
          : OutlinedButton.icon(
              key: const Key('open-calendar-feed'),
              onPressed: onCalendar,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(l10n.calendarTitle),
            ),
      bottomPadding: wide ? AppSpacing.xl : 96,
      children: [
        if (s.load.failure case final failure?)
          ErrorState(
            message: failureText(l10n, failure),
            actionKey: const Key('club-rides-error'),
            onRetry: () =>
                ref.read(clubRidesViewModelProvider.notifier).refresh(),
          ),
        if (s.load.running && s.upcoming.isEmpty && s.past.isEmpty)
          const Center(child: CircularProgressIndicator())
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
          if (s.upcoming.isNotEmpty) ...[
            SectionHeading(title: l10n.ridesUpcoming),
            for (final ride in s.upcoming)
              _RideCard(ride: ride, onOpen: onOpen),
          ],
          if (s.past.isNotEmpty) ...[
            SectionHeading(title: l10n.ridesPast),
            for (final ride in s.past)
              _RideCard(ride: ride, onOpen: onOpen, dimmed: true),
          ],
        ],
      ],
    );
    if (wide) return page;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canPlan
          ? FloatingActionButton.extended(
              key: const Key('plan-ride'),
              onPressed: onPlan,
              icon: const Icon(Icons.add),
              label: Text(l10n.clubPlanRide),
            )
          : null,
      body: page,
    );
  }
}

class _RideCard extends StatelessWidget {
  const _RideCard({
    required this.ride,
    required this.onOpen,
    this.dimmed = false,
  });

  final ClubRideSummaryResponse ride;
  final void Function(String id) onOpen;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final title = Text(
      ride.title,
      style: text.titleMedium?.copyWith(
        decoration: ride.isCancelled ? TextDecoration.lineThrough : null,
        color: dimmed ? Theme.of(context).disabledColor : null,
      ),
    );
    return Card(
      key: Key('club-ride-${ride.id}'),
      child: ListTile(
        onTap: () => onOpen(ride.id),
        leading: const Icon(Icons.event),
        title: Row(
          spacing: AppSpacing.sm,
          children: [
            Flexible(child: title),
            if (ride.isCancelled)
              Chip(
                key: const Key('ride-cancelled'),
                label: Text(l10n.rideCancelled),
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
              ),
            if (ride.isFull && !ride.isCancelled)
              Chip(label: Text(l10n.rideFull)),
            if (ride.isSignedUp && !ride.isCancelled)
              Chip(label: Text(l10n.rideSignedUp)),
          ],
        ),
        subtitle: Text(
          [
            rideStartText(context, ride.startsAt, ride.utcOffsetMinutes),
            rideSubtitle(l10n, ride),
            if (ride.createdByName != null)
              l10n.ridePlannedBy(ride.createdByName!),
          ].join('\n'),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
