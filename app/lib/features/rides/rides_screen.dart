import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/placeholder_block.dart';
import '../../core/l10n.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/stat_tile.dart';
import '../../l10n/generated/app_localizations.dart';
import 'ride_type_chips.dart';
import 'rides_view_model.dart';
import '../../core/tokens.dart';
import '../../core/widgets/empty_state.dart';

String rideErrorText(AppLocalizations l10n, String? code) => switch (code) {
  'corrupt_file' => l10n.rideErrorCorrupt,
  'invalid_file' => l10n.rideErrorInvalid,
  'unsupported_format' => l10n.rideErrorUnsupported,
  'not_cycling' => l10n.rideErrorNotCycling,
  'no_timestamps' => l10n.rideErrorNoTimestamps,
  'no_records' || 'too_short' => l10n.rideErrorNoRecords,
  'file_too_large' => l10n.rideErrorTooLarge,
  _ => l10n.rideErrorUnknown,
};

class RidesScreen extends ConsumerStatefulWidget {
  const RidesScreen({
    super.key,
    required this.onOpen,
    this.showSoloCard = false,
    this.onOpenClubs,
    this.onDismissSoloCard,
  });

  /// Called with a ride's id when its card is pressed.
  final void Function(String id) onOpen;

  /// Whether to point a rider without a club at the nearby clubs.
  final bool showSoloCard;
  final VoidCallback? onOpenClubs;
  final VoidCallback? onDismissSoloCard;

