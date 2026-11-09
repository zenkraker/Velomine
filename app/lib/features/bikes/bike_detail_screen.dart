import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import 'bike_forms.dart';
import 'bikes_controller.dart';
import 'component_names.dart';

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
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteBikeTitle),
        content: Text(l10n.deleteBikeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepIt),
          ),
          FilledButton(
            key: const Key('confirm-delete-bike'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true && await c.delete()) widget.onDeleted();
  }

  Future<void> _addPart() async {
    final data = await showPartForm(
      context,
      types: c.types,
      today: c.today,
      search: c.searchParts,
    );
    if (data != null) await c.addPart(data.toCreate());
  }

  Future<void> _editPart(ComponentResponse part) async {
    final data = await showPartForm(
      context,
      types: c.types,
      today: c.today,
      search: c.searchParts,
      part: part,
    );
    if (data != null) await c.editPart(part.id, data.toUpdate());
  }

  Future<void> _replacePart(ComponentResponse part) async {
    final data = await showPartForm(
      context,
      types: c.types,
      today: c.today,
      search: c.searchParts,
      replacing: part,
    );
    if (data != null) await c.replacePart(part, data.toCreate());
  }

  Future<void> _removePart(ComponentResponse part) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.removePartTitle(
            componentTypeName(l10n, part.type, part.typeName).toLowerCase(),
          ),
        ),
        content: Text(l10n.removePartBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepIt),
          ),
          FilledButton(
            key: const Key('confirm-remove-part'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.remove),
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
                    label: Text(context.l10n.navBikes),
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
    final l10n = context.l10n;
    final errorStyle = TextStyle(color: Theme.of(context).colorScheme.error);
    if (c.notFound) {
      return [
        Text(
          l10n.bikeNotFound,
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
          Text(
            failureText(context.l10n, c.error!),
            key: const Key('bike-error'),
            style: errorStyle,
          ),
      ];
    }
    final bike = detail.bike;
    final make = [bike.brand, bike.model].whereType<String>().join(' ');
    final model = [
      if (bike.modelYear != null) '${bike.modelYear}',
      bike.buildSpec,
      if (bike.frameSize != null) bike.frameSize!,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
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
          if (bike.isDefault) Chip(label: Text(l10n.defaultBike)),
          if (!bike.isActive) Chip(label: Text(l10n.archived)),
        ],
      ),
      Text(
        [
          bikeKindName(l10n, bike.kind),
          if (make.isNotEmpty) make,
          if (model.isNotEmpty) model,
          l10n.wheelLabel(bike.wheelCircumferenceMm),
        ].join(' · '),
      ),
      Wrap(
        spacing: 24,
        runSpacing: 8,
        children: [
          _Stat(l10n.statDistance, km(bike.distanceM)),
          _Stat(l10n.statRides, '${bike.rideCount}'),
          _Stat(l10n.statMovingTime, duration(bike.movingS)),
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
            label: Text(l10n.edit),
          ),
          if (!bike.isDefault && bike.isActive)
            OutlinedButton.icon(
              key: const Key('make-default'),
              onPressed: c.makeDefault,
              icon: const Icon(Icons.star_outline),
              label: Text(l10n.makeDefault),
            ),
          OutlinedButton.icon(
            key: const Key('toggle-archive'),
            onPressed: () => c.setActive(!bike.isActive),
            icon: Icon(
              bike.isActive ? Icons.archive_outlined : Icons.unarchive_outlined,
            ),
            label: Text(bike.isActive ? l10n.archive : l10n.restore),
          ),
          TextButton.icon(
            key: const Key('delete-bike'),
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.delete),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
      if (c.error != null)
        Text(
          failureText(context.l10n, c.error!),
          key: const Key('bike-error'),
          style: errorStyle,
        ),
      Row(
        children: [
          Text(l10n.parts, style: text.titleLarge),
          const Spacer(),
          FilledButton.icon(
            key: const Key('add-part'),
            onPressed: _addPart,
            icon: const Icon(Icons.add),
            label: Text(l10n.addPartAction),
          ),
        ],
      ),
      if (current.isEmpty) Text(l10n.noParts, key: const Key('no-parts')),
      for (final part in current)
        _PartCard(
          part: part,
          onEdit: () => _editPart(part),
          onReplace: () => _replacePart(part),
          onRemove: () => _removePart(part),
        ),
      if (retired.isNotEmpty) ...[
        Text(l10n.replacedParts, style: text.titleMedium),
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
  'soon' => VelomineColors.of(context).wearSoon,
  'retired' => Theme.of(context).disabledColor,
  _ => VelomineColors.of(context).wearOk,
};

String wearLabel(AppLocalizations l10n, String status) => switch (status) {
  'worn' => l10n.wearReplace,
  'soon' => l10n.wearSoon,
  'retired' => l10n.wearReplaced,
  _ => l10n.wearGood,
};

/// "820 of 4000 km · 31 of 100 h · 5.2 of 12 months", only the limits the part has.
String wearText(AppLocalizations l10n, ComponentResponse p) => [
  if (p.expectedDistanceM != null)
    l10n.wearDistance(
      (p.usedDistanceM / 1000).toStringAsFixed(0),
      (p.expectedDistanceM! / 1000).toStringAsFixed(0),
    ),
  if (p.expectedHours != null)
    l10n.wearHours(
      p.usedHours.toStringAsFixed(0),
      p.expectedHours!.toStringAsFixed(0),
    ),
  if (p.expectedMonths != null)
    l10n.wearMonths(
      NumberFormat('0.0').format(p.usedMonths),
      p.expectedMonths!,
    ),
  if (p.expectedDistanceM == null &&
      p.expectedHours == null &&
      p.expectedMonths == null)
    l10n.wearNoLimit(km(p.usedDistanceM), p.usedHours.toStringAsFixed(0)),
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
    final l10n = context.l10n;
    final color = wearColor(context, part.status);
    final make = [part.brand, part.model].whereType<String>().join(' ');
    final typeName = componentTypeName(l10n, part.type, part.typeName);
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
                    make.isEmpty ? typeName : '$typeName · $make',
                    style: text.titleMedium,
                  ),
                ),
                Text(
                  wearLabel(l10n, part.status),
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (part.wearPercent != null)
              Semantics(
                label: l10n.wearPercent(part.wearPercent!),
                child: LinearProgressIndicator(
                  key: Key('wear-${part.id}'),
                  value: (part.wearPercent! / 100).clamp(0.0, 1.0),
                  color: color,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            Text(wearText(l10n, part), key: Key('wear-text-${part.id}')),
            Text(
              part.removedOn == null
                  ? l10n.installedOn(isoDate(part.installedOn))
                  : l10n.installedAndRemoved(
                      isoDate(part.installedOn),
                      isoDate(part.removedOn!),
                    ),
              style: text.bodySmall,
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  key: Key('edit-${part.id}'),
                  onPressed: onEdit,
                  child: Text(l10n.edit),
                ),
                if (onReplace != null)
                  TextButton(
                    key: Key('replace-${part.id}'),
                    onPressed: onReplace,
                    child: Text(l10n.replace),
                  ),
                TextButton(
                  key: Key('remove-${part.id}'),
                  onPressed: onRemove,
                  child: Text(l10n.remove),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
