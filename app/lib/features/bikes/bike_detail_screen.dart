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
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/page_scaffold.dart';
import 'row_menu.dart';
import '../../core/widgets/badge.dart';
import '../../core/widgets/card_grid.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/stat_card.dart';

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// The wear column at the end of a part row: the percentage over the bar, 180 px as the mock-up draws it.
/// No token carries it, so it is named here rather than spelled twice.
const _wearColumnWidth = 180.0;

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
      subtitle: detail == null ? null : _specLine(l10n, detail.bike),
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
    final current = detail.components
        .where((p) => p.removedOn == null)
        .toList();
    return [
      if (bike.isDefault || !bike.isActive)
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            if (bike.isDefault)
              AppBadge(l10n.defaultBike, tone: AppBadgeTone.good),
            if (!bike.isActive) AppBadge(l10n.archived),
          ],
        ),
      if (s.load.failure case final failure?)
        ErrorState(
          message: failureText(l10n, failure),
          actionKey: const Key('bike-error'),
        ),
      // What the bike has done, in the four numbers the mock-up opens the page with.
      SectionCard(
        title: l10n.totals,
        children: [
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            children: [
              StatFigure(
                label: l10n.statDistance,
                value: km(units, bike.distanceM),
              ),
              StatFigure(label: l10n.statRides, value: '${bike.rideCount}'),
              StatFigure(
                label: l10n.statMovingTime,
                value: duration(bike.movingS),
              ),
              StatFigure(label: l10n.parts, value: '${current.length}'),
            ],
          ),
        ],
      ),
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
        )
      else
        // One card per group the component types make: drivetrain, wheels, brakes, and so on. A part that
        // was replaced stays in its group, marked "Replaced", so nothing it holds is lost from the page.
        CardGrid(
          columns: 2,
          // One card a row under the desktop width: the wear column is 180 px, and in a half-width card of a
          // tablet it has no room beside the part's own words.
          tabletColumns: 1,
          children: [
            for (final group in groupParts(l10n, detail.components, s.types))
              SectionCard(
                key: Key('group-${group.name}'),
                title: group.name,
                children: [
                  for (final part in group.parts)
                    _PartRow(
                      part: part,
                      onEdit: () => _editPart(context, ref, part),
                      onReplace: part.removedOn == null
                          ? () => _replacePart(context, ref, part)
                          : null,
                      onRemove: () => _removePart(context, ref, part),
                    ),
                ],
              ),
          ],
        ),
      ServiceSection(id: id),
    ];
  }
}

/// "Road · Trek Domane · 2023 · SL 7 · 56 · wheel 2105 mm": what the bike is, under the title.
String _specLine(AppLocalizations l10n, BikeResponse bike) {
  final make = [bike.brand, bike.model].whereType<String>().join(' ');
  final model = [
    if (bike.modelYear != null) '${bike.modelYear}',
    bike.buildSpec,
    if (bike.frameSize != null) bike.frameSize!,
  ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
  return [
    bikeKindName(l10n, bike.kind),
    if (make.isNotEmpty) make,
    if (model.isNotEmpty) model,
    l10n.wheelLabel(bike.wheelCircumferenceMm),
  ].join(' · ');
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
    ? decimal((metres / 1609.344), 0)
    : decimal((metres / 1000), 0);

/// "820 of 4000 km · 31 of 100 h · 5.2 of 12 months", only the limits the part has.
String wearText(AppLocalizations l10n, Units units, ComponentResponse p) => [
  if (p.expectedDistanceM != null)
    '${l10n.wearDistance(_wearNumber(units, p.usedDistanceM), _wearNumber(units, p.expectedDistanceM!))} ${distanceUnit(units)}',
  if (p.expectedHours != null)
    l10n.wearHours(decimal(p.usedHours, 0), decimal(p.expectedHours!, 0)),
  if (p.expectedMonths != null)
    l10n.wearMonths(
      NumberFormat('0.0').format(p.usedMonths),
      p.expectedMonths!,
    ),
  if (p.expectedDistanceM == null &&
      p.expectedHours == null &&
      p.expectedMonths == null)
    l10n.wearNoLimit(km(units, p.usedDistanceM), decimal(p.usedHours, 0)),
].join(' · ');

/// One part as a row of its group's card: what it is and how far it has gone on the left, the wear as the
/// mock-up's 180 px column on the right — the percentage in words over the bar — and the row's `⋯`.
class _PartRow extends ConsumerWidget {
  const _PartRow({
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
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final color = wearColor(context, part.status);
    final make = [part.brand, part.model].whereType<String>().join(' ');
    final typeName = componentTypeName(l10n, part.type, part.typeName);
    return Row(
      key: Key('part-${part.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              Text(typeName, style: text.bodyLarge),
              // The wear colour never stands alone: the state is a word beside it.
              Text(
                wearLabel(l10n, part.status),
                style: text.labelLarge?.copyWith(color: color),
              ),
              if (part.isCustom) Text(l10n.customPart, style: text.bodySmall),
              Text(
                [
                  if (make.isNotEmpty) make,
                  wearText(l10n, ref.watch(unitsChoiceViewModelProvider), part),
                ].join(' · '),
                key: Key('wear-text-${part.id}'),
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
                Text(
                  part.mpn!,
                  key: Key('mpn-${part.id}'),
                  style: text.bodySmall,
                ),
            ],
          ),
        ),
        if (part.wearPercent != null)
          SizedBox(
            width: _wearColumnWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: AppSpacing.xs,
              children: [
                Text(
                  l10n.wearPercent(part.wearPercent!),
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.end,
                ),
                LinearProgressIndicator(
                  key: Key('wear-${part.id}'),
                  value: (part.wearPercent! / 100).clamp(0.0, 1.0),
                  color: color,
                  minHeight: AppSpacing.sm,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  semanticsLabel: l10n.wearPercent(part.wearPercent!),
                ),
              ],
            ),
          ),
        RowActionMenu(
          menuKey: Key('part-actions-${part.id}'),
          removeKey: Key('remove-${part.id}'),
          onRemove: onRemove,
          actions: [
            PageMenuEntry(
              key: Key('edit-${part.id}'),
              icon: Icons.edit_outlined,
              label: l10n.edit,
              onSelected: onEdit,
            ),
            if (onReplace case final onReplace?)
              PageMenuEntry(
                key: Key('replace-${part.id}'),
                icon: Icons.swap_horiz,
                label: l10n.replace,
                onSelected: onReplace,
              ),
          ],
        ),
      ],
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
