import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../rides_screen.dart';
import 'ride_detail_controller.dart';
import 'route_map.dart';
import 'scale.dart';
import 'series_chart.dart';

class RideDetailScreen extends StatefulWidget {
  const RideDetailScreen({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onDeleted,
    this.tileUrl,
    this.attribution,
  });

  final RideDetailController controller;
  final VoidCallback onBack;
  final VoidCallback onDeleted;
  final String? tileUrl;
  final String? attribution;

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this ride?'),
        content: const Text(
          'The ride, its charts and the file you uploaded are removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            key: const Key('confirm-delete'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && await widget.controller.delete()) widget.onDeleted();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        key: const Key('back'),
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Rides'),
                      ),
                      const Spacer(),
                      if (c.ride != null)
                        TextButton.icon(
                          key: const Key('delete'),
                          onPressed: _confirmDelete,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .error,
                          ),
                        ),
                    ],
                  ),
                  ..._body(context, c),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _body(BuildContext context, RideDetailController c) {
    final text = Theme.of(context).textTheme;
    final error = Theme.of(context).colorScheme.error;
    if (c.notFound) {
      return [
        Text(
          'This ride does not exist, or it is not yours.',
          key: const Key('not-found'),
          style: text.titleMedium,
        ),
      ];
    }
    if (c.loading && c.ride == null) {
      return const [
        Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      ];
    }
    final ride = c.ride;
    if (ride == null) {
      return [
        Text(
          c.error ?? 'Could not load this ride.',
          key: const Key('ride-error'),
          style: TextStyle(color: error),
        ),
      ];
    }
    final heartRateZones =
        ride.heartRateZones.orElse(null) ?? const <ZoneTime>[];
    final powerZones = ride.powerZones.orElse(null) ?? const <ZoneTime>[];

    return [
      Text(
        dateTime(ride.startTime ?? ride.uploadedAt),
        style: text.headlineSmall,
      ),
      Text(
        [ride.fileName, if (ride.device != null) ride.device!].join(' · '),
        style: text.bodyMedium,
      ),
      if (c.error != null)
        Text(
          c.error!,
          key: const Key('ride-error'),
          style: TextStyle(color: error),
        ),
      if (ride.status == 'processing')
        const Row(
          spacing: 8,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            Text('Reading the file…', key: Key('processing')),
          ],
        )
      else if (ride.status == 'failed')
        Text(
          rideErrorText(ride.error),
          key: const Key('ride-failed'),
          style: TextStyle(color: error),
        )
      else ...[
        _Stats(ride: ride),
        if (heartRateZones.isEmpty &&
            powerZones.isEmpty &&
            (ride.avgHeartRate != null || ride.avgPowerW != null))
          Text(
            'Set your maximum heart rate and FTP in your profile to see zones '
            'and training load.',
            key: const Key('training-hint'),
            style: text.bodySmall,
          ),
        if (heartRateZones.isNotEmpty)
          _ZonesCard(
            key: const Key('heart-rate-zones'),
            title: 'Heart rate zones',
            unit: 'bpm',
            zones: heartRateZones,
            colors: _heartRateZoneColors,
          ),
        if (powerZones.isNotEmpty)
          _ZonesCard(
            key: const Key('power-zones'),
            title: 'Power zones',
            unit: 'W',
            zones: powerZones,
            colors: _powerZoneColors,
          ),
        if (c.bikes.isNotEmpty || ride.bikeId != null)
          _BikePicker(controller: c, ride: ride),
        if (c.data?.hasRoute ?? false)
          RouteMap(
            data: c.data!,
            selected: c.selected,
            tileUrl: widget.tileUrl,
            attribution: widget.attribution,
          ),
        if (c.data != null && c.data!.series.isNotEmpty) ...[
          ValueListenableBuilder<int?>(
            valueListenable: c.selected,
            builder: (_, index, _) => Text(
              index == null
                  ? 'Move over a chart, or touch and drag, to see the values along the ride.'
                  : _moment(c, index),
              key: const Key('moment'),
              style: text.bodyMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          for (final series in c.data!.series)
            SeriesChart(
              series: series,
              time: c.data!.time,
              selected: c.selected,
              color:
                  VelomineColors.of(context).series[series.id] ??
                  Theme.of(context).colorScheme.primary,
            ),
        ],
      ],
    ];
  }

  String _moment(RideDetailController c, int index) {
    final d = c.data!;
    final distance = d.distance == null ? null : d.distance![index];
    return 'At ${clock(d.time[index])}${distance == null ? '' : ' · ${km(distance)}'}';
  }
}

/// The ride's numbers as small tiles: only the ones the ride has.
class _Stats extends StatelessWidget {
  const _Stats({required this.ride});

  final RideResponse ride;

