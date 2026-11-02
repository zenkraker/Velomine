import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import 'bike_forms.dart';
import 'bikes_controller.dart';

class BikeDetailScreen extends StatefulWidget {
  const BikeDetailScreen({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onDeleted,
  });

  final BikeDetailController controller;
  final VoidCallback onBack;
  final VoidCallback onDeleted;

  @override
  State<BikeDetailScreen> createState() => _BikeDetailScreenState();
}

class _BikeDetailScreenState extends State<BikeDetailScreen> {
  BikeDetailController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.load();
  }

  Future<void> _edit() async {
    final bike = c.detail!.bike;
    final data = await showBikeForm(context, bike: bike);
    if (data != null) await c.save(data.toUpdate(isActive: bike.isActive));
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this bike?'),
        content: const Text(
          'The bike and its parts are removed. Your rides stay, but they will no longer say which bike you rode. To keep the history, archive the bike instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            key: const Key('confirm-delete-bike'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && await c.delete()) widget.onDeleted();
  }

  Future<void> _addPart() async {
    final data = await showPartForm(context, types: c.types, today: c.today);
    if (data != null) await c.addPart(data.toCreate());
  }

  Future<void> _editPart(ComponentResponse part) async {
    final data = await showPartForm(
      context,
      types: c.types,
      today: c.today,
      part: part,
    );
    if (data != null) await c.editPart(part.id, data.toUpdate());
  }

  Future<void> _replacePart(ComponentResponse part) async {
    final data = await showPartForm(
      context,
      types: c.types,
      today: c.today,
      replacing: part,
    );
    if (data != null) await c.replacePart(part, data.toCreate());
  }

  Future<void> _removePart(ComponentResponse part) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${part.typeName.toLowerCase()} from the list?'),
        content: const Text(
          'Its history is deleted. To keep it, use Replace, which retires the part but keeps its wear.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            key: const Key('confirm-remove-part'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) await c.removePart(part.id);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('back'),
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Bikes'),
                  ),
                ),
                ..._body(context),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  List<Widget> _body(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final errorStyle = TextStyle(color: Theme.of(context).colorScheme.error);
    if (c.notFound) {
      return [
        Text(
          'This bike does not exist, or it is not yours.',
          key: const Key('not-found'),
          style: text.titleMedium,
        ),
      ];
    }
    final detail = c.detail;
    if (detail == null) {
      return [
        if (c.loading) const Center(child: CircularProgressIndicator()),
        if (c.error != null)
          Text(c.error!, key: const Key('bike-error'), style: errorStyle),
      ];
    }
    final bike = detail.bike;
    final make = [bike.brand, bike.model].whereType<String>().join(' ');
    final current = detail.components
        .where((p) => p.removedOn == null)
        .toList();
    final retired = detail.components
        .where((p) => p.removedOn != null)
        .toList();
    return [
      Row(
        spacing: 8,
        children: [
          Flexible(child: Text(bike.name, style: text.headlineSmall)),
          if (bike.isDefault) const Chip(label: Text('Default')),
          if (!bike.isActive) const Chip(label: Text('Archived')),
        ],
      ),
      Text(
        [
          bikeKinds[bike.kind] ?? bike.kind,
          if (make.isNotEmpty) make,
          'wheel ${bike.wheelCircumferenceMm} mm',
        ].join(' · '),
      ),
      Wrap(
        spacing: 24,
        runSpacing: 8,
        children: [
          _Stat('Distance', km(bike.distanceM)),
          _Stat('Rides', '${bike.rideCount}'),
          _Stat('Moving time', duration(bike.movingS)),
        ],
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            key: const Key('edit-bike'),
            onPressed: _edit,
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
          if (!bike.isDefault && bike.isActive)
            OutlinedButton.icon(
              key: const Key('make-default'),
              onPressed: c.makeDefault,
              icon: const Icon(Icons.star_outline),
              label: const Text('Make default'),
            ),
          OutlinedButton.icon(
            key: const Key('toggle-archive'),
            onPressed: () => c.setActive(!bike.isActive),
            icon: Icon(
              bike.isActive ? Icons.archive_outlined : Icons.unarchive_outlined,
            ),
            label: Text(bike.isActive ? 'Archive' : 'Restore'),
          ),
          TextButton.icon(
            key: const Key('delete-bike'),
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
      if (c.error != null)
        Text(c.error!, key: const Key('bike-error'), style: errorStyle),
      Row(
        children: [
          Text('Parts', style: text.titleLarge),
          const Spacer(),
          FilledButton.icon(
            key: const Key('add-part'),
            onPressed: _addPart,
            icon: const Icon(Icons.add),
            label: const Text('Add part'),
          ),
        ],
      ),
      if (current.isEmpty)
        const Text(
          'No parts yet. Add the chain, tyres or brake pads to see how worn they are.',
          key: Key('no-parts'),
        ),
      for (final part in current)
        _PartCard(
          part: part,
          onEdit: () => _editPart(part),
          onReplace: () => _replacePart(part),
          onRemove: () => _removePart(part),
        ),
      if (retired.isNotEmpty) ...[
        Text('Replaced parts', style: text.titleMedium),
        for (final part in retired)
          _PartCard(
            part: part,
            onEdit: () => _editPart(part),
            onRemove: () => _removePart(part),
          ),
      ],
    ];
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

Color wearColor(BuildContext context, String status) => switch (status) {
  'worn' => Theme.of(context).colorScheme.error,
  'soon' => const Color(0xFF7A5C00),
  'retired' => Theme.of(context).disabledColor,
  _ => deepTeal,
};

String wearLabel(String status) => switch (status) {
  'worn' => 'Replace it',
  'soon' => 'Getting worn',
  'retired' => 'Replaced',
  _ => 'Good',
};

/// "820 of 4000 km · 31 of 100 h · 5.2 of 12 months", only the limits the part has.
String wearText(ComponentResponse p) => [
  if (p.expectedDistanceM != null)
    '${(p.usedDistanceM / 1000).toStringAsFixed(0)} of ${(p.expectedDistanceM! / 1000).toStringAsFixed(0)} km',
  if (p.expectedHours != null)
    '${p.usedHours.toStringAsFixed(0)} of ${p.expectedHours!.toStringAsFixed(0)} h',
  if (p.expectedMonths != null)
    '${p.usedMonths.toStringAsFixed(1)} of ${p.expectedMonths} months',
  if (p.expectedDistanceM == null &&
      p.expectedHours == null &&
      p.expectedMonths == null)
    '${km(p.usedDistanceM)} · ${p.usedHours.toStringAsFixed(0)} h, no limit set',
].join(' · ');

class _PartCard extends StatelessWidget {
  const _PartCard({
    required this.part,
    required this.onEdit,
    this.onReplace,
    required this.onRemove,
  });

  final ComponentResponse part;
  final VoidCallback onEdit;
  final VoidCallback? onReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = wearColor(context, part.status);
    final make = [part.brand, part.model].whereType<String>().join(' ');
    return Card(
      key: Key('part-${part.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    make.isEmpty ? part.typeName : '${part.typeName} · $make',
                    style: text.titleMedium,
                  ),
                ),
                Text(
                  wearLabel(part.status),
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (part.wearPercent != null)
              Semantics(
                label: '${part.wearPercent}% worn',
                child: LinearProgressIndicator(
                  key: Key('wear-${part.id}'),
                  value: (part.wearPercent! / 100).clamp(0.0, 1.0),
                  color: color,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            Text(wearText(part), key: Key('wear-text-${part.id}')),
            Text(
              part.removedOn == null
                  ? 'Installed ${isoDate(part.installedOn)}'
                  : 'Installed ${isoDate(part.installedOn)} · removed ${isoDate(part.removedOn!)}',
              style: text.bodySmall,
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  key: Key('edit-${part.id}'),
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
                if (onReplace != null)
                  TextButton(
                    key: Key('replace-${part.id}'),
                    onPressed: onReplace,
                    child: const Text('Replace'),
                  ),
                TextButton(
                  key: Key('remove-${part.id}'),
                  onPressed: onRemove,
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
