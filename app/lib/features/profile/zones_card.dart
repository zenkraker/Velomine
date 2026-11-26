import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/heart_rate_zones.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/form_sheet.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/source_note.dart';
import 'profile_view_model.dart';

const powerSet = 'power';
const heartRateMaxSet = 'heart-rate-max';
const heartRateThresholdSet = 'heart-rate-threshold';

/// The sets the profile lists: power, then the heart-rate model in use. A set the rider has no number for has no
/// zones to show. The other model's bounds stay saved, so they apply when the rider's model changes.
List<ZoneSetResponse> zonesInUse(ZonesResponse zones) {
  final model = zones.heartRateModel;
  final wanted = {powerSet, if (model != null) 'heart-rate-$model'};
  return [
    for (final set in zones.sets)
      if (wanted.contains(set.set_) && set.reference != null) set,
  ];
}

/// The zones in use, with the way to move their limits by hand and back to automatic.
class ZonesCard extends StatelessWidget {
  const ZonesCard({super.key, required this.zones, this.onReset});

  final ZonesResponse zones;

  /// Back to the standard bounds; null while the screen has nothing to reset.
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final sets = zonesInUse(zones);
    return SectionCard(
      title: l10n.zonesTitle,
      menu: PageMenu(
        buttonKey: const Key('zones-actions'),
        entries: [
          PageMenuEntry(
            key: const Key('zones-reset'),
            label: l10n.zonesBackToAutomatic,
            icon: Icons.restart_alt,
            onSelected: () => onReset?.call(),
          ),
        ],
      ),
      children: [
        for (final set in sets) ...[
          if (sets.length > 1)
            Text(
              set.set_ == powerSet ? l10n.powerZones : l10n.heartRateZones,
              style: text.labelLarge,
            ),
          for (final zone in set.zones)
            _ZoneRow(zone: zone, unit: set.set_ == powerSet ? 'W' : 'bpm'),
          if (set.set_ != powerSet)
            if (heartRateZonesSource(
                  l10n,
                  zones.heartRateModel,
                  set.reference,
                  set.referenceSource,
                )
                case final note?)
              SourceNote(note, key: const Key('profile-zones-source')),
          if (set.custom)
            SourceNote(
              l10n.zonesCustom,
              key: Key('profile-zones-custom-${set.set_}'),
            ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('zones-edit'),
            onPressed: sets.isEmpty
                ? null
                : () => showSheet<void>(
                    context,
                    builder: (_) => ZonesSheet(sets: sets),
                  ),
            icon: const Icon(Icons.tune),
            label: Text(l10n.zonesEdit),
          ),
        ),
      ],
    );
  }
}

/// One zone of the list: its number and the watts or bpm it runs between.
class _ZoneRow extends StatelessWidget {
  const _ZoneRow({required this.zone, required this.unit});

  final ZoneTime zone;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final range = zone.to == null
        ? l10n.zoneRangeOpen(zone.from, unit)
        : l10n.zoneRange(zone.from, zone.to!, unit);
    return Row(
      spacing: AppSpacing.sm,
      children: [
        SizedBox(
          // The design's 120 px label column: the number and its word.
          // shortcut: 4 × zoneLabelWidth until tokens.dart grows a named width for it.
          width: AppProgress.zoneLabelWidth * 4,
          child: Text(l10n.zoneName('${zone.zone}'), style: text.labelMedium),
        ),
        Text(range, style: text.bodyMedium),
      ],
    );
  }
}

/// The rider's own limits: one field per zone in watts or bpm, which the app turns into fractions of the reference
/// so the zones follow the FTP or the heart rate when it changes.
class ZonesSheet extends ConsumerStatefulWidget {
  const ZonesSheet({super.key, required this.sets});

  final List<ZoneSetResponse> sets;

  @override
  ConsumerState<ZonesSheet> createState() => _ZonesSheetState();
}

class _ZonesSheetState extends ConsumerState<ZonesSheet> {
  final _fields = <String, List<TextEditingController>>{};
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _fill(widget.sets);
  }

  /// The fields show the values in use, so after saving they show what the server kept, not what was typed.
  void _fill(List<ZoneSetResponse> sets) {
    for (final set in sets) {
      final reference = set.reference ?? 0;
      final values = [
        for (final bound in set.bounds) (bound * reference).round().toString(),
      ];
      final existing = _fields[set.set_];
      if (existing == null) {
        _fields[set.set_] = [
          for (final value in values) TextEditingController(text: value),
        ];
      } else {
        for (final (index, controller) in existing.indexed) {
          controller.text = values[index];
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controllers in _fields.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final changes = <String, List<double>>{};
    for (final set in widget.sets) {
      final reference = set.reference!;
      final bounds = <double>[];
      for (final controller in _fields[set.set_]!) {
        final typed = double.tryParse(
          controller.text.trim().replaceAll(',', '.'),
        );
        if (typed == null || typed <= 0) {
          setState(() => _error = l10n.zonesInvalidLimit);
          return;
        }
        // Two decimals of the reference, which can move a typed watt by one (Story 4, rule 4).
        bounds.add(double.parse((typed / reference).toStringAsFixed(2)));
      }
      for (var i = 1; i < bounds.length; i++) {
        if (bounds[i] <= bounds[i - 1]) {
          setState(() => _error = l10n.zonesNotRising);
          return;
        }
      }
      changes[set.set_] = bounds;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final notifier = ref.read(profileViewModelProvider.notifier);
    for (final change in changes.entries) {
      final failure = await notifier.setZones(change.key, change.value);
      if (!mounted) return;
      if (failure != null) {
        setState(() {
          _busy = false;
          _error = failureText(l10n, failure);
        });
        return;
      }
    }

    final zones = ref.read(profileViewModelProvider).zones;
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (zones != null) {
        _fill([
          for (final set in zones.sets)
            if (changes.containsKey(set.set_)) set,
        ]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      title: l10n.zonesEditTitle,
      saveKey: const Key('zones-save'),
      onSave: _busy ? null : _save,
      error: _error,
      children: [
        Text(l10n.zonesEditHelp),
        for (final set in widget.sets) ...[
          if (widget.sets.length > 1)
            Text(
              set.set_ == powerSet ? l10n.powerZones : l10n.heartRateZones,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          for (final (index, controller) in _fields[set.set_]!.indexed)
            AppTextField(
              fieldKey: Key('zone-limit-${set.set_}-${index + 1}'),
              controller: controller,
              label: l10n.zonesLimitLabel(index + 1),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              suffix: set.set_ == powerSet ? 'W' : 'bpm',
            ),
        ],
      ],
    );
  }
}
