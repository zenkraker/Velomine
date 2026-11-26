import 'dart:async' show scheduleMicrotask;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/confirm.dart';
import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/units.dart';
import '../../core/location_service.dart';
import '../../core/providers.dart';
import '../../core/tokens.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badge.dart';
import '../../core/widgets/card_grid.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/inline_error.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/toolbar_row.dart';
import '../sharing/sharing_view_model.dart';
import '../calendar/club_ride_widgets.dart';
import '../calendar/club_rides_view_model.dart';
import '../routes/route_widgets.dart';
import '../routes/routes_view_model.dart';
import 'club_state.dart';
import 'club_view_model.dart';
import 'join_requests_view_model.dart';
import 'location_picker.dart';
import 'nearby_clubs_state.dart';
import 'nearby_clubs_view_model.dart';
import 'widgets/club_athletes_card.dart';
import 'widgets/club_hero_card.dart';
import 'widgets/club_join_code_card.dart';
import 'widgets/club_location_card.dart';
import 'widgets/club_members_card.dart';
import 'widgets/club_plan_card.dart';
import 'widgets/club_requests_card.dart';
import 'widgets/club_sharing_card.dart';

export 'widgets/club_labels.dart' show clubRoleName;

class ClubScreen extends ConsumerWidget {
  const ClubScreen({
    super.key,
    required this.serverUrl,
    required this.onJoin,
    required this.onStartClub,
    required this.onOpenClubs,
    required this.onOpenAthletes,
    required this.onOpenRides,
    required this.onOpenRide,
    required this.onPlanRide,
    required this.onOpenRoutes,
    required this.onOpenRoute,
    required this.onAddRoute,
    required this.tileUrl,
    required this.attribution,
  });

  final String serverUrl;
  final VoidCallback onJoin;
  final VoidCallback onStartClub;
  final VoidCallback onOpenClubs;
  final VoidCallback onOpenAthletes;
  final VoidCallback onOpenRides;
  final void Function(String id) onOpenRide;
  final VoidCallback onPlanRide;
  final VoidCallback onOpenRoutes;
  final void Function(String id) onOpenRoute;
  final VoidCallback onAddRoute;
  final String tileUrl;
  final String attribution;

