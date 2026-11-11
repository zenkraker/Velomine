import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../../core/failure.dart';
import '../../../core/format.dart';
import '../../../core/placeholder_block.dart';
import '../../../core/l10n.dart';
import '../../../core/theme.dart';
import '../../../core/user_message_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../rides_screen.dart';
import '../ride_type_chips.dart';
import '../ride_type_sheet.dart';
import 'lap_table.dart';
import 'ride_detail_state.dart';
import 'ride_detail_view_model.dart';
import 'ride_feel_card.dart';
import 'ride_selection.dart';
import 'route_map.dart';
import 'scale.dart';
import 'series_chart.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/stat_tile.dart';

class RideDetailScreen extends ConsumerWidget {
  const RideDetailScreen({
    super.key,
    required this.id,
    required this.onDeleted,
    this.tileUrl,
    this.attribution,
  });

  final String id;
  final VoidCallback onDeleted;
  final String? tileUrl;
  final String? attribution;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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
    if (ok == true &&
        await ref.read(rideDetailViewModelProvider(id).notifier).deleteRide()) {
      onDeleted();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(rideDetailViewModelProvider(id));
    final selection = ref.watch(rideSelectionProvider(id));
    final l10n = context.l10n;

    listenUserMessages(
      ref,
      context,
      rideDetailViewModelProvider(id).select((s) => s.messages),
      ref.read(rideDetailViewModelProvider(id).notifier).messageShown,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.lg,
              children: [
                // One menu for the rare actions: a ride's numbers stay the loudest thing on the screen.
                if (s.ride != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: PopupMenuButton<String>(
                      key: const Key('ride-actions'),
                      tooltip: l10n.rideActions,
                      icon: const Icon(Icons.more_vert),
                      onSelected: (_) => _confirmDelete(context, ref),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          key: const Key('delete'),
                          value: 'delete',
                          child: Text(
                            l10n.delete,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ..._body(context, ref, s, selection),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _body(
    BuildContext context,
    WidgetRef ref,
    RideDetailState s,
    RideSelection selection,
  ) {
    final text = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final error = Theme.of(context).colorScheme.error;
    if (s.notFound) {
      return [
        Text(
          l10n.rideNotFound,
          key: const Key('not-found'),
          style: text.titleMedium,
        ),
      ];
    }
    if (s.load.running && s.ride == null) {
      return [
        Semantics(
          liveRegion: true,
          label: l10n.loading,
          child: Column(
            key: const Key('ride-loading'),
            children: [
              Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: PlaceholderBlock(height: 64),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const PlaceholderBlock(height: 180, radius: 16),
            ],
          ),
        ),
      ];
    }
    final ride = s.ride;
    if (ride == null) {
      return [
        Text(
          s.load.failure == null
              ? l10n.couldNotLoadRide
              : failureText(l10n, s.load.failure!),
          key: const Key('ride-error'),
          style: TextStyle(color: error),
        ),
      ];
    }
    final notifier = ref.read(rideDetailViewModelProvider(id).notifier);
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
      if (s.load.failure case final failure?)
        Text(
          failureText(l10n, failure),
          key: const Key('ride-error'),
          style: TextStyle(color: error),
        ),
      if (ride.status == 'processing')
        Row(
          spacing: AppSpacing.sm,
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
        Row(
          children: [
            Expanded(
              child: rideTypeIsSet(ride)
                  ? RideTypeChips(ride: ride)
                  : const SizedBox.shrink(),
            ),
            TextButton.icon(
              key: const Key('edit-ride-type'),
              onPressed: () => showRideTypeSheet(
                context,
                ride,
                ({
                  String? discipline,
                  String? assist,
                  String? environment,
                  bool? commute,
                }) => notifier.setType(
                  discipline: discipline,
                  assist: assist,
                  environment: environment,
                  commute: commute,
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(
                rideTypeIsSet(ride) ? l10n.rideTypeEdit : l10n.rideTypeNotSet,
              ),
            ),
          ],
        ),
        _Stats(ride: ride),
        if (s.laps.isNotEmpty)
          LapTable(laps: s.laps, selectedLap: selection.selectedLap),
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
        if (s.bikes.isNotEmpty || ride.bikeId != null)
          _BikePicker(bikes: s.bikes, ride: ride, onChanged: notifier.setBike),
        RideFeelCard(
          feel: s.feel,
          saving: s.feelCommand.running,
          onSave: notifier.saveFeel,
          onDelete: notifier.deleteFeel,
        ),
        if (s.series?.hasRoute ?? false)
          RouteMap(
            data: s.series!,
            selected: selection.selected,
            selectedLap: selection.selectedLap,
            tileUrl: tileUrl,
            attribution: attribution,
            elevationGainM: ride.elevationGainM,
          ),
        if (s.series != null && s.series!.series.isNotEmpty) ...[
          ValueListenableBuilder<int?>(
            valueListenable: selection.selected,
            builder: (_, index, _) => Text(
              index == null ? l10n.momentHint : _moment(l10n, s, index),
              key: const Key('moment'),
              style: text.bodyMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          for (final series in s.series!.series)
            SeriesChart(
              series: series,
              time: s.series!.time,
              selected: selection.selected,
              selectedLap: selection.selectedLap,
              color:
                  VelomineColors.of(context).series[series.id] ??
                  Theme.of(context).colorScheme.primary,
            ),
        ],
      ],
    ];
  }

  String _moment(AppLocalizations l10n, RideDetailState s, int index) {
    final data = s.series!;
    final distance = data.distance == null ? null : data.distance![index];
    return l10n.momentAt(
      clock(data.time[index]),
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
      spacing: AppSpacing.md,
      runSpacing: 12,
      children: [
        for (final (id, label, value) in tiles)
          StatTile(
            key: Key('stat-$id'),
            label: label,
            value: value,
            boxed: true,
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
        padding: const EdgeInsets.all(AppSpacing.lg),
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
            const SizedBox(height: AppSpacing.md),
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
  const _BikePicker({
    required this.bikes,
    required this.ride,
    required this.onChanged,
  });

  final List<BikeResponse> bikes;
  final RideResponse ride;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final shown = bikes
        .where((b) => b.isActive || b.id == ride.bikeId)
        .toList();
    // A bike this list does not know (deleted meanwhile) must not break the dropdown.
    final value = shown.any((b) => b.id == ride.bikeId) ? ride.bikeId : null;
    return DropdownButtonFormField<String?>(
      key: ValueKey('ride-bike-$value'),
      initialValue: value,
      decoration: InputDecoration(labelText: context.l10n.bike),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(context.l10n.noBike),
        ),
        for (final b in shown)
          DropdownMenuItem<String?>(value: b.id, child: Text(b.name)),
      ],
      onChanged: onChanged,
    );
  }
}
