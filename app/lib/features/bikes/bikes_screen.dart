import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/user_message_text.dart';
import 'bike_forms.dart';
import 'bikes_view_models.dart';

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

    ref.listen(bikesViewModelProvider.select((state) => state.messages), (
      _,
      messages,
    ) {
      for (final message in messages) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userMessageText(l10n, message))));
        ref.read(bikesViewModelProvider.notifier).messageShown(message.id);
      }
    });

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
                spacing: 12,
                children: [
                  Text(
                    l10n.navBikes,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
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
                    Text(l10n.noBikes, key: const Key('no-bikes')),
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
          spacing: 8,
          children: [
            Flexible(child: Text(bike.name, style: text.titleMedium)),
            if (bike.isDefault) Chip(label: Text(l10n.defaultBike)),
            if (!bike.isActive) Chip(label: Text(l10n.archived)),
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
