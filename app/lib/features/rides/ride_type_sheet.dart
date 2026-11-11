import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/motion.dart';

/// Saves the four dimensions of a ride and answers whether the server took them.
typedef RideTypeSaver = Future<bool> Function({
  String? discipline,
  String? assist,
  String? environment,
  bool? commute,
});

/// Opens the sheet that sets the four independent ride dimensions. Every field is optional.
Future<void> showRideTypeSheet(
  BuildContext context,
  RideResponse ride,
  RideTypeSaver save,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  // The sheet keeps the app's motion, or none when the system asks for none.
  sheetAnimationStyle: AnimationStyle(
    duration: motionDuration(context, AppMotion.standard),
  ),
  builder: (_) => _RideTypeSheet(ride: ride, save: save),
);

class _RideTypeSheet extends StatefulWidget {
  const _RideTypeSheet({required this.ride, required this.save});

  final RideResponse ride;
  final RideTypeSaver save;

  @override
  State<_RideTypeSheet> createState() => _RideTypeSheetState();
}

class _RideTypeSheetState extends State<_RideTypeSheet> {
  // The dropdowns use an empty string for "not set", because a null value cannot be selected in a
  // DropdownButton; it is translated back to null when the sheet is saved.
  late String _discipline = widget.ride.discipline ?? '';
  late String _assist = widget.ride.assist ?? '';
  late String _environment = widget.ride.environment ?? '';
  late String _commute = switch (widget.ride.commute) {
    true => 'yes',
    false => 'no',
    null => '',
  };
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final saved = await widget.save(
      discipline: _discipline.isEmpty ? null : _discipline,
      assist: _assist.isEmpty ? null : _assist,
      environment: _environment.isEmpty ? null : _environment,
      commute: switch (_commute) {
        'yes' => true,
        'no' => false,
        _ => null,
      },
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Text(
              l10n.rideTypeTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              l10n.rideTypeHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            _Choice(
              fieldKey: const Key('ride-type-discipline'),
              label: l10n.rideTypeDiscipline,
              value: _discipline,
              items: {
                '': l10n.rideTypeUnset,
                'road': l10n.bikeKindRoad,
                'gravel': l10n.bikeKindGravel,
                'mountain': l10n.bikeKindMountain,
                'track': l10n.bikeKindTrack,
              },
              onChanged: (value) => setState(() => _discipline = value),
            ),
            _Choice(
              fieldKey: const Key('ride-type-assist'),
              label: l10n.rideTypeAssist,
              value: _assist,
              items: {
                '': l10n.rideTypeUnset,
                'none': l10n.rideTypeNoAssist,
                'ebike': l10n.bikeKindEbike,
              },
              onChanged: (value) => setState(() => _assist = value),
            ),
            _Choice(
              fieldKey: const Key('ride-type-environment'),
              label: l10n.rideTypeEnvironment,
              value: _environment,
              items: {
                '': l10n.rideTypeUnset,
                'outdoor': l10n.rideTypeOutdoor,
                'indoor': l10n.rideTypeIndoor,
                'virtual': l10n.rideTypeVirtual,
              },
              onChanged: (value) => setState(() => _environment = value),
            ),
            _Choice(
              fieldKey: const Key('ride-type-commute'),
              label: l10n.rideTypeCommute,
              value: _commute,
              items: {'': l10n.rideTypeUnset, 'yes': l10n.yes, 'no': l10n.no},
              onChanged: (value) => setState(() => _commute = value),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const Key('ride-type-cancel'),
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  key: const Key('ride-type-save'),
                  onPressed: _saving ? null : _save,
                  child: Text(l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final Key fieldKey;
  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(labelText: label),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        key: fieldKey,
        value: value,
        isExpanded: true,
        items: [
          for (final entry in items.entries)
            DropdownMenuItem(value: entry.key, child: Text(entry.value)),
        ],
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    ),
  );
}
