import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
import 'rides_controller.dart';

String rideErrorText(String? code) => switch (code) {
  'corrupt_file' => 'The file is damaged or incomplete.',
  'invalid_file' => 'This is not a ride file.',
  'unsupported_format' => 'Only FIT, GPX and TCX files are supported.',
  'not_cycling' => 'This is not a cycling activity.',
  'no_timestamps' => 'The file has no timestamps.',
  'no_records' || 'too_short' => 'The file has no usable ride data.',
  'file_too_large' => 'The file is too large.',
  _ => 'The server could not read this file.',
};

class RidesScreen extends StatefulWidget {
  const RidesScreen({super.key, required this.controller});

  final RidesController controller;

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
                      c.error!,
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
                for (final ride in c.rides) RideCard(ride: ride),
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
  const RideCard({super.key, required this.ride});

  final RideResponse ride;

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
                rideErrorText(ride.error),
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
    );
  }
}
