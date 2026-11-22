import 'dart:async';

import '../../core/widgets/loading_state.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/confirm.dart';
import '../../core/l10n.dart';
import '../../core/units.dart';
import '../../core/theme.dart';
import '../../core/user_message_text.dart';
import '../../l10n/generated/app_localizations.dart';
import 'bike_forms.dart';
import 'bikes_state.dart';
import 'bikes_view_models.dart';
import 'component_names.dart';
import 'service_section.dart';
import '../../core/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/page_scaffold.dart';
import 'row_menu.dart';
import '../../core/widgets/section_heading.dart';
import '../../core/widgets/stat_card.dart';

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

class BikeDetailScreen extends ConsumerWidget {
  const BikeDetailScreen({
    super.key,
    required this.id,
    required this.onDeleted,
  });

  final String id;
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
    final ok = await confirmDestructive(
      context,
      title: l10n.deleteBikeTitle,
      body: l10n.deleteBikeBody,
      action: l10n.delete,
      key: const Key('confirm-delete-bike'),
      cancelLabel: l10n.keepIt,
    );
    if (ok &&
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
    if (data != null && context.mounted) {
      final l10n = context.l10n;
      final name = componentTypeName(
        l10n,
        part.type,
        part.typeName,
      ).toLowerCase();
      final make = [data.brand, data.model].whereType<String>().join(' ');
      await ref
          .read(bikeDetailViewModelProvider(id).notifier)
          .replacePart(
            part,
            data.toCreate(),
            logTitle: make.isEmpty
                ? l10n.logReplacedPart(name)
                : l10n.logReplacedPartWith(name, make),
          );
    }
  }

