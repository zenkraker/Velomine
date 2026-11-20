import '../../core/widgets/loading_state.dart';
import '../../core/widgets/inline_error.dart';

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../recording/recording_providers.dart';
import '../../core/l10n.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/card_grid.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/stat_tile.dart';
import '../../core/widgets/toolbar_row.dart';
import '../../l10n/generated/app_localizations.dart';
import 'bulk/bulk_upload_card.dart';
import 'bulk/bulk_upload_view_model.dart';
import 'ride_filters.dart';
import 'ride_title.dart';
import 'ride_type_chips.dart';
import 'rides_view_model.dart';
import '../../core/rider_mode.dart';
import '../../core/tokens.dart';
import '../../core/widgets/form_sheet.dart';
import '../../core/units.dart';
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
    required this.onOpenImport,
    this.showSoloCard = false,
    this.onOpenClubs,
    this.onDismissSoloCard,
  });

  /// Called with a ride's id when its card is pressed.
  final void Function(String id) onOpen;

  /// Called with an import's id once the archive has been sent.
  final void Function(String id) onOpenImport;

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
    final layout = ref.watch(riderLayoutProvider);
    final l10n = context.l10n;
    final notifier = ref.read(ridesViewModelProvider.notifier);

    listenUserMessages(
      ref,
      context,
      ridesViewModelProvider.select((s) => s.messages),
      notifier.messageShown,
    );

    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoint.compactWidth;
    final upload = s.upload.running
        ? null
        : () => ref.read(ridesViewModelProvider.notifier).upload();
    final startImport = s.import.running
        ? null
        : () async {
            final id = await notifier.startImport();
            if (id != null && context.mounted) widget.onOpenImport(id);
          };
    final bulk = ref.read(bulkUploadViewModelProvider.notifier);
    final bulkSupported = ref.watch(dropSourceProvider).supported;
    final bulkBusy = ref.watch(
      bulkUploadViewModelProvider.select((s) => s.busy),
    );
    final uploadLabel = s.upload.running ? l10n.uploading : l10n.uploadRide;
    // Getting data in, for the menu and the empty screen: the ways other than upload.
    final imports = <(Key, IconData, String?, VoidCallback?)>[
      (
        const Key('import-strava'),
        Icons.cloud_download_outlined,
        s.import.running ? l10n.importStarting : l10n.importFromStrava,
        startImport,
      ),
      if (bulkSupported) ...[
        (
          const Key('bulk-folder'),
          Icons.folder_open_outlined,
          l10n.bulkChooseFolder,
          bulkBusy ? null : bulk.chooseFolder,
        ),
        (
          const Key('bulk-files'),
          Icons.file_open_outlined,
          l10n.bulkChooseFiles,
          bulkBusy ? null : bulk.chooseFiles,
        ),
      ],
    ];
    final filterActive =
        s.query.isNotEmpty || s.dateRange != null || s.disciplineFilter != null;
    void chooseDiscipline(String? value) => notifier.setDisciplineFilter(value);

    final disciplineChips = <Widget>[
      ChoiceChip(
        key: const Key('filter-all'),
        label: Text(l10n.rideFilterAll),
        selected: s.disciplineFilter == null,
        onSelected: (_) => chooseDiscipline(null),
      ),
      for (final discipline in ['road', 'gravel', 'mountain', 'track'])
        ChoiceChip(
          key: Key('filter-$discipline'),
          label: Text(disciplineName(l10n, discipline)),
          selected: s.disciplineFilter == discipline,
          onSelected: (_) => chooseDiscipline(discipline),
        ),
    ];

    // The phone with a recorder starts rides from the header; everywhere else the header uploads, and
    // on the phone Upload then waits in the menu.
    final hasRecorder = ref.watch(recorderProvider) != null;
    final startRidePrimary = hasRecorder && !wide;
    // On a phone the header also holds the notifications and the account, and the labelled button
    // overflows it at 360 dp, so it is a filled icon there (its tooltip names it).
    Widget headerButton(
      Key key,
      IconData icon,
      String label,
      VoidCallback? onPressed,
    ) => wide
        ? FilledButton.icon(
            key: key,
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          )
        : IconButton.filled(
            key: key,
            tooltip: label,
            onPressed: onPressed,
            icon: Icon(icon),
          );
    final primaryAction = startRidePrimary
        ? headerButton(
            const Key('start-ride'),
            Icons.play_arrow,
            l10n.startRide,
            () => context.push('/record'),
          )
        : headerButton(
            const Key('upload'),
            Icons.upload_file,
            uploadLabel,
            upload,
          );
    final menu = PageMenu(
      buttonKey: const Key('rides-actions'),
      badge: filterActive,
      entries: [
        if (startRidePrimary)
          PageMenuEntry(
            key: const Key('upload'),
            icon: Icons.upload_file,
            label: uploadLabel,
            onSelected: upload ?? () {},
          ),
        // A tablet with a recorder uploads from the header; starting a ride stays one tap away.
        if (hasRecorder && wide)
          PageMenuEntry(
            key: const Key('start-ride'),
            icon: Icons.play_arrow,
            label: l10n.startRide,
            onSelected: () => context.push('/record'),
          ),
        for (final (key, icon, label, onPressed) in imports)
          if (label != null)
            PageMenuEntry(
              key: key,
              icon: icon,
              label: label,
              onSelected: onPressed ?? () {},
            ),
        if (!wide)
          PageMenuEntry(
            key: const Key('rides-filter'),
            icon: Icons.filter_list,
            label: l10n.rideFilterTitle,
            onSelected: () =>
                showFiltersSheet(context, (_) => const _RidesFilterSheet()),
          ),
      ],
    );

    final wideFilters = ToolbarRow(
      children: [
        RideFilters(
          query: s.query,
          dateRange: s.dateRange,
          onQuery: notifier.setQuery,
          onDateRange: notifier.setDateRange,
        ),
        ...disciplineChips,
      ],
    );
    // The ways to add rides, inline where a rider has none: getting data in is the whole job there.
    final emptyActions = Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        FilledButton.icon(
          key: const Key('empty-upload'),
          onPressed: upload,
          icon: const Icon(Icons.upload_file),
          label: Text(uploadLabel),
        ),
        for (final (key, icon, label, onPressed) in imports)
          if (label != null)
            OutlinedButton.icon(
              key: Key('empty-${(key as ValueKey<String>).value}'),
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
            ),
      ],
    );

    final page = PageScaffold(
      eyebrow: l10n.eyebrowRides,
      title: l10n.navRides,
      subtitle: l10n.ridesSubtitle,
      primaryAction: primaryAction,
      menu: menu,
      controller: notifier.scroll,
      refresh: notifier.refresh,
      children: [
        if (wide) const BulkUploadCard(),
        if (s.load.failure case final failure?)
          ErrorState(
            message: failureText(l10n, failure),
            actionKey: const Key('rides-error'),
            onRetry: s.load.running ? null : notifier.refresh,
          ),
        if (showSoloCard && onOpenClubs != null)
          _SoloBanner(onSee: onOpenClubs!, onDismiss: onDismissSoloCard),
        if (wide) wideFilters,
        if (s.rides.isEmpty && !s.load.running)
          if (s.filtered)
            Column(
              key: const Key('no-rides-match'),
              children: [
                EmptyState(
                  icon: Icons.search_off,
                  message: l10n.noRidesMatch,
                  action: TextButton(
                    key: const Key('clear-filters'),
                    onPressed: notifier.clearFilters,
                    child: Text(l10n.rideFilterClear),
                  ),
                ),
              ],
            )
          else
            EmptyState(
              key: const Key('no-rides'),
              message: l10n.noRides,
              icon: Icons.directions_bike,
              // Wide has the ways in on its page already.
              action: wide ? null : emptyActions,
            ),
        if (s.rides.isEmpty && !s.load.running && !s.filtered && bulkSupported)
          SectionCard(
            title: l10n.zwiftTitle,
            description: l10n.zwiftHint,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    key: const Key('zwift-folder'),
                    onPressed: bulkBusy ? null : bulk.chooseFolder,
                    icon: const Icon(Icons.folder_open_outlined),
                    label: Text(l10n.bulkChooseFolder),
                  ),
                  TextButton(
                    key: const Key('zwift-files'),
                    onPressed: bulkBusy ? null : bulk.chooseFiles,
                    child: Text(l10n.bulkChooseFiles),
                  ),
                ],
              ),
            ],
          ),
        CardGrid(
          children: [
            for (final ride in s.rides)
              RideCard(
                ride: ride,
                layout: layout,
                onTap: () => onOpen(ride.id),
              ),
          ],
        ),
        if (s.next != null)
          Center(
            child: TextButton(
              key: const Key('load-more'),
              onPressed: s.load.running ? null : notifier.loadMore,
              child: Text(l10n.loadMore),
            ),
          ),
        if (s.waiting)
          const LoadingState.rows(
            key: Key('rides-loading'),
            count: 5,
            rowHeight: AppLoading.cardRowHeight,
          )
        else if (s.load.running)
          const LoadingState(),
      ],
    );
    return page;
  }
}

