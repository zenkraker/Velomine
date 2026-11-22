import '../../core/widgets/loading_state.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/location_service.dart';
import '../../core/providers.dart';
import '../../core/user_message_text.dart';
import 'location_picker.dart';
import 'nearby_clubs_state.dart';
import 'nearby_clubs_view_model.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/confirm.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/form_sheet.dart';
import '../../core/widgets/page_scaffold.dart';

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
      final replace = await confirmAction(
        context,
        title: l10n.nearbyReplaceTitle(pending.clubName),
        body: l10n.nearbyReplaceBody,
        action: l10n.nearbyRequestSend,
        key: const Key('confirm-replace-request'),
      );
      if (!replace || !mounted) return;
    }

    final note = await showSheet<String>(
      context,
      builder: (_) => _JoinRequestSheet(clubName: club.name),
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

    // The page is outside the shell, so it asks for the header on a phone too.
    return Scaffold(
      body: PageHeaderScope(
        showOnPhone: true,
        child: Builder(
          builder: (context) {
            final position = s.position;
            final nextRadius = position == null
                ? null
                : ref.read(nearbyClubsViewModelProvider.notifier).nextRadius();
            return PageScaffold(
              title: l10n.nearbyTitle,
              parent: l10n.navClub,
              onBack: widget.onBack,
              maxWidth: AppLayout.contentNarrow,
              refresh: position == null || s.locating
                  ? null
                  : () => ref
                        .read(nearbyClubsViewModelProvider.notifier)
                        .refresh(),
              children: [
                if (s.locating)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LoadingState(),
                        const SizedBox(height: AppSpacing.lg),
                        Text(l10n.nearbyLocating),
                      ],
                    ),
                  )
                else if (position == null)
                  ..._whereAreYou(s)
                else
                  ..._clubs(s, position, nextRadius),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _whereAreYou(NearbyClubsState s) {
    final l10n = context.l10n;
    return [
      Text(l10n.nearbyIntro),
      if (s.askedDevice)
        Text(
          l10n.locationCurrentUnavailable,
          key: const Key('nearby-location-denied'),
        ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          FilledButton.tonalIcon(
            key: const Key('nearby-use-device'),
            onPressed: () =>
                ref.read(nearbyClubsViewModelProvider.notifier).start(),
            icon: const Icon(Icons.my_location),
            label: Text(l10n.nearbyUseDevice),
          ),
          OutlinedButton.icon(
            key: const Key('nearby-set-location'),
            onPressed: () => _setSavedLocation(null),
            icon: const Icon(Icons.place),
            label: Text(l10n.nearbySetHome),
          ),
        ],
      ),
    ];
  }

  List<Widget> _clubs(NearbyClubsState s, GeoPoint position, int? nextRadius) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final notifier = ref.read(nearbyClubsViewModelProvider.notifier);
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Text(l10n.nearbyIntro),
          Text(l10n.nearbyLocationHelp, style: theme.textTheme.bodySmall),
          if (s.usingSavedPoint)
            Row(
              children: [
                Icon(
                  Icons.home_outlined,
                  size: AppClub.inlineIcon,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(l10n.nearbyHomeUsed)),
                TextButton(
                  key: const Key('change-home-location'),
                  onPressed: () => _setSavedLocation(position),
                  child: Text(l10n.clubLocationChange),
                ),
              ],
            ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final km in NearbyClubsViewModel.radii)
                  ChoiceChip(
                    key: Key('radius-$km'),
                    label: Text(l10n.nearbyRadius(km)),
                    selected: s.radiusKm == km,
                    onSelected: s.action.running || s.load.running
                        ? null
                        : (_) => notifier.setRadius(km),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filledTonal(
            key: const Key('nearby-relocate'),
            tooltip: l10n.nearbyUseDevice,
            onPressed: () => notifier.start(),
            icon: const Icon(Icons.my_location),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton.filledTonal(
            key: const Key('nearby-set-location'),
            tooltip: l10n.nearbySetHome,
            onPressed: () => _setSavedLocation(position),
            icon: const Icon(Icons.edit_location_alt_outlined),
          ),
        ],
      ),
      if (s.load.failure case final failure?)
        ErrorState(
          message: failureText(l10n, failure),
          actionKey: const Key('nearby-error'),
          onRetry: s.load.running ? null : () => notifier.refresh(),
        ),
      if (s.request != null)
        AppCard(
          key: const Key('pending-join-request'),
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.sm,
              children: [
                Text(
                  l10n.nearbyPendingTitle(s.request!.clubName),
                  style: theme.textTheme.titleMedium,
                ),
                Text(l10n.nearbyPendingBody),
                if (s.request!.note != null) Text('“${s.request!.note}”'),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const Key('cancel-join-request'),
                    onPressed: s.action.running
                        ? null
                        : () => notifier.cancelRequest(),
                    child: Text(l10n.nearbyCancel),
                  ),
                ),
              ],
            ),
          ),
        ),
      if (s.load.running)
        const LoadingState()
      else if (s.clubs.isEmpty && s.load.failure == null) ...[
        EmptyState(
          key: const Key('nearby-empty'),
          message: l10n.nearbyEmpty(s.radiusKm),
          icon: Icons.explore_outlined,
        ),
        if (nextRadius != null)
          Center(
            child: TextButton(
              key: const Key('nearby-widen'),
              onPressed: s.load.running
                  ? null
                  : () => notifier.setRadius(nextRadius),
              child: Text(l10n.nearbyWiden),
            ),
          ),
      ] else
        // The clubs are the rows of one card, nearest first.
        AppCard(
          key: const Key('nearby-clubs-card'),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final club in s.clubs)
                _ClubRow(
                  club: club,
                  requested: s.request?.clubId == club.id,
                  busy: s.action.running,
                  onAsk: () => _ask(club),
                ),
            ],
          ),
        ),
    ];
  }
}

class _JoinRequestSheet extends StatefulWidget {
  const _JoinRequestSheet({required this.clubName});

  final String clubName;

  @override
  State<_JoinRequestSheet> createState() => _JoinRequestSheetState();
}

class _JoinRequestSheetState extends State<_JoinRequestSheet> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      title: l10n.nearbyRequestTitle(widget.clubName),
      saveKey: const Key('send-join-request'),
      saveLabel: l10n.nearbyRequestSend,
      onSave: () => Navigator.of(context).pop(_note.text),
      children: [
        TextField(
          key: const Key('join-request-note'),
          controller: _note,
          maxLength: 300,
          maxLines: 3,
          decoration: InputDecoration(labelText: l10n.nearbyRequestNote),
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
    return ListTile(
      key: Key('nearby-club-${club.id}'),
      title: Text(club.name),
      subtitle: Text(
        '${l10n.clubMemberCount(club.memberCount)} · '
        '${l10n.nearbyDistance(club.distanceKm.round())}',
      ),
      trailing: requested
          ? AppBadge(
              l10n.nearbyRequested,
              key: Key('requested-${club.id}'),
              tone: AppBadgeTone.good,
            )
          : FilledButton.tonal(
              key: Key('ask-${club.id}'),
              onPressed: busy ? null : onAsk,
              child: Text(l10n.nearbyAsk),
            ),
    );
  }
}
