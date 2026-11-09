import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/home_location.dart';
import '../../core/l10n.dart';
import '../../core/location_service.dart';
import 'location_picker.dart';
import 'nearby_clubs_controller.dart';

/// The suggestion page: a rider without a club sees which clubs are within reach and may ask to join one.
class NearbyClubsScreen extends StatefulWidget {
  const NearbyClubsScreen({
    super.key,
    required this.controller,
    required this.locationService,
    required this.homeLocation,
    required this.userId,
    required this.onBack,
    required this.tileUrl,
    required this.attribution,
  });

  final NearbyClubsController controller;
  final LocationService locationService;
  final HomeLocation homeLocation;

  /// Whose saved fallback point to read, so a shared device never mixes two accounts.
  final String userId;

  final VoidCallback onBack;
  final String tileUrl;
  final String attribution;

  @override
  State<NearbyClubsScreen> createState() => _NearbyClubsScreenState();
}

class _NearbyClubsScreenState extends State<NearbyClubsScreen> {
  bool _locating = true;
  bool _fromHome = false;
  GeoPoint? _position;
  bool _askedDevice = false;

  static const _radii = [25, 50, 100, 200];

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _locating = true);
    final device = await widget.locationService.current();
    if (!mounted) return;
    if (device != null) {
      await _use(device, fromHome: false);
      return;
    }

    await widget.homeLocation.load(widget.userId);
    if (!mounted) return;
    final home = widget.homeLocation.position;
    if (home != null) {
      await _use(home, fromHome: true);
      return;
    }

    setState(() {
      _locating = false;
      _askedDevice = true;
    });
  }

  Future<void> _use(GeoPoint point, {required bool fromHome}) async {
    setState(() {
      _locating = false;
      _position = point;
      _fromHome = fromHome;
    });
    await widget.controller.refresh(point);
  }

  Future<GeoPoint?> _pick(GeoPoint? initial) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => LocationPickerScreen(
        initial: initial,
        tileUrl: widget.tileUrl,
        attribution: widget.attribution,
        locationService: widget.locationService,
      ),
    ),
  );

  Future<void> _setSavedLocation() async {
    final point = await _pick(_position);
    if (point == null || !mounted) return;
    await widget.homeLocation.load(widget.userId);
    await widget.homeLocation.save(point);
    await _use(point, fromHome: true);
  }

  Future<void> _ask(NearbyClubResponse club) async {
    final l10n = context.l10n;
    final pending = widget.controller.request;
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

    final failure = await widget.controller.askToJoin(club.id, note);
    if (!mounted) return;
    if (failure == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.nearbyRequestSent)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureText(l10n, failure))));
    }
  }

  Future<void> _cancelRequest() async {
    final failure = await widget.controller.cancelRequest();
    if (!mounted || failure == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failureText(context.l10n, failure))));
  }

  void _widen() {
    final current = widget.controller.radiusKm;
    final next = _radii.firstWhere(
      (km) => km > current,
      orElse: () => _radii.last,
    );
    final position = _position;
    if (position == null || next == current) return;
    widget.controller.refresh(position, radiusKm: next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = widget.controller;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.nearbyTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (_locating) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.nearbyLocating),
                ],
              ),
            );
          }

          final position = _position;
          if (position == null) {
            return _WhereAreYou(
              askedDevice: _askedDevice,
              onUseDevice: _start,
              onPick: _setSavedLocation,
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.refresh(position),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(l10n.nearbyIntro),
                const SizedBox(height: 8),
                Text(
                  l10n.nearbyLocationHelp,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_fromHome) ...[
                  const SizedBox(height: 8),
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
                        onPressed: _setSavedLocation,
                        child: Text(l10n.clubLocationChange),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final km in _radii)
                            ChoiceChip(
                              key: Key('radius-$km'),
                              label: Text(l10n.nearbyRadius(km)),
                              selected: controller.radiusKm == km,
                              onSelected: controller.busy
                                  ? null
                                  : (_) => controller.refresh(
                                      position,
                                      radiusKm: km,
                                    ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      key: const Key('nearby-relocate'),
                      tooltip: l10n.nearbyUseDevice,
                      onPressed: _start,
                      icon: const Icon(Icons.my_location),
                    ),
                    const SizedBox(width: 4),
                    IconButton.filledTonal(
                      key: const Key('nearby-set-location'),
                      tooltip: l10n.nearbySetHome,
                      onPressed: _setSavedLocation,
                      icon: const Icon(Icons.edit_location_alt_outlined),
                    ),
                  ],
                ),
                if (controller.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    failureText(l10n, controller.error!),
                    key: const Key('nearby-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (controller.request != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    key: const Key('pending-join-request'),
                    color: Theme.of(context).colorScheme.secondaryContainer
                        .withValues(alpha: 0.5),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 6,
                        children: [
                          Text(
                            l10n.nearbyPendingTitle(
                              controller.request!.clubName,
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(l10n.nearbyPendingBody),
                          if (controller.request!.note != null)
                            Text('“${controller.request!.note}”'),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              key: const Key('cancel-join-request'),
                              onPressed: controller.busy
                                  ? null
                                  : _cancelRequest,
                              child: Text(l10n.nearbyCancel),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (controller.loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (controller.clubs.isEmpty &&
                    controller.error == null) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      l10n.nearbyEmpty(controller.radiusKm),
                      key: const Key('nearby-empty'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (controller.radiusKm < _radii.last) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        key: const Key('nearby-widen'),
                        onPressed: _widen,
                        child: Text(l10n.nearbyWiden),
                      ),
                    ),
                  ],
                ] else
                  for (final club in controller.clubs)
                    _ClubRow(
                      club: club,
                      requested: controller.request?.clubId == club.id,
                      busy: controller.busy,
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
      padding: const EdgeInsets.all(24),
      children: [
        Text(l10n.nearbyTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(l10n.nearbyIntro),
        const SizedBox(height: 24),
        if (askedDevice) ...[
          Text(
            l10n.locationCurrentUnavailable,
            key: const Key('nearby-location-denied'),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.tonalIcon(
          key: const Key('nearby-use-device'),
          onPressed: onUseDevice,
          icon: const Icon(Icons.my_location),
          label: Text(l10n.nearbyUseDevice),
        ),
        const SizedBox(height: 8),
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
