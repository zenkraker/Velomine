import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/location_service.dart';
import '../../core/providers.dart';
import '../../core/user_message.dart';
import '../../core/user_message_text.dart';
import '../../l10n/generated/app_localizations.dart';
import '../sharing/sharing_state.dart';
import '../sharing/sharing_view_model.dart';
import 'club_view_model.dart';
import 'join_requests_state.dart';
import 'join_requests_view_model.dart';
import 'location_picker.dart';
import 'nearby_clubs_view_model.dart';

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
    required this.onOpenClubs,
    required this.onOpenAthletes,
    required this.tileUrl,
    required this.attribution,
  });

  final String serverUrl;
  final VoidCallback onJoin;
  final VoidCallback onOpenClubs;
  final VoidCallback onOpenAthletes;
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

  void _showMessage(BuildContext context, UserMessage message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(userMessageText(context.l10n, message))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final clubState = ref.watch(clubViewModelProvider);
    final sharing = ref.watch(sharingViewModelProvider);
    final requests = ref.watch(joinRequestsViewModelProvider);
    final nearby = ref.watch(nearbyClubsViewModelProvider);

    ref.listen(clubViewModelProvider.select((s) => s.messages), (_, messages) {
      for (final message in messages) {
        _showMessage(context, message);
        ref.read(clubViewModelProvider.notifier).messageShown(message.id);
      }
    });
    ref.listen(sharingViewModelProvider.select((s) => s.messages), (
      _,
      messages,
    ) {
      for (final message in messages) {
        _showMessage(context, message);
        ref.read(sharingViewModelProvider.notifier).messageShown(message.id);
      }
    });
    ref.listen(joinRequestsViewModelProvider.select((s) => s.messages), (
      _,
      messages,
    ) {
      for (final message in messages) {
        _showMessage(context, message);
        ref
            .read(joinRequestsViewModelProvider.notifier)
            .messageShown(message.id);
      }
    });
    ref.listen(nearbyClubsViewModelProvider.select((s) => s.messages), (
      _,
      messages,
    ) {
      for (final message in messages) {
        _showMessage(context, message);
        ref
            .read(nearbyClubsViewModelProvider.notifier)
            .messageShown(message.id);
      }
    });

    final club = clubState.club;
    if (club == null) {
      if (clubState.load.running && !clubState.loaded) {
        return const Center(child: CircularProgressIndicator());
      }
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      Text(
                        l10n.clubNoneTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(l10n.clubNoneBody),
                      if (nearby.request != null) ...[
                        const Divider(),
                        Text(
                          l10n.nearbyPendingTitle(nearby.request!.clubName),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(l10n.nearbyPendingBody),
                        if (nearby.request!.note != null)
                          Text('“${nearby.request!.note}”'),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            key: const Key('cancel-join-request'),
                            onPressed: nearby.action.running
                                ? null
                                : () => ref
                                      .read(
                                        nearbyClubsViewModelProvider.notifier,
                                      )
                                      .cancelRequest(),
                            child: Text(l10n.nearbyCancel),
                          ),
                        ),
                      ],
                      if (clubState.load.failure case final failure?)
                        Text(
                          failureText(l10n, failure),
                          key: const Key('club-error'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final owner = club.myRole == 'owner';
    final coach = owner || club.myRole == 'coach';
    final members = club.members;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        club.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Chip(label: Text(clubRoleName(l10n, club.myRole))),
                  ],
                ),
                if (!club.isActive)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        l10n.clubInactive,
                        key: const Key('club-inactive'),
                      ),
                    ),
                  ),
                if (clubState.load.failure case final failure?)
                  Text(
                    failureText(l10n, failure),
                    key: const Key('club-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (owner)
                  _requestsCard(
                    context,
                    ref,
                    requests,
                    onApprove: (request) => _decideJoinRequest(
                      context,
                      ref,
                      request,
                      approve: true,
                    ),
                    onDecline: (request) => _decideJoinRequest(
                      context,
                      ref,
                      request,
                      approve: false,
                    ),
                  ),
                if (owner && club.joinCode != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Text(
                            l10n.clubJoinCode,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SelectableText(
                            club.joinCode!,
                            key: const Key('join-code-value'),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(letterSpacing: 4),
                          ),
                          Text(
                            l10n.clubJoinCodeHelp,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                key: const Key('copy-join-link'),
                                onPressed: () => _copy(context, club.joinCode!),
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
                  ),
                ],
                if (owner)
                  _locationCard(
                    context,
                    ref,
                    club,
                    busy: clubState.action.running,
                  ),
                Text(
                  l10n.clubMembers,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Card(
                  child: Column(
                    children: [
                      for (final member in members)
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
                ),
                if (coach) ...[
                  Text(
                    l10n.athletesTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.people_outline),
                      title: Text(l10n.athletesTitle),
                      trailing: TextButton(
                        key: const Key('open-athletes'),
                        onPressed: onOpenAthletes,
                        child: Text(l10n.coachViewAthletes),
                      ),
                    ),
                  ),
                ],
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
                if (!owner)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: const Key('leave-club'),
                      onPressed: clubState.action.running
                          ? null
                          : () => _leave(context, ref),
                      icon: const Icon(Icons.logout),
                      label: Text(l10n.clubLeave),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  )
                else
                  Text(
                    l10n.clubOwnerCannotLeave,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
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
    return Card(
      key: const Key('join-requests-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
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
            else
              for (final request in requests.requests) ...[
                const Divider(),
                Text(
                  request.displayName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (request.note != null) Text('“${request.note}”'),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
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
                        onPressed: requests.action.running
                            ? null
                            : () => onApprove(request),
                        child: Text(l10n.joinRequestApprove),
                      ),
                    ],
                  ),
                ),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              l10n.clubLocation,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              l10n.clubLocationHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              hasPoint
                  ? '${club.latitude!.toStringAsFixed(5)}, '
                        '${club.longitude!.toStringAsFixed(5)}'
                  : l10n.clubLocationNone,
              key: const Key('club-location-value'),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
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
