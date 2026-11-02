import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
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
          label: const Text('Add bike'),
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
                      'Bikes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (c.error != null)
                      Text(
                        c.error!,
                        key: const Key('bikes-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    if (c.loading && c.bikes.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else if (c.bikes.isEmpty && c.error == null)
                      const Text(
                        'No bikes yet. Add one to keep track of its distance and the wear on its parts. New rides are given your default bike.',
                        key: Key('no-bikes'),
                      ),
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
            if (bike.isDefault) const Chip(label: Text('Default')),
            if (!bike.isActive) const Chip(label: Text('Archived')),
          ],
        ),
        subtitle: Text(
          [
            bikeKinds[bike.kind] ?? bike.kind,
            if (make.isNotEmpty) make,
            '${km(bike.distanceM)} · ${bike.rideCount} rides · ${duration(bike.movingS)}',
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
