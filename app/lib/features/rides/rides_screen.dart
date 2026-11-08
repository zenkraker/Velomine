import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../l10n/generated/app_localizations.dart';
import 'rides_controller.dart';

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
  });

  final RidesController controller;

  /// Called with a ride's id when its card is pressed.
  final void Function(String id) onOpen;

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
            label: Text(c.uploading ? 'Uploading…' : 'Upload ride'),
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
                if (c.rides.isEmpty && !c.loading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No rides yet. Upload a FIT, GPX or TCX file.',
                        key: Key('no-rides'),
                      ),
                    ),
                  ),
                for (final ride in c.rides)
                  RideCard(ride: ride, onTap: () => widget.onOpen(ride.id)),
                if (c.next != null)
                  TextButton(
                    key: const Key('load-more'),
                    onPressed: c.loadMore,
                    child: const Text('Load more'),
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
    final ready = ride.status == 'ready';
    final facts = <String>[
      if (ready) ...[
        km(ride.distanceM),
        duration(ride.movingS),
        if (ride.elevationGainM != null) '${ride.elevationGainM!.round()} m up',
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
              const SizedBox(height: 8),
              if (ride.status == 'processing')
                const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Reading the file…', key: Key('processing')),
                  ],
                )
              else if (ride.status == 'failed')
                Text(
                  rideErrorText(context.l10n, ride.error),
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
