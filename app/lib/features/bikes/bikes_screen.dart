import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/user_message_text.dart';
import 'bike_forms.dart';
import 'bikes_view_models.dart';
import '../../core/tokens.dart';
import '../../core/widgets/empty_state.dart';

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

    listenUserMessages(
      ref,
      context,
      bikesViewModelProvider.select((s) => s.messages),
      ref.read(bikesViewModelProvider.notifier).messageShown,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-bike'),
        onPressed: s.action.running ? null : () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.addBike),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.md,
                children: [
                  if (s.load.failure case final failure?)
                    Text(
                      failureText(l10n, failure),
                      key: const Key('bikes-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (s.load.running && s.bikes.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (s.bikes.isEmpty && s.load.failure == null)
                    EmptyState(
                      key: const Key('no-bikes'),
                      message: l10n.noBikes,
                      icon: Icons.pedal_bike,
                    ),
                  for (final bike in s.bikes)
                    _BikeCard(bike: bike, onOpen: onOpen),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BikeCard extends StatelessWidget {
  const _BikeCard({required this.bike, required this.onOpen});

  final BikeResponse bike;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final make = [bike.brand, bike.model].whereType<String>().join(' ');
    return Card(
      key: Key('bike-${bike.id}'),
      child: ListTile(
        onTap: () => onOpen(bike.id),
        leading: Icon(
          Icons.directions_bike,
          color: bike.isActive ? null : Theme.of(context).disabledColor,
        ),
        title: Row(
          spacing: AppSpacing.sm,
          children: [
            Flexible(child: Text(bike.name, style: text.titleMedium)),
            if (bike.isDefault) Chip(label: Text(l10n.defaultBike)),
            if (!bike.isActive) Chip(label: Text(l10n.archived)),
            if (bike.serviceDueCount > 0 || bike.serviceSoonCount > 0)
              _ServiceMarker(due: bike.serviceDueCount > 0),
          ],
        ),
        subtitle: Text(
          [
            bikeKindName(l10n, bike.kind),
            if (make.isNotEmpty) make,
            '${km(bike.distanceM)} · ${l10n.bikeRides(bike.rideCount)} · ${duration(bike.movingS)}',
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
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
