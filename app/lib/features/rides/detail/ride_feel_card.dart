import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../../core/l10n.dart';
import '../../../core/saved_mark_view_model.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';

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
  /// Read in initState: a save can finish after this card is gone, and the badge is app-level.
  late final ProviderContainer _container;

  final _notes = TextEditingController();
  final _notesFocus = FocusNode();
  int? _rpe;

  /// What the server holds, as this card last saw it: a save sends only what differs from it.
  int? _savedRpe;
  String? _savedNotes;

  /// Saves run one after another, so a save queued during another is sent after it, not dropped.
  Future<void> _saves = Future.value();
  bool _inFlight = false;

  @override
  void initState() {
    super.initState();
    _container = ProviderScope.containerOf(context, listen: false);
    _syncFromFeel();
    _notesFocus.addListener(_onNotesFocusChanged);
  }

  void _syncFromFeel() {
    _rpe = widget.feel?.rpe;
    _savedRpe = widget.feel?.rpe;
    _savedNotes = widget.feel?.notes;
    _notes.text = widget.feel?.notes ?? '';
  }

  @override
  void didUpdateWidget(RideFeelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A reload never overwrites what the member is typing or what is being sent.
    if (!_inFlight && !_notesFocus.hasFocus && oldWidget.feel != widget.feel) {
      _syncFromFeel();
    }
  }

  @override
  void dispose() {
    _notesFocus.removeListener(_onNotesFocusChanged);
    _notesFocus.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _onNotesFocusChanged() {
    if (!_notesFocus.hasFocus) _queueSave();
  }

  void _queueSave() => _saves = _saves.then((_) => _save());

  /// Sends the chosen RPE with the notes as they are. Nothing is sent before an RPE is chosen or when neither
  /// changed; a failed save keeps what the member typed and shows no mark.
  Future<void> _save() async {
    final rpe = _rpe;
    if (!mounted || rpe == null) return;
    final text = _notes.text.trim();
    final notes = text.isEmpty ? null : text;
    if (rpe == _savedRpe && notes == _savedNotes) return;
    _inFlight = true;
    final ok = await widget.onSave(rpe, notes);
    _inFlight = false;
    if (!mounted) return;
    if (ok) {
      _savedRpe = rpe;
      _savedNotes = notes;
    }
    _showSaved(ok);
  }

  /// Shows the "Saved." badge for a save that went through. A failed save hides it.
  void _showSaved(bool saved) {
    final badge = _container.read(savedMarkViewModelProvider.notifier);
    if (saved) {
      badge.show();
    } else {
      badge.hide();
    }
  }

  Future<void> _delete() async {
    final ok = await widget.onDelete();
    if (ok && mounted) {
      setState(() {
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
      return AppCard(
        key: const Key('ride-feel-card'),
        child: Text(l10n.wellbeingConsentNeeded, style: text.bodySmall),
      );
    }

    return AppCard(
      key: const Key('ride-feel-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.wellbeingRpe, style: text.titleMedium),
          Text(l10n.wellbeingRpeHint, style: text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (var i = 1; i <= 10; i++)
                ChoiceChip(
                  key: Key('ride-feel-$i'),
                  label: Text('$i'),
                  selected: _rpe == i,
                  onSelected: widget.saving
                      ? null
                      : (_) {
                          setState(() => _rpe = i);
                          _queueSave();
                        },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            fieldKey: const Key('ride-feel-notes'),
            controller: _notes,
            focusNode: _notesFocus,
            onDone: (_) => _queueSave(),
            maxLength: 500,
            maxLines: 2,
            label: l10n.wellbeingNotes,
          ),
          if (feel.rpe != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: widget.saving ? null : _delete,
                child: Text(l10n.wellbeingRpeDelete),
              ),
            ),
        ],
      ),
    );
  }
}