  Future<GeoPoint?> _pick(
    BuildContext context,
    WidgetRef ref,
    GeoPoint? initial,
  ) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => LocationPickerScreen(
        initial: initial,
        tileUrl: tileUrl,
        attribution: attribution,
        locationService: ref.read(locationServiceProvider),
      ),
    ),
  );

  Future<void> _rotateCode(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final sure = await confirmDestructive(
      context,
      title: l10n.clubNewCode,
      body: l10n.clubNewCodeConfirm,
      action: l10n.clubNewCode,
      key: const Key('confirm-new-code'),
    );
    if (sure && context.mounted) {
      await ref.read(clubViewModelProvider.notifier).rotateCode();
    }
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final sure = await confirmDestructive(
      context,
      title: l10n.clubLeaveTitle,
      body: l10n.clubLeaveBody,
      action: l10n.clubLeave,
      key: const Key('confirm-leave-club'),
      cancelLabel: l10n.keepIt,
    );
    if (sure && context.mounted) {
      await ref.read(clubViewModelProvider.notifier).leave();
    }
  }

  void _copy(BuildContext context, String code) {
    final l10n = context.l10n;
    Clipboard.setData(ClipboardData(text: '$serverUrl/join?code=$code'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.clubCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveLocation(
    BuildContext context,
    WidgetRef ref,
    ClubResponse club, {
    required bool isDiscoverable,
    GeoPoint? point,
  }) async {
    final selected =
        point ??
        await _pick(
          context,
          ref,
          club.latitude == null || club.longitude == null
              ? null
              : (latitude: club.latitude!, longitude: club.longitude!),
        );
    if (selected == null || !context.mounted) return;
    await ref
        .read(clubViewModelProvider.notifier)
        .setLocation(
          selected.latitude,
          selected.longitude,
          isDiscoverable: isDiscoverable,
        );
  }

  Future<void> _toggleDiscoverable(
    BuildContext context,
    WidgetRef ref,
    ClubResponse club,
    bool value,
  ) async {
    // Turning discovery on needs a point first, so ask for one and save both at once.
    if (value && (club.latitude == null || club.longitude == null)) {
      await _saveLocation(context, ref, club, isDiscoverable: true);
      return;
    }
    await ref
        .read(clubViewModelProvider.notifier)
        .setLocation(club.latitude, club.longitude, isDiscoverable: value);
  }

  Future<void> _decideJoinRequest(
    BuildContext context,
    WidgetRef ref,
    JoinRequestResponse request, {
    required bool approve,
  }) async {
    final l10n = context.l10n;
    final confirm = approve ? confirmAction : confirmDestructive;
    final sure = await confirm(
      context,
      title: approve
          ? l10n.joinRequestApproveTitle(request.displayName)
          : l10n.joinRequestDeclineTitle(request.displayName),
      body: approve ? l10n.joinRequestApproveBody : l10n.joinRequestDeclineBody,
      action: approve ? l10n.joinRequestApprove : l10n.joinRequestDecline,
      key: Key(
        approve
            ? 'confirm-approve-${request.id}'
            : 'confirm-decline-${request.id}',
      ),
    );
    if (!sure || !context.mounted) return;
    final notifier = ref.read(joinRequestsViewModelProvider.notifier);
    if (approve) {
      await notifier.approve(request.id);
    } else {
      await notifier.decline(request.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final clubState = ref.watch(clubViewModelProvider);
    final sharing = ref.watch(sharingViewModelProvider);
    final requests = ref.watch(joinRequestsViewModelProvider);
    final nearby = ref.watch(nearbyClubsViewModelProvider);

    listenUserMessages(
      ref,
      context,
      clubViewModelProvider.select((s) => s.messages),
      ref.read(clubViewModelProvider.notifier).messageShown,
    );
    listenUserMessages(
      ref,
      context,
      sharingViewModelProvider.select((s) => s.messages),
      ref.read(sharingViewModelProvider.notifier).messageShown,
    );
    listenUserMessages(
      ref,
      context,
      joinRequestsViewModelProvider.select((s) => s.messages),
      ref.read(joinRequestsViewModelProvider.notifier).messageShown,
    );
    listenUserMessages(
      ref,
      context,
      nearbyClubsViewModelProvider.select((s) => s.messages),
      ref.read(nearbyClubsViewModelProvider.notifier).messageShown,
    );

    final club = clubState.club;
    if (club == null) return _noClub(context, ref, clubState, nearby);

    final owner = club.myRole == 'owner';
    final coach = owner || club.myRole == 'coach';

    // What the club is: the plan and the code that lets people in, beside the club's own card.
    final about = <Widget>[
      if (club.plan case final plan?) ClubPlanCard(plan: plan),
      if (owner && club.joinCode != null)
        ClubJoinCodeCard(
          code: club.joinCode!,
          onCopy: () => _copy(context, club.joinCode!),
        ),
    ];

    // The people and the settings, in the order the page reads: who is asking, who is in, the athletes,
    // what the member shares and where the club is.
    final manage = <Widget>[
      if (owner)
        ClubRequestsCard(
          requests: requests,
          onRefresh: ref.read(joinRequestsViewModelProvider.notifier).refresh,
          onApprove: (request) =>
              _decideJoinRequest(context, ref, request, approve: true),
          onDecline: (request) =>
              _decideJoinRequest(context, ref, request, approve: false),
        ),
      // The roster is for the club's managers: a rider sees the rides, the routes and what they share.
      if (coach)
        ClubMembersCard(
          members: club.members,
          owner: owner,
          onSetRole: (userId, role) =>
              ref.read(clubViewModelProvider.notifier).setRole(userId, role),
        ),
      if (coach) ClubAthletesCard(onOpen: onOpenAthletes),
      ClubSharingCard(
        state: sharing,
        onChoose: ({rides, analytics, routes, wellbeing}) => ref
            .read(sharingViewModelProvider.notifier)
            .choose(
              rides: rides,
              analytics: analytics,
              routes: routes,
              wellbeing: wellbeing,
            ),
      ),
      if (owner)
        ClubLocationCard(
          club: club,
          busy: clubState.action.running,
          tileUrl: tileUrl,
          attribution: attribution,
          onSetLocation: () => _saveLocation(
            context,
            ref,
            club,
            isDiscoverable: club.isDiscoverable,
          ),
          onToggleDiscoverable: (value) =>
              _toggleDiscoverable(context, ref, club, value),
        ),
    ];

    // Paired from the tablet width up, one under the other on a phone.
    Widget cards(List<Widget> children) =>
        CardGrid(columns: 2, children: children);

    return PageScaffold(
      // Club is a destination, so its own name is the title; the club's name is the first card's (ClubPage.md).
      title: l10n.navClub,
      subtitle: l10n.clubSubtitle,
      // Leaving ends the member's place in the club; a new code ends the old one for good. Both are in the menu,
      // last and red. The owner cannot leave, and a rider cannot make a code.
      menu: PageMenu(
        buttonKey: const Key('club-actions'),
        entries: [
          if (owner)
            PageMenuEntry(
              key: const Key('new-join-code'),
              label: l10n.clubNewCode,
              icon: Icons.refresh,
              destructive: true,
              onSelected: clubState.action.running
                  ? () {}
                  : () => scheduleMicrotask(() {
                      if (context.mounted) _rotateCode(context, ref);
                    }),
            )
          else
            PageMenuEntry(
              key: const Key('leave-club'),
              label: l10n.clubLeave,
              icon: Icons.logout,
              destructive: true,
              onSelected: clubState.action.running
                  ? () {}
                  : () => scheduleMicrotask(() {
                      if (context.mounted) _leave(context, ref);
                    }),
            ),
        ],
      ),
      children: [
        ClubHeroCard(club: club),
        if (!club.isActive)
          AppCard(
            child: Text(
              l10n.clubInactive,
              key: const Key('club-inactive'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        if (clubState.load.failure case final failure?)
          ErrorState(
            message: failureText(l10n, failure),
            actionKey: const Key('club-error'),
            onRetry: clubState.load.running
                ? null
                : ref.read(clubViewModelProvider.notifier).refresh,
          ),
        if (about.isNotEmpty) cards(about),
        _ridesSection(context, ref, canPlan: coach),
        _routesSection(context, ref),
        if (manage.isNotEmpty) cards(manage),
        // The owner cannot leave; the note stays where the button used to be.
        if (owner)
          Text(
            l10n.clubOwnerCannotLeave,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  /// The page for a member without a club: three ways forward, or the invitation that is waiting.
  Widget _noClub(
    BuildContext context,
    WidgetRef ref,
    ClubState clubState,
    NearbyClubsState nearby,
  ) {
    final l10n = context.l10n;
    // The real header while the club is read, so the page is opaque from its first frame.
    if (clubState.load.running && !clubState.loaded) {
      return PageScaffold(
        title: l10n.navClub,
        subtitle: l10n.clubNoneSubtitle,
        children: const [LoadingState.rows(key: Key('club-loading'), count: 4)],
      );
    }
    return PageScaffold(
      title: l10n.navClub,
      subtitle: l10n.clubNoneSubtitle,
      children: [
        if (clubState.load.failure case final failure?)
          ErrorState(
            message: failureText(l10n, failure),
            actionKey: const Key('club-error'),
            onRetry: clubState.load.running
                ? null
                : ref.read(clubViewModelProvider.notifier).refresh,
          ),
        AppCard(
          key: const Key('club-none-card'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: [
              Text(
                l10n.clubNoneTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(l10n.clubNoneBody),
            ],
          ),
        ),
        if (nearby.request case final request?)
          SectionCard(
            title: l10n.nearbyPendingTitle(request.clubName),
            description: l10n.nearbyPendingBody,
            children: [
              if (request.note != null) Text(l10n.noteQuoted(request.note!)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const Key('cancel-join-request'),
                  onPressed: nearby.action.running
                      ? null
                      : () => ref
                            .read(nearbyClubsViewModelProvider.notifier)
                            .cancelRequest(),
                  child: Text(l10n.nearbyCancel),
                ),
              ),
            ],
          )
        // A pending request takes the place of the three ways forward.
        else
          // The three ways are peers: one card each, one button style, and the third stays when an operator
          // has turned club creation off (its button is simply off).
          CardGrid(
            columns: 3,
            children: [
              _ClubWayCard(
                cardKey: const Key('club-way-nearby'),
                title: l10n.nearbyTitle,
                body: l10n.clubNearbyBody,
                icon: Icons.explore_outlined,
                action: OutlinedButton(
                  key: const Key('go-nearby-clubs'),
                  onPressed: onOpenClubs,
                  child: Text(l10n.clubSeeNearby),
                ),
              ),
              _ClubWayCard(
                cardKey: const Key('club-way-join'),
                title: l10n.clubJoinWithCode,
                body: l10n.clubJoinBody,
                icon: Icons.vpn_key_outlined,
                action: OutlinedButton(
                  key: const Key('go-join-club'),
                  onPressed: onJoin,
                  child: Text(l10n.joinTitle),
                ),
              ),
              _ClubWayCard(
                cardKey: const Key('club-way-start'),
                title: l10n.startClubButton,
                body: l10n.clubStartBody,
                icon: Icons.group_add_outlined,
                // The button is simply off when the operator turned clubs off, so the card says why. A failed
                // load leaves the flag false too, and then the error above is the reason, not this.
                note: clubState.loaded && !clubState.canStartClub
                    ? l10n.clubStartUnavailable
                    : null,
                action: OutlinedButton(
                  key: const Key('go-start-club'),
                  onPressed: clubState.canStartClub ? onStartClub : null,
                  child: Text(l10n.startClubButton),
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// The next few club rides, with the way to the whole calendar and to planning one.
  Widget _ridesSection(
    BuildContext context,
    WidgetRef ref, {
    required bool canPlan,
  }) {
    final l10n = context.l10n;
    final s = ref.watch(clubRidesViewModelProvider);
    return SectionCard(
      title: l10n.clubRidesTitle,
      description: l10n.clubRidesHelp,
      children: [
        if (s.load.failure case final failure?)
          InlineError(
            failureText(l10n, failure),
            key: const Key('club-rides-error'),
          ),
        if (s.load.running && s.upcoming.isEmpty)
          const LoadingState()
        else if (s.upcoming.isEmpty && s.load.failure == null)
          Text(l10n.ridesEmpty, key: const Key('club-rides-empty'))
        else
          for (final ride in s.upcoming.take(3))
            _UpcomingRideRow(ride: ride, onOpen: () => onOpenRide(ride.id)),
        ToolbarRow(
          children: [
            TextButton(
              key: const Key('open-club-rides'),
              onPressed: onOpenRides,
              child: Text(l10n.clubRidesSeeAll),
            ),
            // Planning a ride is the card's own quiet action; the page keeps a single main action.
            if (canPlan)
              TextButton.icon(
                key: const Key('plan-ride-from-club'),
                onPressed: onPlanRide,
                icon: const Icon(Icons.add),
                label: Text(l10n.clubPlanRide),
              ),
          ],
        ),
      ],
    );
  }

  /// The newest club routes, with the way to the library and to adding one.
  Widget _routesSection(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(routesViewModelProvider);
    return SectionCard(
      title: l10n.clubRoutesTitle,
      description: l10n.clubRoutesHelp,
      children: [
        if (s.load.failure case final failure?)
          InlineError(
            failureText(l10n, failure),
            key: const Key('club-routes-error'),
          ),
        if (s.load.running && s.routes.isEmpty)
          const LoadingState()
        else if (s.routes.isEmpty && s.load.failure == null)
          Text(l10n.clubRoutesEmpty, key: const Key('club-routes-empty'))
        else
          for (final route in s.routes.take(3))
            ListTile(
              key: Key('club-route-${route.id}'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.route),
              title: Text(route.name),
              subtitle: Text(
                '${routeLineOf(ref.watch(unitsChoiceViewModelProvider), route.distanceM, route.climbingM)} · '
                '${routeSurfaceName(l10n, route.surface)}',
              ),
              onTap: () => onOpenRoute(route.id),
            ),
        ToolbarRow(
          children: [
            TextButton(
              key: const Key('open-club-routes'),
              onPressed: onOpenRoutes,
              child: Text(l10n.clubRoutesSeeAll),
            ),
            // Adding a route is the card's own quiet action; the page keeps a single main action.
            TextButton.icon(
              key: const Key('add-route-from-club'),
              onPressed: onAddRoute,
              icon: const Icon(Icons.add),
              label: Text(l10n.clubAddRoute),
            ),
          ],
        ),
      ],
    );
  }
}

/// One of the three ways forward for a rider without a club: what it is, and the button that takes it.
class _ClubWayCard extends StatelessWidget {
  const _ClubWayCard({
    required this.cardKey,
    required this.title,
    required this.body,
    required this.icon,
    required this.action,
    this.note,
  });

  final Key cardKey;
  final String title;
  final String body;
  final IconData icon;
  final Widget action;

  /// Why the action cannot be taken, under it, for the one way an operator can turn off.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      key: cardKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Text(title, style: text.titleMedium),
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          Text(body),
          action,
          if (note case final note?)
            Text(
              note,
              key: const Key('club-way-start-note'),
              style: text.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// One of the club's next rides, led by the day it happens: the day and month, the title with its time,
/// meeting point and pace, and the rider's own state or how many places are left.
class _UpcomingRideRow extends StatelessWidget {
  const _UpcomingRideRow({required this.ride, required this.onOpen});

  final ClubRideSummaryResponse ride;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final date = rideDateBlock(ride.startsAt, ride.utcOffsetMinutes);
    final subtitle = [
      rideRowTime(context, ride.startsAt, ride.utcOffsetMinutes),
      ride.meetingName,
      ridePaceName(l10n, ride.pace),
      if (ride.noDrop) l10n.rideNoDrop,
    ].join(' · ');
    return InkWell(
      key: Key('club-ride-${ride.id}'),
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(date.day, style: text.titleMedium),
                Text(
                  date.month,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  Text(ride.title, style: text.bodyLarge),
                  Text(
                    subtitle,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AppBadge(
              ride.isCancelled
                  ? l10n.rideCancelled
                  : ride.isSignedUp
                  ? l10n.rideSignedUp
                  : ridePlaces(l10n, ride),
              tone: ride.isCancelled
                  ? AppBadgeTone.bad
                  : ride.isSignedUp
                  ? AppBadgeTone.good
                  : AppBadgeTone.neutral,
            ),
          ],
        ),
      ),
    );
  }
}
