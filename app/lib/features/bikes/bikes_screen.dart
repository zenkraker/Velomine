import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/units.dart';
import '../../core/theme.dart';
import '../../core/user_message_text.dart';
import 'bike_forms.dart';
import 'bikes_view_models.dart';
import '../../core/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/stat_tile.dart';
import '../../core/widgets/card_grid.dart';

class BikesScreen extends ConsumerWidget {
  const BikesScreen({super.key, required this.onOpen});

  final void Function(String id) onOpen;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final data = await showBikeForm(context);
    if (data == null || !context.mounted) return;
    final id = await ref
        .read(bikesViewModelProvider.notifier)
        .add(data.toCreate());
    if (id != null && context.mounted) onOpen(id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(bikesViewModelProvider);
    final l10n = context.l10n;
    final notifier = ref.read(bikesViewModelProvider.notifier);
    final add = FilledButton.icon(
      key: const Key('add-bike'),
      onPressed: s.action.running ? null : () => _add(context, ref),
      icon: const Icon(Icons.add),
      label: Text(l10n.addBike),
    );

    listenUserMessages(
      ref,
      context,
      bikesViewModelProvider.select((s) => s.messages),
      notifier.messageShown,
    );

    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoint.compactWidth;
    return Scaffold(
      backgroundColor: Colors.transparent,
      // A single action: on the floating button on a phone, in the page header from a tablet up.
      floatingActionButton: wide ? null : add,
      body: PageScaffold(
        eyebrow: l10n.eyebrowBikes,
        title: l10n.navBikes,
        subtitle: l10n.bikesSubtitle,
        actions: wide ? add : null,
        children: [
          if (s.load.failure case final failure?)
            ErrorState(
              message: failureText(l10n, failure),
              actionKey: const Key('bikes-error'),
              onRetry: s.load.running ? null : notifier.refresh,
            ),
          if (s.load.running && s.bikes.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (s.bikes.isEmpty && s.load.failure == null)
            EmptyState(
              key: const Key('no-bikes'),
              message: l10n.noBikes,
              icon: Icons.pedal_bike,
              // A different key: the page's own add button may be in the tree already.
              action: FilledButton.icon(
                key: const Key('no-bikes-add'),
                onPressed: s.action.running ? null : () => _add(context, ref),
                icon: const Icon(Icons.add),
                label: Text(l10n.addBike),
              ),
            ),
          CardGrid(
            columns: 3,
            children: [
              for (final bike in s.bikes) _BikeCard(bike: bike, onOpen: onOpen),
            ],
          ),
        ],
      ),
    );
  }
}

/// One bike as a card: what it is, how far it has gone, and what needs doing.
class _BikeCard extends ConsumerWidget {
  const _BikeCard({required this.bike, required this.onOpen});

  final BikeResponse bike;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final units = ref.watch(unitsChoiceViewModelProvider);
    final make = [bike.brand, bike.model].whereType<String>().join(' ');
    final facts = <(String, String)>[
      (l10n.statDistance, km(units, bike.distanceM)),
      (l10n.statRides, bike.rideCount.toString()),
      (l10n.statMovingTime, duration(bike.movingS)),
    ];
    return Card(
      key: Key('bike-${bike.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onOpen(bike.id),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.sm,
            children: [
              Row(
                spacing: AppSpacing.sm,
                children: [
                  Icon(
                    Icons.directions_bike,
                    color: bike.isActive ? scheme.primary : scheme.outline,
                  ),
                  Expanded(
                    child: Text(
                      bike.name,
                      style: text.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (bike.serviceDueCount > 0 || bike.serviceSoonCount > 0)
                    _ServiceMarker(due: bike.serviceDueCount > 0),
                ],
              ),
              Text(
                [
                  bikeKindName(l10n, bike.kind),
                  if (make.isNotEmpty) make,
                ].join(' · '),
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (bike.isDefault || !bike.isActive)
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (bike.isDefault)
                      Chip(
                        label: Text(l10n.defaultBike),
                        backgroundColor: scheme.primaryContainer,
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (!bike.isActive)
                      Chip(
                        label: Text(l10n.archived),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xl,
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

/// A small flag on a bike that has a job due (red) or nearly due.
class _ServiceMarker extends StatelessWidget {
  const _ServiceMarker({required this.due});

  final bool due;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = due
        ? Theme.of(context).colorScheme.error
        : VelomineColors.of(context).wearSoon;
    final label = due ? l10n.bikeServiceDue : l10n.bikeServiceSoon;
    return Semantics(
      label: label,
      child: Tooltip(
        message: label,
        child: Icon(
          Icons.build_circle_outlined,
          key: Key(due ? 'service-due' : 'service-soon'),
          color: color,
          size: 22,
        ),
      ),
    );
  }
}
