import 'dart:async' show scheduleMicrotask;

import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../../core/failure.dart';
import '../../../core/format.dart';
import '../../../core/heart_rate_zones.dart';
import '../../../core/hooks.dart';
import '../../../core/placeholder_block.dart';
import '../../../core/confirm.dart';
import '../../../core/l10n.dart';
import '../../../core/rider_mode.dart';
import '../../../core/theme.dart';
import '../../../core/user_message_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../rides_screen.dart';
import '../ride_text_sheet.dart';
import '../ride_title.dart';
import '../ride_type_chips.dart';
import '../ride_type_sheet.dart';
import '../../progress/events.dart';
import '../../progress/progress_view_models.dart';
import 'lap_table.dart';
import 'effort_word.dart';
import 'power_record_chips.dart';
import 'ride_detail_state.dart';
import 'ride_detail_view_model.dart';
import 'ride_feel_card.dart';
import 'ride_selection.dart';
import 'route_map.dart';
import 'scale.dart';
import 'series_chart.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/ftp_suggestion_card.dart';
import '../../../core/widgets/heart_rate_note_card.dart';
import '../../../core/widgets/inline_error.dart';
import '../../../core/widgets/more_details.dart';
import '../../../core/widgets/page_menu.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/units.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/source_note.dart';
import '../../../core/widgets/stat_card.dart';
import '../../accounts/effort_source_text.dart';

/// The two shapes the server hands a ride's file out in.
const rideFileFormatOriginal = 'original';
const rideFileFormatFit = 'fit';

/// Whether the ride's own file is already a FIT file, so the server only has to hand it back.
bool isFitFile(String fileName) {
  final name = fileName.toLowerCase();
  return name.endsWith('.fit') || name.endsWith('.fit.gz');
}

class RideDetailScreen extends ConsumerWidget {
  const RideDetailScreen({
    super.key,
    required this.id,
    required this.layout,
    required this.onDeleted,
    required this.serverUrl,
    required this.openLink,
    this.tileUrl,
    this.attribution,
  });

  final String id;

  /// The server this session belongs to, used for the ride file's download address.
  final String serverUrl;

  /// Opens the download in the browser, which saves it.
  final LinkOpener openLink;

  /// What this rider's mode puts first. Required, so a screen showing someone else's ride is given
  /// [RiderModeLayout.full] explicitly instead of silently following the viewer's mode.
  final RiderModeLayout layout;
  final VoidCallback onDeleted;
  final String? tileUrl;
  final String? attribution;

