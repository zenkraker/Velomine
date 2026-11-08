import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../../core/failure.dart';
import '../../../core/format.dart';
import '../../../core/l10n.dart';
import '../../../core/theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../rides_screen.dart';
import 'ride_detail_controller.dart';
import 'ride_feel_card.dart';
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
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteRideTitle),
        content: Text(l10n.deleteRideBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepIt),
          ),
          FilledButton(
            key: const Key('confirm-delete'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
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
                        label: Text(context.l10n.navRides),
                      ),
                      const Spacer(),
                      if (c.ride != null)
                        TextButton.icon(
                          key: const Key('delete'),
                          onPressed: _confirmDelete,
                          icon: const Icon(Icons.delete_outline),
                          label: Text(context.l10n.delete),
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
    final l10n = context.l10n;
    final error = Theme.of(context).colorScheme.error;
    if (c.notFound) {
      return [
        Text(
          l10n.rideNotFound,
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
          c.error == null ? l10n.couldNotLoadRide : failureText(l10n, c.error!),
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
          failureText(l10n, c.error!),
          key: const Key('ride-error'),
          style: TextStyle(color: error),
        ),
      if (ride.status == 'processing')
        Row(
          spacing: 8,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            Text(l10n.readingFile, key: const Key('processing')),
          ],
        )
      else if (ride.status == 'failed')
        Text(
          rideErrorText(l10n, ride.error),
          key: const Key('ride-failed'),
          style: TextStyle(color: error),
        )
      else ...[
        _Stats(ride: ride),
        if (heartRateZones.isEmpty &&
            powerZones.isEmpty &&
            (ride.avgHeartRate != null || ride.avgPowerW != null))
          Text(
            l10n.trainingHint,
            key: const Key('training-hint'),
            style: text.bodySmall,
          ),
        if (heartRateZones.isNotEmpty)
          _ZonesCard(
            key: const Key('heart-rate-zones'),
            title: l10n.heartRateZones,
            unit: 'bpm',
            zones: heartRateZones,
            colors: _heartRateZoneColors,
          ),
        if (powerZones.isNotEmpty)
          _ZonesCard(
            key: const Key('power-zones'),
            title: l10n.powerZones,
            unit: 'W',
            zones: powerZones,
            colors: _powerZoneColors,
          ),
        if (c.bikes.isNotEmpty || ride.bikeId != null)
          _BikePicker(controller: c, ride: ride),
        RideFeelCard(
          feel: c.feel,
          saving: c.savingFeel,
          onSave: c.saveFeel,
          onDelete: c.deleteFeel,
        ),
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
              index == null ? l10n.momentHint : _moment(l10n, c, index),
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

  String _moment(AppLocalizations l10n, RideDetailController c, int index) {
    final d = c.data!;
    final distance = d.distance == null ? null : d.distance![index];
    return l10n.momentAt(
      clock(d.time[index]),
      distance == null ? '' : ' · ${km(distance)}',
    );
  }
}

/// The ride's numbers as small tiles: only the ones the ride has.
class _Stats extends StatelessWidget {
  const _Stats({required this.ride});

  final RideResponse ride;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tiles = <(String, String, String)>[
      ('distance', l10n.statDistance, km(ride.distanceM)),
      ('moving-time', l10n.statMovingTime, duration(ride.movingS)),
      if (ride.elapsedS != null &&
          ride.movingS != null &&
          ride.elapsedS! - ride.movingS! > 60)
        ('elapsed-time', l10n.statElapsedTime, duration(ride.elapsedS)),
      if (ride.elevationGainM != null)
        ('climbing', l10n.statClimbing, '${ride.elevationGainM!.round()} m'),
      if (ride.elevationLossM != null)
        (
          'descending',
          l10n.statDescending,
          '${ride.elevationLossM!.round()} m',
        ),
      ('average-speed', l10n.statAverageSpeed, kmh(ride.avgSpeedMs)),
      if (ride.maxSpeedMs != null)
        ('top-speed', l10n.statTopSpeed, kmh(ride.maxSpeedMs)),
      if (ride.avgPowerW != null)
        ('average-power', l10n.statAveragePower, '${ride.avgPowerW} W'),
      if (ride.normalizedPowerW != null)
        (
          'normalized-power',
          l10n.statNormalizedPower,
          '${ride.normalizedPowerW} W',
        ),
      if (ride.maxPowerW != null)
        ('max-power', l10n.statMaxPower, '${ride.maxPowerW} W'),
      if (ride.intensityFactor != null)
        (
          'intensity',
          l10n.statIntensity,
          ride.intensityFactor!.toStringAsFixed(2),
        ),
      if (ride.tss != null) ('tss', l10n.statTss, ride.tss!.round().toString()),
      if (ride.trimp != null)
        ('trimp', l10n.statTrimp, ride.trimp!.round().toString()),
      if (ride.avgHeartRate != null)
        (
          'average-heart-rate',
          l10n.statAverageHeartRate,
          '${ride.avgHeartRate} bpm',
        ),
      if (ride.maxHeartRate != null)
        ('max-heart-rate', l10n.statMaxHeartRate, '${ride.maxHeartRate} bpm'),
      if (ride.avgCadence != null)
        ('average-cadence', l10n.statAverageCadence, '${ride.avgCadence} rpm'),
    ];
    final text = Theme.of(context).textTheme;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final (id, label, value) in tiles)
          Container(
            key: Key('stat-$id'),
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
          Text(l10n.speedFromGps, style: text.bodySmall),
        if (ride.tss != null || ride.trimp != null)
          Text(l10n.loadHint, style: text.bodySmall),
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
    final l10n = context.l10n;
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
                label: l10n.zoneSemantics(
                  zone.zone,
                  _range(l10n, zone),
                  duration(zone.seconds),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text('Z${zone.zone}', style: text.labelMedium),
                    ),
                    SizedBox(
                      width: 92,
                      child: Text(_range(l10n, zone), style: text.labelSmall),
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

  String _range(AppLocalizations l10n, ZoneTime zone) => zone.to == null
      ? l10n.zoneRangeOpen(zone.from, unit)
      : l10n.zoneRange(zone.from, zone.to!, unit);
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
      decoration: InputDecoration(labelText: context.l10n.bike),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(context.l10n.noBike),
        ),
        for (final b in bikes)
          DropdownMenuItem<String?>(value: b.id, child: Text(b.name)),
      ],
      onChanged: controller.setBike,
    );
  }
}