/// A phone's filters in one sheet: the search, the dates and the discipline, all applied as they are
/// chosen, so the list behind the sheet has already changed when it closes.
class _RidesFilterSheet extends ConsumerWidget {
  const _RidesFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(ridesViewModelProvider);
    final notifier = ref.read(ridesViewModelProvider.notifier);
    final l10n = context.l10n;
    Widget discipline(String key, String label, String? value, bool selected) =>
        ChoiceChip(
          key: Key(key),
          label: Text(label),
          selected: selected,
          onSelected: (_) => notifier.setDisciplineFilter(value),
        );
    return SheetFrame(
      title: l10n.rideFilterTitle,
      children: [
        RideFilters(
          query: s.query,
          dateRange: s.dateRange,
          onQuery: notifier.setQuery,
          onDateRange: notifier.setDateRange,
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            discipline(
              'filter-all',
              l10n.rideFilterAll,
              null,
              s.disciplineFilter == null,
            ),
            for (final name in ['road', 'gravel', 'mountain', 'track'])
              discipline(
                'filter-$name',
                disciplineName(l10n, name),
                name,
                s.disciplineFilter == name,
              ),
          ],
        ),
      ],
    );
  }
}

/// A quiet line at the top of the list for a rider without a club, not a card competing with the rides.
class _SoloBanner extends StatelessWidget {
  const _SoloBanner({required this.onSee, this.onDismiss});

