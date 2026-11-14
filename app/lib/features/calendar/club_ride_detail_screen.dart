import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/units.dart';
import '../../core/tokens.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_card.dart';
import '../routes/route_widgets.dart';
import '../routes/routes_view_model.dart';
import 'club_ride_widgets.dart';
import 'club_rides_view_model.dart';

class ClubRideDetailScreen extends ConsumerWidget {
  const ClubRideDetailScreen({
    super.key,
    required this.id,
    required this.onEdit,
    this.tileUrl,
    this.attribution,
  });

  final String id;
  final VoidCallback onEdit;
  final String? tileUrl;
  final String? attribution;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.rideCancelConfirmTitle),
        content: Text(l10n.rideCancelConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepIt),
          ),
          FilledButton(
            key: const Key('confirm-cancel-ride'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.rideCancel),
          ),
        ],
      ),
    );
    if (sure == true) {
      await ref.read(clubRideDetailViewModelProvider(id).notifier).cancel();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(clubRideDetailViewModelProvider(id));
    final notifier = ref.read(clubRideDetailViewModelProvider(id).notifier);

    listenUserMessages(
      ref,
      context,
      clubRideDetailViewModelProvider(id).select((s) => s.messages),
      notifier.messageShown,
    );

    if (s.load.running && s.detail == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (s.notFound) {
      return EmptyState(
        key: const Key('club-ride-missing'),
        message: l10n.failureMissing,
        icon: Icons.event_busy,
      );
    }
    final detail = s.detail;
    if (detail == null) {
      return ErrorState(
        message: s.load.failure == null
            ? l10n.couldNotLoadRide
            : failureText(l10n, s.load.failure!),
        actionKey: const Key('club-ride-error'),
        onRetry: s.load.running
            ? null
            : ref.read(clubRideDetailViewModelProvider(id).notifier).load,
      );
    }

    final ride = detail.ride;
    final started = ride.startsAt.isBefore(DateTime.now());
    final route = ride.routeId == null
        ? null
        : ref.watch(routeDetailViewModelProvider(ride.routeId!)).detail;
    final busy = s.action.running;

    return PageScaffold(
      eyebrow: l10n.clubRidesEyebrow,
      title: ride.title,
      titleKey: const Key('club-ride-title'),
      subtitle: rideStartText(context, ride.startsAt, ride.utcOffsetMinutes),
      maxWidth: AppLayout.contentNarrow,
      children: [
        if (ride.isCancelled)
          Chip(
            key: const Key('ride-cancelled'),
            label: Text(l10n.rideCancelled),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
        Text(rideStartText(context, ride.startsAt, ride.utcOffsetMinutes)),
        Text(
          [
            ridePaceName(l10n, ride.pace),
            if (ride.noDrop) l10n.rideNoDrop,
            ridePlaces(l10n, ride),
            if (ride.createdByName != null)
              l10n.ridePlannedBy(ride.createdByName!),
          ].join(' · '),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (ride.isCancelled)
          Text(
            l10n.rideCancelledReason,
            key: const Key('ride-cancelled-reason'),
          ),
        if (ride.isFull && !ride.isSignedUp && !ride.isCancelled)
          Text(l10n.rideFullReason, key: const Key('ride-full-reason')),
        if (started && !ride.isCancelled)
          Text(l10n.rideStartedReason, key: const Key('ride-started-reason')),
        if (ride.routeName != null && route != null)
          SectionCard(
            title: l10n.rideRoute,
            description:
                '${ride.routeName} · ${routeLineOf(ref.watch(unitsChoiceViewModelProvider), route.distanceM, route.climbingM)}',
            children: [
              RoutePreview(
                latitude: route.latitude,
                longitude: route.longitude,
                elevation: route.elevation,
                tileUrl: tileUrl,
                attribution: attribution,
              ),
            ],
          ),
        SectionCard(
          title: l10n.rideMeeting,
          children: [
            Text(detail.ride.meetingName),
            MeetingMap(
              latitude: detail.meetingLatitude,
              longitude: detail.meetingLongitude,
              tileUrl: tileUrl,
              attribution: attribution,
            ),
          ],
        ),
        if (detail.notes != null && detail.notes!.isNotEmpty)
          SectionCard(title: l10n.rideNotes, children: [Text(detail.notes!)]),
        SectionCard(
          title: l10n.rideWhoIsIn,
          children: [
            if (detail.participants.isEmpty)
              Text(l10n.rideNobodyIn, key: const Key('ride-nobody-in'))
            else
              for (final participant in detail.participants)
                ListTile(
                  key: Key('participant-${participant.userId}'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.account_circle_outlined),
                  title: Text(participant.displayName),
                ),
          ],
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (!detail.canPlan)
              _joinButton(context, ref, detail, started, busy),
            if (detail.canPlan) ...[
              OutlinedButton.icon(
                key: const Key('edit-ride'),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.rideEdit),
              ),
              if (!ride.isCancelled)
                TextButton.icon(
                  key: const Key('cancel-ride'),
                  onPressed: busy ? null : () => _cancel(context, ref),
                  icon: const Icon(Icons.event_busy),
                  label: Text(l10n.rideCancel),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _joinButton(
    BuildContext context,
    WidgetRef ref,
    ClubRideDetailResponse detail,
    bool started,
    bool busy,
  ) {
    final l10n = context.l10n;
    final ride = detail.ride;
    final notifier = ref.read(clubRideDetailViewModelProvider(id).notifier);
    if (ride.isSignedUp) {
      if (started && !ride.isCancelled) {
        return FilledButton.tonalIcon(
          key: const Key('ride-signed-up'),
          onPressed: null,
          icon: const Icon(Icons.check),
          label: Text(l10n.rideSignedUp),
        );
      }
      return OutlinedButton.icon(
        key: const Key('leave-ride'),
        onPressed: busy ? null : notifier.leave,
        icon: const Icon(Icons.logout),
        label: Text(l10n.rideImOut),
      );
    }
    final unavailable = ride.isCancelled || started || ride.isFull;
    return FilledButton.icon(
      key: const Key('join-ride'),
      onPressed: unavailable || busy ? null : notifier.join,
      icon: const Icon(Icons.directions_bike),
      label: Text(l10n.rideImIn),
    );
  }
}