  @override
  ConsumerState<RidesScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends ConsumerState<RidesScreen> {
  @override
  void initState() {
    super.initState();
    // The ViewModel keeps the offset; the list has no size yet, so it is applied after the frame.
    final vm = ref.read(ridesViewModelProvider.notifier);
    if (vm.scrollOffset <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !vm.scroll.hasClients) return;
      vm.scroll.jumpTo(
        vm.scrollOffset.clamp(0, vm.scroll.position.maxScrollExtent),
      );
    });
  }

  /// Called with a ride's id when its card is pressed.
  void Function(String id) get onOpen => widget.onOpen;
  bool get showSoloCard => widget.showSoloCard;
  VoidCallback? get onOpenClubs => widget.onOpenClubs;
  VoidCallback? get onDismissSoloCard => widget.onDismissSoloCard;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(ridesViewModelProvider);
    final l10n = context.l10n;

    listenUserMessages(
      ref,
      context,
      ridesViewModelProvider.select((s) => s.messages),
      ref.read(ridesViewModelProvider.notifier).messageShown,
    );

    // One column on a phone; on a tablet the list keeps a readable measure instead of stretching.
    final width = MediaQuery.sizeOf(context).width;
    final side = math.max(16.0, (width - 720) / 2);
    final wide = width >= 600;
    final upload = s.upload.running
        ? null
        : () => ref.read(ridesViewModelProvider.notifier).upload();
    return Scaffold(
      backgroundColor: Colors.transparent,
      // Wide: the action sits with the list. Compact: it floats, and the list ends above it.
      floatingActionButton: wide
          ? null
          : FloatingActionButton.extended(
              key: const Key('upload'),
              onPressed: upload,
              icon: const Icon(Icons.upload_file),
              label: Text(s.upload.running ? l10n.uploading : l10n.uploadRide),
            ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(ridesViewModelProvider.notifier).refresh(),
        child: ListView(
          controller: ref.read(ridesViewModelProvider.notifier).scroll,
          padding: EdgeInsets.fromLTRB(side, 8, side, wide ? 16 : 96),
          children: [
            if (wide)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const Key('upload'),
                  onPressed: upload,
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    s.upload.running ? l10n.uploading : l10n.uploadRide,
                  ),
                ),
              ),
            if (s.load.failure case final failure?)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  failureText(l10n, failure),
                  key: const Key('rides-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (showSoloCard && onOpenClubs != null)
              Card(
                key: const Key('solo-club-card'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.soloHintTitle,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            key: const Key('dismiss-solo-card'),
                            tooltip: l10n.soloHintDismiss,
                            onPressed: onDismissSoloCard,
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      Text(l10n.soloHintBody),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: const Key('open-nearby-from-rides'),
                          onPressed: onOpenClubs,
                          icon: const Icon(Icons.explore_outlined),
                          label: Text(l10n.soloHintSee),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: AppSpacing.sm,
                  children: [
                    ChoiceChip(
                      key: const Key('filter-all'),
                      label: Text(l10n.rideFilterAll),
                      selected: s.disciplineFilter == null,
                      onSelected: (_) => ref
                          .read(ridesViewModelProvider.notifier)
                          .setDisciplineFilter(null),
                    ),
                    for (final discipline in [
                      'road',
                      'gravel',
                      'mountain',
                      'track',
                    ])
                      ChoiceChip(
                        key: Key('filter-$discipline'),
                        label: Text(disciplineName(l10n, discipline)),
                        selected: s.disciplineFilter == discipline,
                        onSelected: (_) => ref
                            .read(ridesViewModelProvider.notifier)
                            .setDisciplineFilter(discipline),
                      ),
                  ],
                ),
              ),
            ),
            if (s.rides.isEmpty && !s.load.running)
              EmptyState(
                key: const Key('no-rides'),
                message: l10n.noRides,
                icon: Icons.directions_bike,
              ),
            for (final ride in s.rides)
              RideCard(ride: ride, onTap: () => onOpen(ride.id)),
            if (s.next != null)
              TextButton(
                key: const Key('load-more'),
                onPressed: s.load.running
                    ? null
                    : () =>
                          ref.read(ridesViewModelProvider.notifier).loadMore(),
                child: Text(l10n.loadMore),
              ),
            if (s.load.running && s.rides.isEmpty)
              Semantics(
                liveRegion: true,
                label: l10n.loading,
                child: Column(
                  key: const Key('rides-loading'),
                  children: [
                    for (var i = 0; i < 5; i++)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: PlaceholderBlock(height: 96, radius: 16),
                      ),
                  ],
                ),
              )
            else if (s.load.running)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class RideCard extends StatelessWidget {
  const RideCard({super.key, required this.ride, this.onTap});

  final RideResponse ride;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final ready = ride.status == 'ready';
    // A file with no samples parses but says nothing: it reads as empty, not as a ride of zeros.
    final empty =
        ready && (ride.distanceM ?? 0) <= 0 && (ride.movingS ?? 0) <= 0;
    // Each number carries its name: a row of unlabelled values is a puzzle on a phone.
    final facts = <(String, String)>[
      if (ready) ...[
        (l10n.statDistance, km(ride.distanceM)),
        (l10n.statMovingTime, duration(ride.movingS)),
        if (ride.elevationGainM != null)
          (l10n.statClimbing, l10n.metresUp(ride.elevationGainM!.round())),
        (l10n.statAverageSpeed, kmh(ride.avgSpeedMs)),
        if (ride.avgPowerW != null)
          (
            l10n.statAveragePower,
            '${ride.avgPowerW} W${ride.normalizedPowerW == null ? '' : ' (NP ${ride.normalizedPowerW})'}',
          ),
        if (ride.avgHeartRate != null)
          (l10n.statAverageHeartRate, '${ride.avgHeartRate} bpm'),
        if (ride.avgCadence != null)
          (l10n.statAverageCadence, '${ride.avgCadence} rpm'),
      ],
    ];
    return Card(
      key: Key('ride-${ride.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateTime(ride.startTime ?? ride.uploadedAt),
                style: text.titleMedium,
              ),
              Text(ride.fileName, style: text.bodySmall),
              if (ready && rideTypeIsSet(ride)) ...[
                const SizedBox(height: 6),
                RideTypeChips(ride: ride),
              ],
              const SizedBox(height: AppSpacing.sm),
              if (ride.status == 'processing')
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.readingFile, key: const Key('processing')),
                  ],
                )
              else if (ride.status == 'failed')
                Text(
                  rideErrorText(l10n, ride.error),
                  key: const Key('ride-failed'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                )
              else if (empty)
                Text(
                  l10n.rideNoData,
                  key: const Key('ride-no-data'),
                  style: text.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: statRowSpacing,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final (label, value) in facts)
                      StatTile(label: label, value: value),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
