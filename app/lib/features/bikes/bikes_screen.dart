import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import 'bike_forms.dart';
import 'bikes_controller.dart';

class BikesScreen extends StatefulWidget {
  const BikesScreen({
    super.key,
    required this.controller,
    required this.onOpen,
  });

  final BikesController controller;
  final void Function(String id) onOpen;

  @override
  State<BikesScreen> createState() => _BikesScreenState();
}

class _BikesScreenState extends State<BikesScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.refresh();
  }

  Future<void> _add() async {
    final data = await showBikeForm(context);
    if (data == null) return;
    final id = await widget.controller.add(data.toCreate());
    if (id != null && mounted) widget.onOpen(id);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('add-bike'),
          onPressed: _add,
          icon: const Icon(Icons.add),
          label: Text(context.l10n.addBike),
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
                      context.l10n.navBikes,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (c.error != null)
                      Text(
                        failureText(context.l10n, c.error!),
                        key: const Key('bikes-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    if (c.loading && c.bikes.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else if (c.bikes.isEmpty && c.error == null)
                      Text(context.l10n.noBikes, key: const Key('no-bikes')),
                    for (final bike in c.bikes)
                      _BikeCard(bike: bike, onOpen: widget.onOpen),
                  ],
                ),
              ),
            ),
          ],
        ),
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
