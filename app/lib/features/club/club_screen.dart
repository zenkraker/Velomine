import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/units.dart';
import '../../core/location_service.dart';
import '../../core/providers.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/card_grid.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_heading.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/toolbar_row.dart';
import '../../l10n/generated/app_localizations.dart';
import '../sharing/sharing_state.dart';
import '../sharing/sharing_view_model.dart';
import '../calendar/club_ride_widgets.dart';
import '../calendar/club_rides_view_model.dart';
import '../routes/route_widgets.dart';
import '../routes/routes_view_model.dart';
import 'club_view_model.dart';
import 'club_state.dart';
import 'join_requests_state.dart';
import 'join_requests_view_model.dart';
import 'location_picker.dart';
import 'nearby_clubs_state.dart';
import 'nearby_clubs_view_model.dart';
import '../../core/tokens.dart';

String clubRoleName(AppLocalizations l10n, String role) => switch (role) {
  'owner' => l10n.clubOwner,
  'coach' => l10n.clubCoach,
  _ => l10n.clubMemberRole,
};

String _audienceName(AppLocalizations l10n, String audience) =>
    switch (audience) {
      'coaches' => l10n.audienceCoaches,
      _ => l10n.audienceNone,
    };

String _viewName(AppLocalizations l10n, String what) => switch (what) {
  'rides' => l10n.shareRides,
  'analytics' => l10n.shareAnalytics,
  'routes' => l10n.shareRoutes,
  'wellbeing' => l10n.shareWellbeing,
  _ => what,
};

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
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.clubNewCodeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirm-new-code'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.clubNewCode),
          ),
        ],
      ),
    );
    if (sure == true) {
      await ref.read(clubViewModelProvider.notifier).rotateCode();
    }
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clubLeaveTitle),
        content: Text(l10n.clubLeaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepIt),
          ),
          FilledButton(
            key: const Key('confirm-leave-club'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.clubLeave),
          ),
        ],
      ),
    );
    if (sure == true) {
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
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          approve
              ? l10n.joinRequestApproveTitle(request.displayName)
              : l10n.joinRequestDeclineTitle(request.displayName),
        ),
        content: Text(
          approve ? l10n.joinRequestApproveBody : l10n.joinRequestDeclineBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: Key(
              approve
                  ? 'confirm-approve-${request.id}'
                  : 'confirm-decline-${request.id}',
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              approve ? l10n.joinRequestApprove : l10n.joinRequestDecline,
            ),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
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
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoint.compactWidth;

    // What the club's owner looks after. Paired on a desktop window, one under the other on a tablet.
    final manage = <Widget>[
      if (club.plan case final plan?) _planCard(context, plan),
      if (owner)
        _requestsCard(
          context,
          ref,
          requests,
          onApprove: (request) =>
              _decideJoinRequest(context, ref, request, approve: true),
          onDecline: (request) =>
              _decideJoinRequest(context, ref, request, approve: false),
        ),
      if (owner && club.joinCode != null)
        _joinCodeCard(context, ref, club.joinCode!, clubState),
      if (owner)
        _locationCard(context, ref, club, busy: clubState.action.running),
      _membersCard(context, ref, club, owner: owner),
      if (coach) _athletesCard(context),
      _SharingCard(
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
    ];

    return PageScaffold(
      eyebrow: l10n.eyebrowClub,
      title: l10n.navClub,
      subtitle: l10n.clubSubtitle,
      children: [
        _ClubHeader(club: club),
        if (!club.isActive)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(l10n.clubInactive, key: const Key('club-inactive')),
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
        SectionHeading(title: l10n.clubRidesTitle),
        _ridesSection(context, ref, canPlan: coach),
        SectionHeading(title: l10n.clubRoutesTitle),
        _routesSection(context, ref),
        SectionHeading(title: l10n.clubMembers),
        if (wide)
          CardGrid(columns: 2, children: manage)
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.lg,
            children: manage,
          ),
        // Leaving ends the member's place in the club: last on the page, away from the rest.
        _leaveCard(context, ref, owner: owner, busy: clubState.action.running),
      ],
    );
  }

  /// The page for a member without a club: the one thing to do, and the invitation that is waiting.
  Widget _noClub(
    BuildContext context,
    WidgetRef ref,
    ClubState clubState,
    NearbyClubsState nearby,
  ) {
    final l10n = context.l10n;
    if (clubState.load.running && !clubState.loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return PageScaffold(
      eyebrow: l10n.eyebrowClub,
      title: l10n.clubNoneTitleShort,
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                Text(
                  l10n.clubNoneTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(l10n.clubNoneBody),
                // One row of choices with one weight: the main way first, the alternatives beside it.
                ToolbarRow(
                  children: [
                    FilledButton.icon(
                      key: const Key('go-nearby-clubs'),
                      onPressed: onOpenClubs,
                      icon: const Icon(Icons.explore_outlined),
                      label: Text(l10n.clubSeeNearby),
                    ),
                    OutlinedButton.icon(
                      key: const Key('go-join-club'),
                      onPressed: onJoin,
                      icon: const Icon(Icons.group_add),
                      label: Text(l10n.joinTitle),
                    ),
                    if (clubState.canStartClub)
                      TextButton.icon(
                        key: const Key('go-start-club'),
                        onPressed: onStartClub,
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(l10n.startClubButton),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (nearby.request case final request?)
          SectionCard(
            title: l10n.nearbyPendingTitle(request.clubName),
            description: l10n.nearbyPendingBody,
            children: [
              if (request.note != null) Text('“${request.note}”'),
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
          ),
      ],
    );
  }

  /// What the club's owner needs to know about the plan: room used, the paid-until day, and what to do when
  /// the club is full or the plan has ended. Ordinary members never get a plan from the server.
  Widget _planCard(BuildContext context, ClubPlanResponse plan) {
    final l10n = context.l10n;
    final limit = plan.memberLimit;
    final notice = switch (plan.blocked) {
      'ended' => l10n.clubPlanEndedNotice(dateOnly(plan.paidUntil)),
      'full' => l10n.clubPlanFullNotice,
      _ => null,
    };
    return Card(
      key: const Key('club-plan-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Text(
              l10n.clubPlanTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              limit == null
                  ? l10n.clubMemberCount(plan.memberCount)
                  : l10n.clubPlanMembers(plan.memberCount, limit),
              key: const Key('club-plan-members'),
            ),
            if (limit != null)
              Semantics(
                label: l10n.clubPlanMembers(plan.memberCount, limit),
                excludeSemantics: true,
                child: LinearProgressIndicator(
                  key: const Key('club-plan-bar'),
                  value: (plan.memberCount / limit).clamp(0.0, 1.0),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            if (plan.paidUntil != null)
              Text(
                l10n.clubPlanPaidUntil(dateOnly(plan.paidUntil)),
                key: const Key('club-plan-paid-until'),
              ),
            if (notice != null)
              Text(
                notice,
                key: const Key('club-plan-notice'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _joinCodeCard(
    BuildContext context,
    WidgetRef ref,
    String code,
    ClubState clubState,
  ) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Text(
              l10n.clubJoinCode,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SelectableText(
              code,
              key: const Key('join-code-value'),
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(letterSpacing: 4),
            ),
            Text(
              l10n.clubJoinCodeHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            ToolbarRow(
              children: [
                OutlinedButton.icon(
                  key: const Key('copy-join-link'),
                  onPressed: () => _copy(context, code),
                  icon: const Icon(Icons.link),
                  label: Text(l10n.clubCopy),
                ),
                TextButton.icon(
                  key: const Key('new-join-code'),
                  onPressed: clubState.action.running
                      ? null
                      : () => _rotateCode(context, ref),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.clubNewCode),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _membersCard(
    BuildContext context,
    WidgetRef ref,
    ClubResponse club, {
    required bool owner,
  }) {
    final l10n = context.l10n;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final member in club.members)
            ListTile(
              key: Key('member-${member.userId}'),
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(member.displayName),
              subtitle: Text(clubRoleName(l10n, member.role)),
              trailing: owner && member.role != 'owner'
                  ? PopupMenuButton<String>(
                      key: Key('member-menu-${member.userId}'),
                      tooltip: l10n.changeRoles,
                      onSelected: (role) => ref
                          .read(clubViewModelProvider.notifier)
                          .setRole(member.userId, role),
                      itemBuilder: (_) => [
                        if (member.role != 'coach')
                          PopupMenuItem(
                            value: 'coach',
                            child: Text(l10n.clubMakeCoach),
                          ),
                        if (member.role != 'member')
                          PopupMenuItem(
                            value: 'member',
                            child: Text(l10n.clubMakeMember),
                          ),
                      ],
                    )
                  : null,
            ),
        ],
      ),
    );
  }

  Widget _athletesCard(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.people_outline),
        title: Text(l10n.athletesTitle),
        trailing: TextButton(
          key: const Key('open-athletes'),
          onPressed: onOpenAthletes,
          child: Text(l10n.coachViewAthletes),
        ),
      ),
    );
  }

  /// Leaving a club ends the member's place in it, so it is the last thing here and quietly styled.
  Widget _leaveCard(
    BuildContext context,
    WidgetRef ref, {
    required bool owner,
    required bool busy,
  }) {
    final l10n = context.l10n;
    if (owner) {
      return Text(
        l10n.clubOwnerCannotLeave,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        key: const Key('leave-club'),
        onPressed: busy ? null : () => _leave(context, ref),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        icon: const Icon(Icons.logout),
        label: Text(l10n.clubLeave),
      ),
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
          Text(
            failureText(l10n, failure),
            key: const Key('club-rides-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (s.load.running && s.upcoming.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          )
        else if (s.upcoming.isEmpty && s.load.failure == null)
          Text(l10n.ridesEmpty, key: const Key('club-rides-empty'))
        else
          for (final ride in s.upcoming.take(3))
            ListTile(
              key: Key('club-ride-${ride.id}'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(ride.title),
              subtitle: Text(
                '${rideStartText(context, ride.startsAt, ride.utcOffsetMinutes)} · '
                '${ride.meetingName} · ${ridePlaces(l10n, ride)}',
              ),
              onTap: () => onOpenRide(ride.id),
            ),
        ToolbarRow(
          children: [
            TextButton(
              key: const Key('open-club-rides'),
              onPressed: onOpenRides,
              child: Text(l10n.clubRidesSeeAll),
            ),
            if (canPlan)
              FilledButton.tonalIcon(
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
          Text(
            failureText(l10n, failure),
            key: const Key('club-routes-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (s.load.running && s.routes.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          )
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
            FilledButton.tonalIcon(
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

  Widget _requestsCard(
    BuildContext context,
    WidgetRef ref,
    JoinRequestsState requests, {
    required void Function(JoinRequestResponse request) onApprove,
    required void Function(JoinRequestResponse request) onDecline,
  }) {
    final l10n = context.l10n;
    final blocked = requests.admissionBlocked;
    return Card(
      key: const Key('join-requests-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.joinRequestsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const Key('refresh-join-requests'),
                  tooltip: l10n.actionLoadJoinRequests,
                  onPressed: requests.load.running
                      ? null
                      : () => ref
                            .read(joinRequestsViewModelProvider.notifier)
                            .refresh(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (requests.load.failure case final failure?)
              Text(
                failureText(l10n, failure),
                key: const Key('join-requests-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (requests.load.running)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (requests.requests.isEmpty)
              Text(
                l10n.joinRequestsEmpty,
                key: const Key('join-requests-empty'),
              )
            else ...[
              if (blocked != null)
                Text(
                  blocked == 'ended'
                      ? l10n.joinRequestsBlockedEnded
                      : l10n.joinRequestsBlockedFull,
                  key: const Key('join-requests-blocked'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              for (final request in requests.requests) ...[
                const Divider(),
                Text(
                  request.displayName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (request.note != null) Text('“${request.note}”'),
                Align(
                  alignment: Alignment.centerRight,
                  child: ToolbarRow(
                    children: [
                      TextButton(
                        key: Key('decline-${request.id}'),
                        onPressed: requests.action.running
                            ? null
                            : () => onDecline(request),
                        child: Text(l10n.joinRequestDecline),
                      ),
                      FilledButton.tonal(
                        key: Key('approve-${request.id}'),
                        onPressed: requests.action.running || blocked != null
                            ? null
                            : () => onApprove(request),
                        child: Text(l10n.joinRequestApprove),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _locationCard(
    BuildContext context,
    WidgetRef ref,
    ClubResponse club, {
    required bool busy,
  }) {
    final l10n = context.l10n;
    final hasPoint = club.latitude != null && club.longitude != null;
    return Card(
      key: const Key('club-location-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Text(
              l10n.clubLocation,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              l10n.clubLocationHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            // The point a club is found by, as a person reads a map, not a raw pair of coordinates.
            Row(
              spacing: AppSpacing.sm,
              children: [
                Icon(
                  hasPoint ? Icons.place : Icons.place_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                Expanded(
                  child: Text(
                    hasPoint ? l10n.clubLocationOnMap : l10n.clubLocationNone,
                    key: const Key('club-location-value'),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('set-club-location'),
                onPressed: busy
                    ? null
                    : () => _saveLocation(
                        context,
                        ref,
                        club,
                        isDiscoverable: club.isDiscoverable,
                      ),
                icon: const Icon(Icons.place),
                label: Text(
                  hasPoint ? l10n.clubLocationChange : l10n.clubLocationSet,
                ),
              ),
            ),
            SwitchListTile(
              key: const Key('club-discoverable'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.clubDiscoverable),
              subtitle: Text(l10n.clubDiscoverableHelp),
              value: club.isDiscoverable,
              onChanged: busy
                  ? null
                  : (value) => _toggleDiscoverable(context, ref, club, value),
            ),
          ],
        ),
      ),
    );
  }
}

/// The top of the club page: the name, the person's role, how many ride here, and the join code
/// when they own it — the handful of facts the rest of the page builds on.
class _ClubHeader extends StatelessWidget {
  const _ClubHeader({required this.club});

  final ClubResponse club;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Text(
              club.name,
              style: text.headlineSmall,
              semanticsLabel: club.name,
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(clubRoleName(l10n, club.myRole)),
                  backgroundColor: scheme.primaryContainer,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  l10n.clubMemberCount(club.members.length),
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SharingCard extends StatelessWidget {
  const _SharingCard({required this.state, required this.onChoose});

  final SharingState state;
  final void Function({
    String? rides,
    String? analytics,
    String? routes,
    String? wellbeing,
  })
  onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget choice(
      String label,
      String value,
      String key,
      void Function(String value) onChanged, {
      bool enabled = true,
      String? helper,
    }) => InputDecorator(
      decoration: InputDecoration(labelText: label, helperText: helper),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: Key(key),
          value: value,
          isExpanded: true,
          items: [
            for (final audience in ['none', 'coaches'])
              DropdownMenuItem(
                value: audience,
                child: Text(_audienceName(l10n, audience)),
              ),
          ],
          onChanged: state.save.running || !enabled
              ? null
              : (v) {
                  if (v != null) onChanged(v);
                },
        ),
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Text(
              l10n.sharingTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              l10n.sharingHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (state.load.running && !state.loaded)
              const Center(child: CircularProgressIndicator())
            else ...[
              choice(
                l10n.shareRides,
                state.rides,
                'share-rides',
                (v) => onChoose(rides: v),
              ),
              choice(
                l10n.shareAnalytics,
                state.analytics,
                'share-analytics',
                (v) => onChoose(analytics: v),
              ),
              choice(
                l10n.shareRoutes,
                state.routes,
                'share-routes',
                (v) => onChoose(routes: v),
                enabled: state.rides != 'none',
                helper: state.rides == 'none' ? l10n.routesNeedRides : null,
              ),
              choice(
                l10n.shareWellbeing,
                state.wellbeing,
                'share-wellbeing',
                (v) => onChoose(wellbeing: v),
                helper: l10n.shareWellbeingHelper,
              ),
            ],
            if (state.load.failure case final failure?)
              Text(
                failureText(l10n, failure),
                key: const Key('sharing-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const Divider(),
            Text(
              l10n.viewsTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (state.views.isEmpty)
              Text(l10n.viewsEmpty)
            else
              for (final view in state.views)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.visibility_outlined, size: 18),
                  title: Text(view.viewerName),
                  subtitle: Text(_viewName(l10n, view.what)),
                  trailing: Text(dateTime(view.at)),
                ),
          ],
        ),
      ),
    );
  }
}