  /// Offers the ride's file to the browser: the original as received, or a FIT file written from it.
  Future<void> _download(
    BuildContext context,
    WidgetRef ref,
    String format,
  ) async {
    final path = await ref
        .read(rideDetailViewModelProvider(id).notifier)
        .rideFileLink(format);
    if (path == null || !context.mounted) return;
    await openLink(Uri.parse('$serverUrl$path'));
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await confirmDestructive(
      context,
      title: l10n.deleteRideTitle,
      body: l10n.deleteRideBody,
      action: l10n.delete,
      key: const Key('confirm-delete'),
      cancelLabel: l10n.keepIt,
    );
    if (ok &&
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

    final ride = s.ride;
    final menu = ride == null ? null : _menu(context, ref, ride);

    return PageScaffold(
      // The title is the page's name, so a rename shows here at once.
      parent: l10n.navRides,
      title: s.ride == null ? l10n.rideDetailTitle : rideTitle(l10n, s.ride!),
      titleKey: const Key('ride-title'),
      menu: menu,
      children: _body(context, ref, s, selection),
    );
  }

  /// One menu for everything rare about a ride: its text, its type and deleting it. The numbers
  /// stay the loudest thing on the screen, and there is one place to change any of it.
  Widget _menu(BuildContext context, WidgetRef ref, RideResponse ride) {
    final l10n = context.l10n;
    final notifier = ref.read(rideDetailViewModelProvider(id).notifier);
    // The sheet or dialog opens after the menu has closed, so the two never fight for the tap.
    void later(VoidCallback open) => scheduleMicrotask(() {
      if (context.mounted) open();
    });
    return PageMenu(
      buttonKey: const Key('ride-actions'),
      entries: [
        if (ride.status == 'ready') ...[
          PageMenuEntry(
            key: const Key('edit-ride-text'),
            label: l10n.rideTextEdit,
            icon: Icons.edit_outlined,
            onSelected: () => later(
              () => showRideTextSheet(context, ride, notifier.saveDetails),
            ),
          ),
          PageMenuEntry(
            key: const Key('edit-ride-type'),
            label: rideTypeIsSet(ride)
                ? l10n.rideTypeEdit
                : l10n.rideTypeNotSet,
            icon: Icons.directions_bike_outlined,
            onSelected: () => later(
              () => showRideTypeSheet(
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
            ),
          ),
        ],
        // The files are not destructive, so they sit above the divider with the rest.
        PageMenuEntry(
          key: const Key('download-original'),
          label: l10n.rideDownloadOriginal,
          icon: Icons.download_outlined,
          onSelected: () =>
              later(() => _download(context, ref, rideFileFormatOriginal)),
        ),
        // Only a FIT file read from something else needs writing: its own is what came in.
        if (!isFitFile(ride.fileName))
          PageMenuEntry(
            key: const Key('download-fit'),
            label: l10n.rideDownloadFit,
            icon: Icons.file_download_outlined,
            onSelected: () =>
                later(() => _download(context, ref, rideFileFormatFit)),
          ),
        PageMenuEntry(
          key: const Key('delete'),
          label: l10n.delete,
          icon: Icons.delete_outline,
          destructive: true,
          onSelected: () => later(() => _confirmDelete(context, ref)),
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
    if (s.notFound) {
      return [
        EmptyState(
          key: const Key('not-found'),
          message: l10n.rideNotFound,
          icon: Icons.search_off,
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
        ErrorState(
          message: s.load.failure == null
              ? l10n.couldNotLoadRide
              : failureText(l10n, s.load.failure!),
          actionKey: const Key('ride-error'),
          onRetry: s.load.running
              ? null
              : ref.read(rideDetailViewModelProvider(id).notifier).load,
        ),
      ];
    }
    final notifier = ref.read(rideDetailViewModelProvider(id).notifier);
    // The events are read here too: this ride may be the one an event was.
    ref.watch(eventsViewModelProvider);

    final heartRateZones =
        ride.heartRateZones.orElse(null) ?? const <ZoneTime>[];
    final powerZones = ride.powerZones.orElse(null) ?? const <ZoneTime>[];

    return [
      // The page header already names the ride; the body starts with when it was.
      Text(dateTime(ride.startTime ?? ride.uploadedAt), style: text.bodyMedium),
      Text(
        [ride.fileName, if (ride.device != null) ride.device!].join(' · '),
        style: text.bodySmall,
      ),
      if (ride.description case final description?
          when description.trim().isNotEmpty)
        Text(
          description,
          key: const Key('ride-description'),
          style: text.bodyMedium,
        )
      else if (ride.status == 'ready')
        Text(
          l10n.rideTextAdd,
          key: const Key('add-ride-description'),
          style: text.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      EventLinkCard(rideId: ride.id),
      if (s.load.failure case final failure?)
        InlineError(failureText(l10n, failure), key: const Key('ride-error')),
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
        InlineError(
          rideErrorText(l10n, ride.error),
          key: const Key('ride-failed'),
        )
      else
        ..._readyBody(
          context,
          ref,
          s,
          ride,
          selection,
          notifier,
          heartRateZones,
          powerZones,
        ),
    ];
  }

  /// Everything the ride has to say, in the order it says it. Each part is tagged with whether only the
  /// training view keeps it on the page: a simple mode folds the advanced parts behind one button, training
  /// leaves them where they were.
  List<Widget> _readyBody(
    BuildContext context,
    WidgetRef ref,
    RideDetailState s,
    RideResponse ride,
    RideSelection selection,
    RideDetailViewModel notifier,
    List<ZoneTime> heartRateZones,
    List<ZoneTime> powerZones,
  ) {
    final text = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final effort = layout.effortWord ? effortWord(heartRateZones) : null;
    final items = <(Widget, bool)>[
      if (ride.ftpSuggestionW.value case final watts?)
        (
          FtpSuggestionCard(
            watts: watts,
            method: ride.ftpSuggestionMethod.value ?? '20min',
            suggestionId: ride.ftpSuggestionId.value,
            effortWatts: ride.ftpSuggestionEffortW.value,
            busy: s.action.running,
            onAccept: notifier.acceptSuggestion,
            onDismiss: notifier.dismissSuggestion,
          ),
          true,
        ),
      // One card per number this ride moved: one ride can raise the maximum and the threshold.
      for (final note in [
        ride.heartRateMaxNote.orElse(null),
        ride.heartRateThresholdNote.orElse(null),
      ])
        if (note != null)
          for (final card in _heartRateNoteCard(s, ride, note, notifier))
            (card, true),
      if (rideTypeIsSet(ride)) (RideTypeChips(ride: ride), false),
      (
        PowerRecordChips(
          records: ride.powerRecords.orElse(const []) ?? const [],
        ),
        true,
      ),
      if (s.series?.hasRoute ?? false)
        (
          RouteMap(
            data: s.series!,
            selected: selection.selected,
            selectedLap: selection.selectedLap,
            tileUrl: tileUrl,
            attribution: attribution,
            elevationGainM: ride.elevationGainM,
            virtualWorld: ride.environment == 'virtual',
            title: rideTitle(l10n, ride),
            date: _rideDate(context, ride),
            facts: _mapFacts(context, ride),
          ),
          false,
        ),
      (
        _Stats(
          ride: ride,
          show: layout.foldAdvanced ? _StatsShow.basic : _StatsShow.all,
        ),
        false,
      ),
      if (effort case final word?)
        (
          Text(
            switch (word) {
              EffortWord.easy => l10n.rideEffortEasy,
              EffortWord.steady => l10n.rideEffortSteady,
              EffortWord.hard => l10n.rideEffortHard,
            },
            key: const Key('ride-effort'),
            style: text.titleMedium,
          ),
          false,
        ),
      if (layout.foldAdvanced)
        (_Stats(ride: ride, show: _StatsShow.advanced), true),
      if (s.laps.isNotEmpty)
        (LapTable(laps: s.laps, selectedLap: selection.selectedLap), true),
      if (heartRateZones.isEmpty &&
          powerZones.isEmpty &&
          (ride.avgHeartRate != null || ride.avgPowerW != null))
        (
          Text(
            l10n.trainingHint,
            key: const Key('training-hint'),
            style: text.bodySmall,
          ),
          true,
        ),
      if (heartRateZones.isNotEmpty)
        (
          _ZonesCard(
            key: const Key('heart-rate-zones'),
            title: l10n.heartRateZones,
            unit: 'bpm',
            zones: heartRateZones,
            colors: _heartRateZoneColors,
            note: heartRateZonesSource(
              l10n,
              ride.heartRateZoneModel.orElse(null),
              ride.heartRateZoneReferenceBpm.orElse(null),
              ride.heartRateZoneReferenceSource.orElse(null),
            ),
          ),
          !layout.showZonesAndCharts,
        ),
      if (powerZones.isNotEmpty)
        (
          _ZonesCard(
            key: const Key('power-zones'),
            title: l10n.powerZones,
            unit: 'W',
            zones: powerZones,
            colors: _powerZoneColors,
          ),
          true,
        ),
      if (s.bikes.isNotEmpty || ride.bikeId != null)
        (
          _BikePicker(bikes: s.bikes, ride: ride, onChanged: notifier.setBike),
          false,
        ),
      (
        RideFeelCard(
          feel: s.feel,
          saving: s.feelCommand.running,
          onSave: notifier.saveFeel,
          onDelete: notifier.deleteFeel,
        ),
        true,
      ),
      if (s.views case final views?) (_ViewsCard(views: views), false),
      if (s.series != null && s.series!.series.isNotEmpty) ...[
        (
          ValueListenableBuilder<int?>(
            valueListenable: selection.selected,
            builder: (_, index, _) => Text(
              index == null
                  ? l10n.momentHint
                  : _moment(
                      l10n,
                      s,
                      index,
                      ref.watch(unitsChoiceViewModelProvider),
                    ),
              key: const Key('moment'),
              style: text.bodyMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          layout.rideChartIds.isEmpty,
        ),
        for (final series in s.series!.series)
          (
            SeriesChart(
              series: series,
              time: s.series!.time,
              selected: selection.selected,
              selectedLap: selection.selectedLap,
              color:
                  VelomineColors.of(context).series[series.id] ??
                  Theme.of(context).colorScheme.primary,
            ),
            !layout.rideChartIds.contains(series.id),
          ),
      ],
    ];
    if (!layout.foldAdvanced) return [for (final (widget, _) in items) widget];
    final folded = [
      for (final (widget, advanced) in items)
        if (advanced) widget,
    ];
    return [
      for (final (widget, advanced) in items)
        if (!advanced) widget,
      if (folded.isNotEmpty)
        MoreDetails(label: l10n.moreDetailsAll, children: folded),
    ];
  }

  String _moment(
    AppLocalizations l10n,
    RideDetailState s,
    int index,
    Units units,
  ) {
    final data = s.series!;
    final distance = data.distance == null ? null : data.distance![index];
    return l10n.momentAt(
      clock(data.time[index]),
      distance == null ? '' : ' · ${km(units, distance)}',
    );
  }

  /// The card for what this ride did to a heart-rate number, when it caused one: a measured value is a note,
  /// a suggestion is the question. A suggestion already answered, or a value the profile cannot yet say, is
  /// nothing.
  List<Widget> _heartRateNoteCard(
    RideDetailState s,
    RideResponse ride,
    String note,
    RideDetailViewModel notifier,
  ) {
    final isMax = note.startsWith('max');
    final kind = isMax ? 'max' : 'threshold';
    final current = isMax
        ? s.profile?.maxHeartRate
        : s.profile?.thresholdHeartRate.orElse(null);
    if (note.endsWith('suggested')) {
      final suggestion = s.heartRateSuggestions
          .where((x) => x.rideId == ride.id && x.kind == kind)
          .firstOrNull;
      if (suggestion == null) return const [];
      return [
        HeartRateNoteCard(
          kind: kind,
          bpm: suggestion.bpm,
          currentBpm: current,
          suggestionId: suggestion.id,
          zonesFromThreshold:
              ride.heartRateZoneModel.orElse(null) == 'threshold',
          busy: s.action.running,
          onAccept: notifier.acceptHeartRateSuggestion,
          onDismiss: notifier.dismissHeartRateSuggestion,
        ),
      ];
    }
    // The profile carries the number in use and the ride that measured it: the card is this ride's only while the
    // number still came from it, never after another ride or the rider changed it.
    final measuredOn = isMax
        ? s.profile?.maxHeartRateRideId.orElse(null)
        : s.profile?.thresholdHeartRateRideId.orElse(null);
    if (current == null || measuredOn != ride.id) return const [];
    return [
      HeartRateNoteCard(
        kind: kind,
        bpm: current,
        zonesFromThreshold: ride.heartRateZoneModel.orElse(null) == 'threshold',
      ),
    ];
  }
}

/// The drift in words: below 5 % the heart rate held, 5 to 10 % it moved a little, above 10 % it moved a lot.
String decouplingWord(AppLocalizations l10n, double pct) => pct < 5
    ? l10n.decouplingSteady
    : pct <= 10
    ? l10n.decouplingDrift
    : l10n.decouplingLargeDrift;

/// Who else has looked at this ride, most recent first. Only the owner ever sees this.
class _ViewsCard extends StatelessWidget {
  const _ViewsCard({required this.views});

  final List<ShareViewResponse> views;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SectionCard(
      key: const Key('ride-views'),
      title: l10n.viewsTitle,
      children: [
        if (views.isEmpty)
          Text(
            l10n.rideViewsEmpty,
            key: const Key('ride-views-empty'),
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          for (final view in views)
            Text(
              l10n.rideViewedBy(view.viewerName, weekdayTime(view.at)),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
      ],
    );
  }
}

/// The ride's numbers as small tiles: only the ones the ride has, and only the ones this view shows.
///
/// The basic tiles answer "how was the ride" (how far, how long, how hard the heart worked); everything else
/// is training analysis and a simple mode folds it away.
class _Stats extends ConsumerWidget {
  const _Stats({required this.ride, required this.show});

  final RideResponse ride;
  final _StatsShow show;

  /// The tiles a simple rider keeps, by the id the tile is tagged with.
  static const _basic = {
    'distance',
    'moving-time',
    'elapsed-time',
    'climbing',
    'average-speed',
    'average-heart-rate',
    'max-heart-rate',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final units = ref.watch(unitsChoiceViewModelProvider);
    final tiles = <(String, String, String)>[
      ('distance', l10n.statDistance, km(units, ride.distanceM)),
      ('moving-time', l10n.statMovingTime, duration(ride.movingS)),
      if (ride.elapsedS != null &&
          ride.movingS != null &&
          ride.elapsedS! - ride.movingS! > 60)
        ('elapsed-time', l10n.statElapsedTime, duration(ride.elapsedS)),
      if (ride.elevationGainM != null)
        ('climbing', l10n.statClimbing, elevation(units, ride.elevationGainM)),
      if (ride.elevationLossM != null)
        (
          'descending',
          l10n.statDescending,
          elevation(units, ride.elevationLossM),
        ),
      ('average-speed', l10n.statAverageSpeed, kmh(units, ride.avgSpeedMs)),
      if (ride.maxSpeedMs != null)
        ('top-speed', l10n.statTopSpeed, kmh(units, ride.maxSpeedMs)),
      if (ride.avgPowerW != null)
        ('average-power', l10n.statAveragePower, '${ride.avgPowerW} W'),
      if (ride.estimatedAvgPowerW.value case final estimate?)
        (
          'estimated-average-power',
          l10n.statEstimatedAveragePower,
          '$estimate W',
        ),
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
      // The effort score the dashboard uses for this ride, and where it came from.
      if (ride.effortScore.value case final score?)
        ('effort-score', l10n.statEffortScore, score.round().toString()),
      if (ride.efficiencyFactor.value case final efficiency?)
        ('efficiency', l10n.statEfficiency, efficiency.toStringAsFixed(2)),
      if (ride.decouplingPct.value case final decoupling?
          when ride.steady.value == true)
        (
          'decoupling',
          l10n.statDecoupling,
          '${decoupling.toStringAsFixed(1)} %',
        ),
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
    final basic = show == _StatsShow.all || show == _StatsShow.basic;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: 12,
      children: [
        for (final (id, label, value) in tiles)
          if (show == _StatsShow.all ||
              (show == _StatsShow.basic) == _basic.contains(id))
            StatFigure(key: Key('stat-$id'), label: label, value: value),
        if (basic && ride.speedSource == 'gps')
          Text(l10n.speedFromGps, style: text.bodySmall),
        if (show != _StatsShow.basic) ...[
          if (ride.minWPrimeBalanceJ.value case final low?)
            Text(
              l10n.wPrimeLowest(
                (low / 1000).toStringAsFixed(1),
                ((ride.wPrimeJ.value ?? 0) / 1000).toStringAsFixed(1),
              ),
              key: const Key('wprime-lowest'),
              style: text.bodySmall,
            ),
          if (ride.tss != null || ride.trimp != null)
            Text(l10n.loadHint, style: text.bodySmall),
          if (ride.effortScore.value != null)
            if (effortSourceText(l10n, ride.effortSource.orElse(null))
                case final note?)
              SourceNote(note, key: const Key('effort-source')),
          if (ride.estimatedAvgPowerW.value != null)
            SourceNote(
              l10n.estimatedPowerSource,
              key: const Key('estimated-power-source'),
            ),
          if (ride.efficiencyFactor.value != null) ...[
            if (ride.decouplingPct.value case final decoupling?
                when ride.steady.value == true)
              Text(
                l10n.decoupling(
                  decoupling.toStringAsFixed(1),
                  decouplingWord(l10n, decoupling),
                ),
                key: const Key('decoupling'),
                style: text.bodyMedium,
              ),
            SourceNote(l10n.decouplingSource),
          ],
        ],
      ],
    );
  }
}

/// Which of the ride's tiles this view draws.
enum _StatsShow { all, basic, advanced }

/// Time in each training zone, as a bar per zone.
class _ZonesCard extends StatelessWidget {
  const _ZonesCard({
    super.key,
    required this.title,
    required this.unit,
    required this.zones,
    required this.colors,
    this.note,
  });

  final String title;
  final String unit;
  final List<ZoneTime> zones;
  final List<Color> colors;

  /// Where the zones came from, when the server says.
  final String? note;

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
                Expanded(child: Text(title, style: text.titleMedium)),
                const SizedBox(width: AppSpacing.sm),
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
                        borderRadius: BorderRadius.circular(AppSpacing.xs),
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
              if (index < zones.length - 1)
                const SizedBox(height: AppSpacing.xs),
            ],
            if (note case final note?) ...[
              const SizedBox(height: AppSpacing.sm),
              SourceNote(note),
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

/// The event this ride was, when one is linked to it.
class EventLinkCard extends ConsumerWidget {
  const EventLinkCard({super.key, required this.rideId});

  final String rideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final events = ref.watch(eventsViewModelProvider);
    final event = events.events.where((e) => e.rideId == rideId).firstOrNull;
    if (event == null) return const SizedBox.shrink();
    return SectionCard(
      key: const Key('ride-event'),
      title: l10n.eventYourRide(event.name),
      description: eventDetail(
        l10n,
        ref.watch(unitsChoiceViewModelProvider),
        event,
      ),
      children: [
        if (event.notes case final notes? when notes.isNotEmpty)
          Text(notes, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

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

/// The ride's date as the map card says it: the day and the start time in the member's clock.
String _rideDate(BuildContext context, RideResponse ride) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final uploaded = ride.uploadedAt.toLocal();
  final start = ride.startTime?.toLocal() ?? uploaded;
  return '${DateFormat.yMMMEd(locale).format(start)} · '
      '${DateFormat.Hm(locale).format(start)}';
}

/// The facts the map card has room for: distance, moving time and climbing, when the ride has them.
List<({String label, String value})> _mapFacts(
  BuildContext context,
  RideResponse ride,
) {
  final l10n = context.l10n;
  final units = ProviderScope.containerOf(context)
      .read(unitsChoiceViewModelProvider);
  return [
    if (ride.distanceM != null && ride.distanceM! > 0)
      (label: l10n.statDistance, value: km(units, ride.distanceM)),
    if (ride.movingS != null && ride.movingS! > 0)
      (label: l10n.statMovingTime, value: duration(ride.movingS)),
    if (ride.elevationGainM != null && ride.elevationGainM! > 0)
      (label: l10n.statClimbing, value: elevation(units, ride.elevationGainM)),
  ];
}
