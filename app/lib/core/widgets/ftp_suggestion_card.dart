import 'package:material_ui/material_ui.dart';

import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../l10n/generated/app_localizations.dart';

/// An FTP a ride suggests, with the effort behind it and the two answers: use it, or let it go.
/// The ride's page and the progress page show the same card; [effortWatts] is null on a ride, whose own
/// page already says how long it was.
class FtpSuggestionCard extends StatelessWidget {
  const FtpSuggestionCard({
    super.key,
    required this.watts,
    required this.method,
    required this.suggestionId,
    this.effortWatts,
    this.busy = false,
    this.onAccept,
    this.onDismiss,
  });

  final int watts;

  /// `20min`, `30min` or `60min`: the effort the number came from.
  final String method;

  /// The suggestion to accept or dismiss; null when there is nothing to answer.
  final String? suggestionId;

  /// The ride's best for that effort, when the page did not come from the suggestion itself.
  final int? effortWatts;
  final bool busy;

  /// Null where there is nothing to adopt.
  final void Function(String suggestionId)? onAccept;
  final void Function(String suggestionId)? onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final shown = '$watts';
    return Card(
      key: const Key('ftp-suggestion'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Text(l10n.ftpSuggestionTitle(shown), style: text.titleMedium),
            Text(
              ftpSuggestionSourceText(l10n, method, effortWatts),
              style: text.bodyMedium,
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (suggestionId case final id?) ...[
                  if (onAccept != null)
                    FilledButton(
                      key: const Key('ftp-suggestion-use'),
                      onPressed: busy ? null : () => onAccept!(id),
                      child: Text(l10n.ftpSuggestionUse(shown)),
                    ),
                  TextButton(
                    key: const Key('ftp-suggestion-dismiss'),
                    onPressed: busy ? null : () => onDismiss?.call(id),
                    child: Text(l10n.ftpSuggestionDismiss),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Where the suggested number came from, in words: the effort it was worked out from.
String ftpSuggestionSourceText(
  AppLocalizations l10n,
  String method,
  int? effortWatts,
) {
  final effort = '${effortWatts ?? '–'}';
  return switch (method) {
    '30min' => l10n.ftpSuggestionMethod30(effort),
    '60min' => l10n.ftpSuggestionMethod60,
    _ => l10n.ftpSuggestionMethod20(effort),
  };
}
