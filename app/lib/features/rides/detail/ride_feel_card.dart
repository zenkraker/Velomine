import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../../core/l10n.dart';
import '../../../core/tokens.dart';

/// How hard the ride felt and an optional note. Owner-only; coaches see the RPE but never the note.
class RideFeelCard extends StatefulWidget {
  const RideFeelCard({
    super.key,
    required this.feel,
    required this.onSave,
    required this.onDelete,
    required this.saving,
  });

  final RideFeelResponse? feel;
  final Future<bool> Function(int rpe, String? notes) onSave;
  final Future<bool> Function() onDelete;
  final bool saving;

  @override
  State<RideFeelCard> createState() => _RideFeelCardState();
}

class _RideFeelCardState extends State<RideFeelCard> {
  late final TextEditingController _notes = TextEditingController(
    text: widget.feel?.notes ?? '',
  );
  int? _rpe;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _rpe = widget.feel?.rpe;
  }

  @override
  void didUpdateWidget(RideFeelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.feel?.rpe != widget.feel?.rpe) {
      _rpe = widget.feel?.rpe;
      _notes.text = widget.feel?.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rpe == null) return;
    final notes = _notes.text.trim();
    final ok = await widget.onSave(_rpe!, notes.isEmpty ? null : notes);
    if (ok && mounted) setState(() => _editing = false);
  }

  Future<void> _delete() async {
    final ok = await widget.onDelete();
    if (ok && mounted) {
      setState(() {
        _editing = false;
        _rpe = null;
        _notes.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final feel = widget.feel;
    if (feel == null) return const SizedBox.shrink();

    if (feel.consentRequired) {
      return Card(
        key: const Key('ride-feel-card'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(l10n.wellbeingConsentNeeded, style: text.bodySmall),
        ),
      );
    }

    final showForm = _editing || feel.rpe == null;
    return Card(
      key: const Key('ride-feel-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.wellbeingRpe, style: text.titleMedium),
                ),
                if (!showForm && feel.rpe != null)
                  TextButton(
                    key: const Key('ride-feel-edit'),
                    onPressed: () => setState(() => _editing = true),
                    child: Text(l10n.wellbeingEdit),
                  ),
              ],
            ),
            if (!showForm && feel.rpe != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.wellbeingRpeSaved(feel.rpe!),
                key: const Key('ride-feel-saved'),
                style: text.titleSmall,
              ),
              if (feel.notes case final notes? when notes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(notes, style: text.bodySmall),
              ],
            ] else ...[
              Text(l10n.wellbeingRpeHint, style: text.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 1; i <= 10; i++)
                    ChoiceChip(
                      key: Key('ride-feel-$i'),
                      label: Text('$i'),
                      selected: _rpe == i,
                      onSelected: widget.saving
                          ? null
                          : (_) => setState(() => _rpe = i),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('ride-feel-notes'),
                controller: _notes,
                maxLength: 500,
                maxLines: 2,
                decoration: InputDecoration(labelText: l10n.wellbeingNotes),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  FilledButton(
                    key: const Key('ride-feel-save'),
                    onPressed: widget.saving || _rpe == null ? null : _save,
                    child: Text(l10n.wellbeingRpeSave),
                  ),
                  if (feel.rpe != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    TextButton(
                      onPressed: widget.saving ? null : _delete,
                      child: Text(l10n.wellbeingRpeDelete),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() {
                        _editing = false;
                        _rpe = feel.rpe;
                        _notes.text = feel.notes ?? '';
                      }),
                      child: Text(l10n.cancel),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
