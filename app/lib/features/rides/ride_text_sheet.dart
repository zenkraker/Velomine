import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../core/l10n.dart';
import '../../core/motion.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_text_field.dart';

/// Saves the title and description and answers whether the server took them.
typedef RideTextSaver = Future<bool> Function(
  String? title,
  String? description,
);

/// The longest title and description the server accepts.
const rideTitleLimit = 120;
const rideDescriptionLimit = 2000;

/// Opens the sheet where the member names a ride and writes about it. Both fields are optional;
/// emptying one removes it.
Future<void> showRideTextSheet(
  BuildContext context,
  RideResponse ride,
  RideTextSaver save,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  sheetAnimationStyle: AnimationStyle(
    duration: motionDuration(context, AppMotion.standard),
  ),
  builder: (_) => _RideTextSheet(ride: ride, save: save),
);

class _RideTextSheet extends StatefulWidget {
  const _RideTextSheet({required this.ride, required this.save});

  final RideResponse ride;
  final RideTextSaver save;

  @override
  State<_RideTextSheet> createState() => _RideTextSheetState();
}

class _RideTextSheetState extends State<_RideTextSheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.ride.title ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.ride.description ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final title = _title.text.trim();
    final description = _description.text.trim();
    final saved = await widget.save(
      title.isEmpty ? null : title,
      description.isEmpty ? null : description,
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
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Text(
              l10n.rideTextSheetTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              l10n.rideTextHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            AppTextField(
              fieldKey: const Key('ride-title-field'),
              controller: _title,
              label: l10n.rideTextTitle,
              helper: l10n.rideTextTitleHelper,
              enabled: !_saving,
              maxLength: rideTitleLimit,
            ),
            AppTextField(
              fieldKey: const Key('ride-description-field'),
              controller: _description,
              label: l10n.rideTextDescription,
              keyboardType: TextInputType.multiline,
              enabled: !_saving,
              maxLength: rideDescriptionLimit,
              maxLines: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: AppSpacing.sm,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  key: const Key('ride-text-save'),
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