  final VoidCallback onSee;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      key: const Key('solo-club-card'),
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          0,
          AppSpacing.xs,
        ),
        child: Row(
          spacing: AppSpacing.sm,
          children: [
            Icon(
              Icons.explore_outlined,
              color: scheme.onSurfaceVariant,
              size: 20,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.soloHintTitle, style: text.titleSmall),
                  Text(
                    l10n.soloHintBody,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              key: const Key('open-nearby-from-rides'),
              onPressed: onSee,
              child: Text(l10n.soloHintSee),
            ),
            IconButton(
              key: const Key('dismiss-solo-card'),
              tooltip: l10n.soloHintDismiss,
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class RideCard extends ConsumerWidget {
  const RideCard({
    super.key,
    required this.ride,
    required this.layout,
    this.onTap,
  });

  final RideResponse ride;

  /// What this rider's mode puts on a card. Required, so a card showing someone else's ride is given
  /// [RiderModeLayout.full] explicitly instead of silently following the viewer's mode.
  final RiderModeLayout layout;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitsChoiceViewModelProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final ready = ride.status == 'ready';
    // A file with no samples parses but says nothing: it reads as empty, not as a ride of zeros.
    final empty =
        ready && (ride.distanceM ?? 0) <= 0 && (ride.movingS ?? 0) <= 0;
    // Each number carries its name: a row of unlabelled values is a puzzle on a phone. A number the
    // ride does not have is left out, not shown as zero, and the mode decides which ones the card lists.
    final facts = <(String, String, String)>[
      if (ready) ...[
        if ((ride.distanceM ?? 0) > 0)
          ('distance', l10n.statDistance, km(units, ride.distanceM)),
        if ((ride.movingS ?? 0) > 0)
          ('moving-time', l10n.statMovingTime, duration(ride.movingS)),
        if ((ride.elevationGainM ?? 0) > 0)
          (
            'climbing',
            l10n.statClimbing,
            elevation(units, ride.elevationGainM),
          ),
        if ((ride.avgSpeedMs ?? 0) > 0)
          ('average-speed', l10n.statAverageSpeed, kmh(units, ride.avgSpeedMs)),
        if ((ride.avgPowerW ?? 0) > 0)
          (
            'average-power',
            l10n.statAveragePower,
            '${ride.avgPowerW} W${ride.normalizedPowerW == null ? '' : ' (NP ${ride.normalizedPowerW})'}',
          ),
        if ((ride.avgHeartRate ?? 0) > 0)
          (
            'average-heart-rate',
            l10n.statAverageHeartRate,
            '${ride.avgHeartRate} bpm',
          ),
        if ((ride.avgCadence ?? 0) > 0)
          (
            'average-cadence',
            l10n.statAverageCadence,
            '${ride.avgCadence} rpm',
          ),
      ],
    ].where((fact) => layout.rideListFacts.contains(fact.$1)).toList();
    return Card(
      key: Key('ride-${ride.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              Text(
                rideTitle(l10n, ride),
                key: const Key('ride-title'),
                style: text.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                dateTime(ride.startTime ?? ride.uploadedAt),
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (ready && rideTypeIsSet(ride))
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: RideTypeChips(ride: ride),
                ),
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
                InlineError(
                  rideErrorText(l10n, ride.error),
                  key: const Key('ride-failed'),
                )
              else if (empty || facts.isEmpty)
                Text(
                  l10n.rideNoData,
                  key: const Key('ride-no-data'),
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    // A few columns of numbers under the title, so the card reads as a table.
                    const gap = AppSpacing.md;
                    const columns = 3;
                    final width =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final (_, label, value) in facts)
                          SizedBox(
                            width: math.max(width, 62),
                            child: StatTile(label: label, value: value),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