  @override
  Widget build(BuildContext context) {
    final tiles = <(String, String)>[
      ('Distance', km(ride.distanceM)),
      ('Moving time', duration(ride.movingS)),
      if (ride.elapsedS != null &&
          ride.movingS != null &&
          ride.elapsedS! - ride.movingS! > 60)
        ('Elapsed time', duration(ride.elapsedS)),
      if (ride.elevationGainM != null)
        ('Climbing', '${ride.elevationGainM!.round()} m'),
      if (ride.elevationLossM != null)
        ('Descending', '${ride.elevationLossM!.round()} m'),
      ('Average speed', kmh(ride.avgSpeedMs)),
      if (ride.maxSpeedMs != null) ('Top speed', kmh(ride.maxSpeedMs)),
      if (ride.avgPowerW != null) ('Average power', '${ride.avgPowerW} W'),
      if (ride.normalizedPowerW != null)
        ('Normalized power', '${ride.normalizedPowerW} W'),
      if (ride.maxPowerW != null) ('Max power', '${ride.maxPowerW} W'),
      if (ride.intensityFactor != null)
        ('Intensity', ride.intensityFactor!.toStringAsFixed(2)),
      if (ride.tss != null) ('TSS', ride.tss!.round().toString()),
      if (ride.trimp != null) ('TRIMP', ride.trimp!.round().toString()),
      if (ride.avgHeartRate != null)
        ('Average heart rate', '${ride.avgHeartRate} bpm'),
      if (ride.maxHeartRate != null)
        ('Max heart rate', '${ride.maxHeartRate} bpm'),
      if (ride.avgCadence != null)
        ('Average cadence', '${ride.avgCadence} rpm'),
    ];
    final text = Theme.of(context).textTheme;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final (label, value) in tiles)
          Container(
            key: Key('stat-$label'),
            width: 150,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.labelMedium),
                const SizedBox(height: 2),
                Text(value, style: text.titleMedium),
              ],
            ),
          ),
        if (ride.speedSource == 'gps')
          Text(
            'Speed is worked out from GPS positions.',
            style: text.bodySmall,
          ),
        if (ride.tss != null || ride.trimp != null)
          Text(
            'TSS uses your FTP; TRIMP is time in heart-rate zones. '
            'Set both in your profile to see them.',
            style: text.bodySmall,
          ),
      ],
    );
  }
}

/// Time in each training zone, as a bar per zone.
class _ZonesCard extends StatelessWidget {
  const _ZonesCard({
    super.key,
    required this.title,
    required this.unit,
    required this.zones,
    required this.colors,
  });

  final String title;
  final String unit;
  final List<ZoneTime> zones;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final maxSeconds = zones.fold<double>(
      0,
      (largest, zone) => zone.seconds > largest ? zone.seconds : largest,
    );
    final total = zones.fold<double>(0, (sum, zone) => sum + zone.seconds);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: text.titleMedium),
                const Spacer(),
                Text(duration(total), style: text.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            for (final (index, zone) in zones.indexed) ...[
              Semantics(
                label:
                    'Zone ${zone.zone}, ${_range(zone)}, ${duration(zone.seconds)}',
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text('Z${zone.zone}', style: text.labelMedium),
                    ),
                    SizedBox(
                      width: 92,
                      child: Text(_range(zone), style: text.labelSmall),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: maxSeconds <= 0
                              ? 0
                              : zone.seconds / maxSeconds,
                          minHeight: 8,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(
                            colors[index % colors.length],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: Text(
                        duration(zone.seconds),
                        textAlign: TextAlign.right,
                        style: text.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < zones.length - 1) const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }

  String _range(ZoneTime zone) => zone.to == null
      ? '≥ ${zone.from} $unit'
      : '${zone.from}–${zone.to} $unit';
}

const _heartRateZoneColors = [
  Color(0xFF4A90E2),
  Color(0xFF4CAF50),
  Color(0xFFF2C14E),
  Color(0xFFF08A3C),
  Color(0xFFC0392B),
];

const _powerZoneColors = [
  Color(0xFF90A4AE),
  Color(0xFF4A90E2),
  Color(0xFF4CAF50),
  Color(0xFFF2C14E),
  Color(0xFFF08A3C),
  Color(0xFFC0392B),
  Color(0xFF8E44AD),
];

/// Which bike was ridden. An archived bike is only listed when this ride already uses it.
class _BikePicker extends StatelessWidget {
  const _BikePicker({required this.controller, required this.ride});

  final RideDetailController controller;
  final RideResponse ride;

  @override
  Widget build(BuildContext context) {
    final bikes = controller.bikes
        .where((b) => b.isActive || b.id == ride.bikeId)
        .toList();
    // A bike this list does not know (deleted meanwhile) must not break the dropdown.
    final value = bikes.any((b) => b.id == ride.bikeId) ? ride.bikeId : null;
    return DropdownButtonFormField<String?>(
      key: ValueKey('ride-bike-$value'),
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Bike'),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('No bike')),
        for (final b in bikes)
          DropdownMenuItem<String?>(value: b.id, child: Text(b.name)),
      ],
      onChanged: controller.setBike,
    );
  }
}