  Future<void> _removePart(
    BuildContext context,
    WidgetRef ref,
    ComponentResponse part,
  ) async {
    final l10n = context.l10n;
    final ok = await confirmDestructive(
      context,
      title: l10n.removePartTitle(
        componentTypeName(l10n, part.type, part.typeName).toLowerCase(),
      ),
      body: l10n.removePartBody,
      action: l10n.remove,
      key: const Key('confirm-remove-part'),
      cancelLabel: l10n.keepIt,
    );
    if (ok) {
      await ref
          .read(bikeDetailViewModelProvider(id).notifier)
          .removePart(part.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(bikeDetailViewModelProvider(id));
    final l10n = context.l10n;

    listenUserMessages(
      ref,
      context,
      bikeDetailViewModelProvider(id).select((s) => s.messages),
      ref.read(bikeDetailViewModelProvider(id).notifier).messageShown,
    );

    final detail = s.detail;
    return PageScaffold(
      title: detail?.bike.name ?? l10n.navBikes,
      parent: l10n.navBikes,
      titleKey: const Key('bike-title'),
      primaryAction: detail == null ? null : _addPartButton(context, ref),
      menu: detail == null ? null : _bikeMenu(context, ref, detail.bike),
      children: _body(context, ref, s),
    );
  }

  /// The page's one action: a filled icon on a phone, whose tooltip names it, a labelled button from 600 dp.
  Widget _addPartButton(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return FilledButton.icon(
      key: const Key('add-part'),
      onPressed: () => _addPart(context, ref),
      icon: const Icon(Icons.add),
      label: Text(l10n.addPartAction),
    );
  }

  /// The rare jobs on a bike, behind one menu in the page header. Entries that open a sheet or a
  /// dialog wait for the menu to close.
  Widget _bikeMenu(BuildContext context, WidgetRef ref, BikeResponse bike) {
    final l10n = context.l10n;
    final notifier = ref.read(bikeDetailViewModelProvider(id).notifier);
    void later(Future<void> Function() run) => scheduleMicrotask(() {
      if (context.mounted) run();
    });
    return PageMenu(
      buttonKey: const Key('bike-actions'),
      entries: [
        PageMenuEntry(
          key: const Key('edit-bike'),
          icon: Icons.edit_outlined,
          label: l10n.edit,
          onSelected: () => later(() => _edit(context, ref)),
        ),
        PageMenuEntry(
          key: const Key('save-template'),
          label: l10n.saveAsTemplate,
          onSelected: () => later(() => _saveTemplate(context, ref)),
        ),
        PageMenuEntry(
          key: const Key('apply-template'),
          label: l10n.applyTemplate,
          onSelected: () => later(() => _applyTemplate(context, ref)),
        ),
        if (!bike.isDefault && bike.isActive)
          PageMenuEntry(
            key: const Key('make-default'),
            label: l10n.makeDefault,
            onSelected: notifier.makeDefault,
          ),
        PageMenuEntry(
          key: const Key('toggle-archive'),
          label: bike.isActive ? l10n.archive : l10n.restore,
          onSelected: () => notifier.setActive(!bike.isActive),
        ),
        PageMenuEntry(
          key: const Key('delete-bike'),
          icon: Icons.delete_outline,
          label: l10n.delete,
          destructive: true,
          onSelected: () => later(() => _confirmDelete(context, ref)),
        ),
      ],
    );
  }

  List<Widget> _body(BuildContext context, WidgetRef ref, BikeDetailState s) {
    final units = ref.watch(unitsChoiceViewModelProvider);
    final text = Theme.of(context).textTheme;
    final l10n = context.l10n;
    if (s.notFound) {
      return [
        EmptyState(
          key: const Key('not-found'),
          message: l10n.bikeNotFound,
          icon: Icons.pedal_bike,
        ),
      ];
    }
    final detail = s.detail;
    if (detail == null) {
      return [
        if (s.load.running) const LoadingState(),
        if (s.load.failure case final failure?)
          ErrorState(
            message: failureText(l10n, failure),
            actionKey: const Key('bike-error'),
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
      if (bike.isDefault || !bike.isActive)
        Wrap(
          spacing: AppSpacing.sm,
          children: [
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
        spacing: AppSpacing.xl,
        runSpacing: 8,
        children: [
          StatFigure(
            label: l10n.statDistance,
            value: km(units, bike.distanceM),
          ),
          StatFigure(label: l10n.statRides, value: '${bike.rideCount}'),
          StatFigure(label: l10n.statMovingTime, value: duration(bike.movingS)),
        ],
      ),
      if (s.load.failure case final failure?)
        ErrorState(
          message: failureText(l10n, failure),
          actionKey: const Key('bike-error'),
        ),
      ServiceSection(id: id),
      SectionHeading(title: l10n.parts),
      if (current.isEmpty)
        EmptyState(
          key: const Key('no-parts'),
          message: l10n.noParts,
          icon: Icons.build_outlined,
          action: OutlinedButton.icon(
            key: const Key('add-part-empty'),
            onPressed: () => _addPart(context, ref),
            icon: const Icon(Icons.add),
            label: Text(l10n.addPartAction),
          ),
        ),
      // The fitted parts as the component types group them: drivetrain, wheels, brakes, and so on.
      for (final group in groupParts(l10n, current, s.types)) ...[
        Text(group.name, style: text.labelLarge),
        for (final part in group.parts)
          _PartCard(
            part: part,
            onEdit: () => _editPart(context, ref, part),
            onReplace: () => _replacePart(context, ref, part),
            onRemove: () => _removePart(context, ref, part),
          ),
      ],
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

/// A wear distance in whole kilometres or whole miles, whichever the member reads.
String _wearNumber(Units units, double metres) => units == Units.imperial
    ? (metres / 1609.344).toStringAsFixed(0)
    : (metres / 1000).toStringAsFixed(0);

/// "820 of 4000 km · 31 of 100 h · 5.2 of 12 months", only the limits the part has.
String wearText(AppLocalizations l10n, Units units, ComponentResponse p) => [
  if (p.expectedDistanceM != null)
    '${l10n.wearDistance(_wearNumber(units, p.usedDistanceM), _wearNumber(units, p.expectedDistanceM!))} ${distanceUnit(units)}',
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
    l10n.wearNoLimit(
      km(units, p.usedDistanceM),
      p.usedHours.toStringAsFixed(0),
    ),
].join(' · ');

class _PartCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final color = wearColor(context, part.status);
    final make = [part.brand, part.model].whereType<String>().join(' ');
    final typeName = componentTypeName(l10n, part.type, part.typeName);
    return AppCard(
      key: Key('part-${part.id}'),
      padding: const EdgeInsets.all(AppSpacing.lg),
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
              RowRemoveMenu(
                menuKey: Key('part-actions-${part.id}'),
                removeKey: Key('remove-${part.id}'),
                onRemove: onRemove,
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
          Text(
            wearText(l10n, ref.watch(unitsChoiceViewModelProvider), part),
            key: Key('wear-text-${part.id}'),
          ),
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
            Text(part.mpn!, key: Key('mpn-${part.id}'), style: text.bodySmall),
          Wrap(
            spacing: AppSpacing.sm,
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
            ],
          ),
        ],
      ),
    );
  }
}

/// The fitted parts grouped as the component types group them, in the order the groups first appear:
/// drivetrain (chain, cassette), wheels (tyres, sealant), brakes, and so on.
List<({String name, List<ComponentResponse> parts})> groupParts(
  AppLocalizations l10n,
  List<ComponentResponse> parts,
  List<ComponentTypeResponse> types,
) {
  final groupOf = {for (final type in types) type.id: type.group};
  final order = <String>[];
  final grouped = <String, List<ComponentResponse>>{};
  for (final part in parts) {
    final group = groupOf[part.type] ?? 'other';
    if (!grouped.containsKey(group)) order.add(group);
    grouped.putIfAbsent(group, () => []).add(part);
  }
  return [
    for (final group in order)
      (name: componentGroupName(l10n, group), parts: grouped[group]!),
  ];
}
