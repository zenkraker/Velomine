import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/location_service.dart';
import '../../core/providers.dart';
import '../../core/user_message_text.dart';
import 'location_picker.dart';
import 'nearby_clubs_view_model.dart';
import '../../core/tokens.dart';
import '../../core/widgets/empty_state.dart';

/// The suggestion page: a rider without a club sees which clubs are within reach and may ask to join one.
class NearbyClubsScreen extends ConsumerStatefulWidget {
  const NearbyClubsScreen({
    super.key,
    required this.onBack,
    required this.tileUrl,
    required this.attribution,
  });

  final VoidCallback onBack;
  final String tileUrl;
  final String attribution;

  @override
  ConsumerState<NearbyClubsScreen> createState() => _NearbyClubsScreenState();
}

class _NearbyClubsScreenState extends ConsumerState<NearbyClubsScreen> {
  @override
  void initState() {
    super.initState();
    // Opening the page asks where the rider is: the device first, then the saved point.
    Future.microtask(
      () => ref.read(nearbyClubsViewModelProvider.notifier).start(),
    );
  }

  Future<GeoPoint?> _pick(GeoPoint? initial) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => LocationPickerScreen(
        initial: initial,
        tileUrl: widget.tileUrl,
        attribution: widget.attribution,
        locationService: ref.read(locationServiceProvider),
      ),
    ),
  );

  Future<void> _setSavedLocation(GeoPoint? initial) async {
    final point = await _pick(initial);
    if (point == null || !mounted) return;
    await ref.read(nearbyClubsViewModelProvider.notifier).useSavedPoint(point);
  }

  Future<void> _ask(NearbyClubResponse club) async {
    final l10n = context.l10n;
    final pending = ref.read(nearbyClubsViewModelProvider).request;
    if (pending != null && pending.clubId != club.id) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.nearbyReplaceTitle(pending.clubName)),
          content: Text(l10n.nearbyReplaceBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: const Key('confirm-replace-request'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.nearbyRequestSend),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }

    final note = await showDialog<String>(
      context: context,
      builder: (_) => _JoinRequestDialog(clubName: club.name),
    );
    if (note == null || !mounted) return;

    await ref
        .read(nearbyClubsViewModelProvider.notifier)
        .askToJoin(club.id, note);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = ref.watch(nearbyClubsViewModelProvider);

    listenUserMessages(
      ref,
      context,
      nearbyClubsViewModelProvider.select((s) => s.messages),
      ref.read(nearbyClubsViewModelProvider.notifier).messageShown,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.nearbyTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: widget.onBack,
        ),
      ),
      body: Builder(
        builder: (context) {
          if (s.locating) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(l10n.nearbyLocating),
                ],
              ),
            );
          }

          final position = s.position;
          if (position == null) {
            return _WhereAreYou(
              askedDevice: s.askedDevice,
              onUseDevice: () =>
                  ref.read(nearbyClubsViewModelProvider.notifier).start(),
              onPick: () => _setSavedLocation(null),
            );
          }

          final nextRadius = ref
              .read(nearbyClubsViewModelProvider.notifier)
              .nextRadius();
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(nearbyClubsViewModelProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(l10n.nearbyIntro),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.nearbyLocationHelp,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (s.usingSavedPoint) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.home_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(l10n.nearbyHomeUsed)),
                      TextButton(
                        key: const Key('change-home-location'),
                        onPressed: () => _setSavedLocation(position),
                        child: Text(l10n.clubLocationChange),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: 4,
                        children: [
                          for (final km in NearbyClubsViewModel.radii)
                            ChoiceChip(
                              key: Key('radius-$km'),
                              label: Text(l10n.nearbyRadius(km)),
                              selected: s.radiusKm == km,
                              onSelected: s.action.running || s.load.running
                                  ? null
                                  : (_) => ref
                                        .read(
                                          nearbyClubsViewModelProvider.notifier,
                                        )
                                        .setRadius(km),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filledTonal(
                      key: const Key('nearby-relocate'),
                      tooltip: l10n.nearbyUseDevice,
                      onPressed: () => ref
                          .read(nearbyClubsViewModelProvider.notifier)
                          .start(),
                      icon: const Icon(Icons.my_location),
                    ),
                    const SizedBox(width: 4),
                    IconButton.filledTonal(
                      key: const Key('nearby-set-location'),
                      tooltip: l10n.nearbySetHome,
                      onPressed: () => _setSavedLocation(position),
                      icon: const Icon(Icons.edit_location_alt_outlined),
                    ),
                  ],
                ),
                if (s.load.failure case final failure?) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    failureText(l10n, failure),
                    key: const Key('nearby-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (s.request != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Card(
                    key: const Key('pending-join-request'),
                    color: Theme.of(context).colorScheme.secondaryContainer
                        .withValues(alpha: 0.5),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 6,
                        children: [
                          Text(
                            l10n.nearbyPendingTitle(s.request!.clubName),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(l10n.nearbyPendingBody),
                          if (s.request!.note != null)
                            Text('“${s.request!.note}”'),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              key: const Key('cancel-join-request'),
                              onPressed: s.action.running
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
                      ),
                    ),
                  ),
                ],
                if (s.load.running)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (s.clubs.isEmpty && s.load.failure == null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  EmptyState(
                    key: const Key('nearby-empty'),
                    message: l10n.nearbyEmpty(s.radiusKm),
                    icon: Icons.explore_outlined,
                  ),
                  if (nextRadius != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: TextButton(
                        key: const Key('nearby-widen'),
                        onPressed: s.load.running
                            ? null
                            : () => ref
                                  .read(nearbyClubsViewModelProvider.notifier)
                                  .setRadius(nextRadius),
                        child: Text(l10n.nearbyWiden),
                      ),
                    ),
                  ],
                ] else
                  for (final club in s.clubs)
                    _ClubRow(
                      club: club,
                      requested: s.request?.clubId == club.id,
                      busy: s.action.running,
                      onAsk: () => _ask(club),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WhereAreYou extends StatelessWidget {
  const _WhereAreYou({
    required this.askedDevice,
    required this.onUseDevice,
    required this.onPick,
  });

  final bool askedDevice;
  final VoidCallback onUseDevice;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(l10n.nearbyIntro),
        const SizedBox(height: AppSpacing.xl),
        if (askedDevice) ...[
          Text(
            l10n.locationCurrentUnavailable,
            key: const Key('nearby-location-denied'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        FilledButton.tonalIcon(
          key: const Key('nearby-use-device'),
          onPressed: onUseDevice,
          icon: const Icon(Icons.my_location),
          label: Text(l10n.nearbyUseDevice),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          key: const Key('nearby-set-location'),
          onPressed: onPick,
          icon: const Icon(Icons.place),
          label: Text(l10n.nearbySetHome),
        ),
      ],
    );
  }
}

class _JoinRequestDialog extends StatefulWidget {
  const _JoinRequestDialog({required this.clubName});

  final String clubName;

  @override
  State<_JoinRequestDialog> createState() => _JoinRequestDialogState();
}

class _JoinRequestDialogState extends State<_JoinRequestDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.nearbyRequestTitle(widget.clubName)),
      content: TextField(
        key: const Key('join-request-note'),
        controller: _note,
        maxLength: 300,
        maxLines: 3,
        decoration: InputDecoration(labelText: l10n.nearbyRequestNote),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('send-join-request'),
          onPressed: () => Navigator.of(context).pop(_note.text),
          child: Text(l10n.nearbyRequestSend),
        ),
      ],
    );
  }
}

class _ClubRow extends StatelessWidget {
  const _ClubRow({
    required this.club,
    required this.requested,
    required this.busy,
    required this.onAsk,
  });

  final NearbyClubResponse club;
  final bool requested;
  final bool busy;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      key: Key('nearby-club-${club.id}'),
      child: ListTile(
        title: Text(club.name),
        subtitle: Text(
          '${l10n.clubMemberCount(club.memberCount)} · '
          '${l10n.nearbyDistance(club.distanceKm.round())}',
        ),
        trailing: requested
            ? Chip(
                key: Key('requested-${club.id}'),
                label: Text(l10n.nearbyRequested),
              )
            : FilledButton.tonal(
                key: Key('ask-${club.id}'),
                onPressed: busy ? null : onAsk,
                child: Text(l10n.nearbyAsk),
              ),
      ),
    );
  }
}
