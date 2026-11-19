import 'package:material_ui/material_ui.dart';

import '../../core/l10n.dart';
import '../../core/tokens.dart';

/// What a ride did to a heart-rate number: measured it (a note, no buttons) or
/// suggests it (the rider decides). The ride's page and the progress page show
/// the same card; [suggestionId] is null when there is nothing to answer.
class HeartRateNoteCard extends StatelessWidget {
  const HeartRateNoteCard({
    super.key,
    required this.kind,
    required this.bpm,
    this.currentBpm,
    this.suggestionId,
    this.busy = false,
    this.onAccept,
    this.onDismiss,
  });

  /// `max` or `threshold`: the number the ride changed.
  final String kind;

  /// The measured or suggested value.
  final int bpm;

  /// The value the rider typed, for a suggestion's "above the {current} you set" and "Keep {current}".
  final int? currentBpm;

  /// The suggestion to accept or dismiss; null when the value was measured and used.
  final String? suggestionId;

  final bool busy;

  final void Function(String suggestionId)? onAccept;
  final void Function(String suggestionId)? onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final suggested = suggestionId != null;
    final body = suggested
        ? l10n.heartRateSuggested(bpm, currentBpm ?? bpm)
        : kind == 'max'
        ? l10n.heartRateMaxMeasured(bpm)
        : l10n.heartRateThresholdMeasured(bpm);
    return Card(
      key: Key('heart-rate-note-$kind'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Text(body, style: text.titleMedium),
            if (suggestionId case final id?) ...[
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (onAccept != null)
                    FilledButton(
                      key: const Key('heart-rate-note-use'),
                      onPressed: busy ? null : () => onAccept!(id),
                      child: Text(l10n.heartRateSuggestionUse(bpm)),
                    ),
                  TextButton(
                    key: const Key('heart-rate-note-keep'),
                    onPressed: busy ? null : () => onDismiss?.call(id),
                    child: Text(
                      l10n.heartRateSuggestionKeep(currentBpm ?? bpm),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
