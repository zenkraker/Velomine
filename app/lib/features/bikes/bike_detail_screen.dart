import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/user_message_text.dart';
import '../../l10n/generated/app_localizations.dart';
import 'bike_forms.dart';
import 'bikes_state.dart';
import 'bikes_view_models.dart';
import 'component_names.dart';

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

class BikeDetailScreen extends ConsumerWidget {
  const BikeDetailScreen({
    super.key,
    required this.id,
    required this.onBack,
    required this.onDeleted,
  });

  final String id;
  final VoidCallback onBack;
  final VoidCallback onDeleted;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final bike = ref.read(bikeDetailViewModelProvider(id)).detail!.bike;
    final data = await showBikeForm(context, bike: bike);
    if (data != null) {
      await ref
          .read(bikeDetailViewModelProvider(id).notifier)
          .save(data.toUpdate(isActive: bike.isActive));
    }
  }

  Future<void> _saveTemplate(BuildContext context, WidgetRef ref) async {
    final name = await showTemplateNameDialog(context);
    if (name == null) return;
    final saved = await ref
        .read(bikeDetailViewModelProvider(id).notifier)
        .saveTemplateFromBike(name);
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.saved)));
    }
  }

  Future<void> _applyTemplate(BuildContext context, WidgetRef ref) async {
    final templates = ref.read(bikeDetailViewModelProvider(id)).templates;
    final template = await showApplyTemplateDialog(
      context,
      templates: templates,
    );
    if (template == null) return;
    final applied = await ref
        .read(bikeDetailViewModelProvider(id).notifier)
        .applyTemplate(template.id);
    if (applied && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.templateApplied)));
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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
    if (ok == true &&
        await ref.read(bikeDetailViewModelProvider(id).notifier).delete()) {
      onDeleted();
    }
  }

  Future<void> _addPart(BuildContext context, WidgetRef ref) async {
    final s = ref.read(bikeDetailViewModelProvider(id));
    final data = await showPartForm(
      context,
      types: s.types,
      today: _today(),
      search: ref.read(bikeDetailViewModelProvider(id).notifier).searchParts,
    );
    if (data != null) {
      await ref
          .read(bikeDetailViewModelProvider(id).notifier)
          .addPart(data.toCreate());
    }
  }

  Future<void> _editPart(
    BuildContext context,
    WidgetRef ref,
    ComponentResponse part,
  ) async {
    final s = ref.read(bikeDetailViewModelProvider(id));
    final data = await showPartForm(
      context,
      types: s.types,
      today: _today(),
      search: ref.read(bikeDetailViewModelProvider(id).notifier).searchParts,
      part: part,
    );
    if (data != null) {
      await ref
          .read(bikeDetailViewModelProvider(id).notifier)
          .editPart(part.id, data.toUpdate());
    }
  }

  Future<void> _replacePart(
    BuildContext context,
    WidgetRef ref,
    ComponentResponse part,
  ) async {
    final s = ref.read(bikeDetailViewModelProvider(id));
    final data = await showPartForm(
      context,
      types: s.types,
      today: _today(),
      search: ref.read(bikeDetailViewModelProvider(id).notifier).searchParts,
      replacing: part,
    );
    if (data != null) {
      await ref
          .read(bikeDetailViewModelProvider(id).notifier)
          .replacePart(part, data.toCreate());
    }
  }

  Future<void> _removePart(
    BuildContext context,
    WidgetRef ref,
    ComponentResponse part,
  ) async {
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
    if (ok == true) {
      await ref
          .read(bikeDetailViewModelProvider(id).notifier)
          .removePart(part.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(bikeDetailViewModelProvider(id));
    final l10n = context.l10n;

    ref.listen(bikeDetailViewModelProvider(id).select((s) => s.messages), (
      _,
      messages,
    ) {
      for (final message in messages) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userMessageText(l10n, message))));
        ref
            .read(bikeDetailViewModelProvider(id).notifier)
            .messageShown(message.id);
      }
    });

    return ListView(
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
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l10n.navBikes),
                  ),
                ),
                ..._body(context, ref, s),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _body(BuildContext context, WidgetRef ref, BikeDetailState s) {
    final text = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final errorStyle = TextStyle(color: Theme.of(context).colorScheme.error);
    if (s.notFound) {
      return [
        Text(
          l10n.bikeNotFound,
          key: const Key('not-found'),
          style: text.titleMedium,
        ),
      ];
    }
    final detail = s.detail;
    if (detail == null) {
      return [
        if (s.load.running) const Center(child: CircularProgressIndicator()),
        if (s.load.failure case final failure?)
          Text(
            failureText(l10n, failure),
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
    final notifier = ref.read(bikeDetailViewModelProvider(id).notifier);
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
            onPressed: () => _edit(context, ref),
            icon: const Icon(Icons.edit),
            label: Text(l10n.edit),
          ),
          OutlinedButton.icon(
            key: const Key('save-template'),
            onPressed: () => _saveTemplate(context, ref),
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(l10n.saveAsTemplate),
          ),
          OutlinedButton.icon(
            key: const Key('apply-template'),
            onPressed: () => _applyTemplate(context, ref),
            icon: const Icon(Icons.playlist_add_check),
            label: Text(l10n.applyTemplate),
          ),
          if (!bike.isDefault && bike.isActive)
            OutlinedButton.icon(
              key: const Key('make-default'),
              onPressed: notifier.makeDefault,
              icon: const Icon(Icons.star_outline),
              label: Text(l10n.makeDefault),
            ),
          OutlinedButton.icon(
            key: const Key('toggle-archive'),
            onPressed: () => notifier.setActive(!bike.isActive),
            icon: Icon(
              bike.isActive ? Icons.archive_outlined : Icons.unarchive_outlined,
            ),
            label: Text(bike.isActive ? l10n.archive : l10n.restore),
          ),
          TextButton.icon(
            key: const Key('delete-bike'),
            onPressed: () => _confirmDelete(context, ref),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.delete),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
      if (s.load.failure case final failure?)
        Text(
          failureText(l10n, failure),
          key: const Key('bike-error'),
          style: errorStyle,
        ),
      Row(
        children: [
          Text(l10n.parts, style: text.titleLarge),
          const Spacer(),
          FilledButton.icon(
            key: const Key('add-part'),
            onPressed: () => _addPart(context, ref),
            icon: const Icon(Icons.add),
            label: Text(l10n.addPartAction),
          ),
        ],
      ),
      if (current.isEmpty) Text(l10n.noParts, key: const Key('no-parts')),
      for (final part in current)
        _PartCard(
          part: part,
          onEdit: () => _editPart(context, ref, part),
          onReplace: () => _replacePart(context, ref, part),
          onRemove: () => _removePart(context, ref, part),
        ),
      if (retired.isNotEmpty) ...[
        Text(l10n.replacedParts, style: text.titleMedium),
        for (final part in retired)
          _PartCard(
            part: part,
            onEdit: () => _editPart(context, ref, part),
            onRemove: () => _removePart(context, ref, part),
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
            if (part.isCustom) Text(l10n.customPart, style: text.bodySmall),
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
            if (part.mpn != null)
              Text(
                part.mpn!,
                key: Key('mpn-${part.id}'),
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
