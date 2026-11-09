import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../l10n/generated/app_localizations.dart';
import 'rides_controller.dart';
import 'ride_type_chips.dart';

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

class RidesScreen extends StatefulWidget {
  const RidesScreen({
    super.key,
    required this.controller,
    required this.onOpen,
    this.showSoloCard = false,
    this.onOpenClubs,
    this.onDismissSoloCard,
  });

  final RidesController controller;

  /// Called with a ride's id when its card is pressed.
  final void Function(String id) onOpen;

  /// Whether to point a rider without a club at the nearby clubs.
  final bool showSoloCard;
  final VoidCallback? onOpenClubs;
  final VoidCallback? onDismissSoloCard;

  @override
  State<RidesScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends State<RidesScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('upload'),
            onPressed: c.uploading ? null : c.upload,
            icon: const Icon(Icons.upload_file),
            label: Text(
              c.uploading ? context.l10n.uploading : context.l10n.uploadRide,
            ),
          ),
          body: RefreshIndicator(
            onRefresh: c.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                if (c.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      failureText(context.l10n, c.error!),
                      key: const Key('rides-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (widget.showSoloCard && widget.onOpenClubs != null)
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
                                  context.l10n.soloHintTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                              IconButton(
                                key: const Key('dismiss-solo-card'),
                                tooltip: context.l10n.soloHintDismiss,
                                onPressed: widget.onDismissSoloCard,
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          Text(context.l10n.soloHintBody),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              key: const Key('open-nearby-from-rides'),
                              onPressed: widget.onOpenClubs,
                              icon: const Icon(Icons.explore_outlined),
                              label: Text(context.l10n.soloHintSee),
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
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          key: const Key('filter-all'),
                          label: Text(context.l10n.rideFilterAll),
                          selected: c.disciplineFilter == null,
                          onSelected: (_) => c.setDisciplineFilter(null),
                        ),
                        for (final discipline in [
                          'road',
                          'gravel',
                          'mountain',
                          'track',
                        ])
                          ChoiceChip(
                            key: Key('filter-$discipline'),
                            label: Text(
                              disciplineName(context.l10n, discipline),
                            ),
                            selected: c.disciplineFilter == discipline,
                            onSelected: (_) =>
                                c.setDisciplineFilter(discipline),
                          ),
                      ],
                    ),
                  ),
                ),
                if (c.rides.isEmpty && !c.loading)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        context.l10n.noRides,
                        key: const Key('no-rides'),
                      ),
                    ),
                  ),
                for (final ride in c.rides)
                  RideCard(ride: ride, onTap: () => widget.onOpen(ride.id)),
                if (c.next != null)
                  TextButton(
                    key: const Key('load-more'),
                    onPressed: c.loadMore,
                    child: Text(context.l10n.loadMore),
                  ),
                if (c.loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
    final facts = <String>[
      if (ready) ...[
        km(ride.distanceM),
        duration(ride.movingS),
        if (ride.elevationGainM != null)
          l10n.metresUp(ride.elevationGainM!.round()),
        kmh(ride.avgSpeedMs),
        if (ride.avgPowerW != null)
          '${ride.avgPowerW} W${ride.normalizedPowerW == null ? '' : ' (NP ${ride.normalizedPowerW})'}',
        if (ride.avgHeartRate != null) '${ride.avgHeartRate} bpm',
        if (ride.avgCadence != null) '${ride.avgCadence} rpm',
      ],
    ];
    return Card(
      key: Key('ride-${ride.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 8),
              if (ride.status == 'processing')
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.readingFile, key: const Key('processing')),
                  ],
                )
              else if (ride.status == 'failed')
                Text(
                  rideErrorText(l10n, ride.error),
                  key: const Key('ride-failed'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [for (final f in facts) Text(f)],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
