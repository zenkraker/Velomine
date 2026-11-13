import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/placeholder_block.dart';
import '../../core/l10n.dart';
import '../../core/page_actions.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/card_grid.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/stat_tile.dart';
import '../../core/widgets/toolbar_row.dart';
import '../../l10n/generated/app_localizations.dart';
import 'bulk/bulk_upload_card.dart';
import 'bulk/bulk_upload_view_model.dart';
import 'ride_filters.dart';
import 'ride_title.dart';
import 'ride_type_chips.dart';
import 'rides_view_model.dart';
import '../../core/tokens.dart';
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

  /// A phone's title bar: one filter button and the ways to add rides behind a menu, instead of a row
  /// of buttons over the list.
  void _phoneAppBar(
    BuildContext context,
    List<(Key, IconData, String?, VoidCallback?)> imports,
    bool filterActive,
  ) {
    final l10n = context.l10n;
    final actions = <Widget>[
      phoneFilterButton(
        key: const Key('rides-filter'),
        tooltip: l10n.rideFilterTitle,
        active: filterActive,
        onPressed: () =>
            showFiltersSheet(context, (_) => const _RidesFilterSheet()),
      ),
      if (imports.isNotEmpty)
        PopupMenuButton<VoidCallback?>(
          key: const Key('rides-actions'),
          tooltip: l10n.ridesImportMenu,
          icon: const Icon(Icons.more_vert),
          onSelected: (action) => action?.call(),
          itemBuilder: (_) => [
            for (final (key, icon, label, onPressed) in imports)
              if (label != null)
                PopupMenuItem(
                  key: key,
                  value: onPressed,
                  enabled: onPressed != null,
                  child: ListTile(
                    leading: Icon(icon),
                    title: Text(label),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
          ],
        ),
    ];
    // The title bar belongs to the shell, so the page hands its buttons over after the frame.
    final where = GoRouterState.of(context).uri.path;
    // The element, not just the context: a tab that is being removed is still "mounted" in its
    // final frame and must not put its buttons back over the screen replacing it.
    final element = context as Element;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!element.mounted) return;
      Future.microtask(
        () => ref.read(pageActionsProvider.notifier).set(where, actions),
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
    final action = FilledButton.icon(
      key: const Key('upload'),
      onPressed: upload,
      icon: const Icon(Icons.upload_file),
      label: Text(s.upload.running ? l10n.uploading : l10n.uploadRide),
    );
    // Getting data in, for a phone's title bar and its empty screen: the three ways other than upload.
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

    // A wide window keeps the controls on the page; a phone puts them in the title bar and the list.
    if (!wide) _phoneAppBar(context, imports, filterActive);

    final wideActions = ToolbarRow(
      alignment: WrapAlignment.end,
      children: [
        action,
        for (final (key, icon, label, onPressed) in imports)
          if (label != null)
            OutlinedButton.icon(
              key: key,
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
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
        action,
        for (final (key, icon, label, onPressed) in imports)
          if (label != null)
            OutlinedButton.icon(
              key: key,
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
      controller: notifier.scroll,
      refresh: notifier.refresh,
      // A phone's upload button floats over the list; the last card ends above it.
      bottomPadding: wide ? AppSpacing.xl : 96,
      children: [
        if (wide) ...[wideActions, const BulkUploadCard()],
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
              // Wide has the button in its header already.
              action: wide ? null : emptyActions,
            ),
        CardGrid(
          children: [
            for (final ride in s.rides)
              RideCard(ride: ride, onTap: () => onOpen(ride.id)),
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
    );
    if (wide) return page;
    // The list ends above the button, so the last card is never under it.
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('upload'),
        onPressed: upload,
        icon: const Icon(Icons.upload_file),
        label: Text(s.upload.running ? l10n.uploading : l10n.uploadRide),
      ),
      body: page,
    );
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.lg,
        children: [
          Text(
            l10n.rideFilterTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
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
      ),
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
  const RideCard({super.key, required this.ride, this.onTap});

  final RideResponse ride;
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
    // ride does not have is left out, not shown as zero.
    final facts = <(String, String)>[
      if (ready) ...[
        if ((ride.distanceM ?? 0) > 0)
          (l10n.statDistance, km(units, ride.distanceM)),
        if ((ride.movingS ?? 0) > 0)
          (l10n.statMovingTime, duration(ride.movingS)),
        if ((ride.elevationGainM ?? 0) > 0)
          (l10n.statClimbing, elevation(units, ride.elevationGainM)),
        if ((ride.avgSpeedMs ?? 0) > 0)
          (l10n.statAverageSpeed, kmh(units, ride.avgSpeedMs)),
        if ((ride.avgPowerW ?? 0) > 0)
          (
            l10n.statAveragePower,
            '${ride.avgPowerW} W${ride.normalizedPowerW == null ? '' : ' (NP ${ride.normalizedPowerW})'}',
          ),
        if ((ride.avgHeartRate ?? 0) > 0)
          (l10n.statAverageHeartRate, '${ride.avgHeartRate} bpm'),
        if ((ride.avgCadence ?? 0) > 0)
          (l10n.statAverageCadence, '${ride.avgCadence} rpm'),
      ],
    ];
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
                Text(
                  rideErrorText(l10n, ride.error),
                  key: const Key('ride-failed'),
                  style: TextStyle(color: scheme.error),
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
                        for (final (label, value) in facts)
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
