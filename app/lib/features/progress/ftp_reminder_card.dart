import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/form_sheet.dart';

/// The FTP may be out of date, and here is the way out: adopt the estimate, read how to test it, or be
/// left alone for two weeks. The server says why, so the card only says it in words.
class FtpReminderCard extends StatelessWidget {
  const FtpReminderCard({
    super.key,
    required this.check,
    this.busy = false,
    this.onUseEstimate,
    this.onSnooze,
  });

  final FtpCheckResponse check;
  final bool busy;

  /// Null while there is no estimate to adopt.
  final void Function(int watts)? onUseEstimate;
  final VoidCallback? onSnooze;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final estimate = check.estimateW;
    // Only called with a reason, so "missing" is the one left over.
    final title = switch (check.reason) {
      'stale' => l10n.ftpReminderStaleTitle(
        ((check.ftpAgeDays ?? 0) / 7).floor(),
      ),
      'estimate_higher' => l10n.ftpReminderEstimateTitle,
      _ => l10n.ftpReminderMissingTitle,
    };
    final body = switch (check.reason) {
      'stale' => l10n.ftpReminderStaleBody,
      'estimate_higher' => l10n.ftpReminderEstimateBody(
        '${estimate ?? '–'}',
        '${check.ftpW ?? '–'}',
      ),
      _ => l10n.ftpReminderMissingBody('${estimate ?? '–'}'),
    };

    return AppCard(
      key: const Key('ftp-reminder'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Text(title, style: text.titleMedium),
          Text(body, style: text.bodyMedium),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (estimate != null && onUseEstimate != null)
                FilledButton(
                  key: const Key('ftp-reminder-use'),
                  onPressed: busy ? null : () => onUseEstimate!(estimate),
                  child: Text(l10n.ftpUse(estimate)),
                ),
              TextButton(
                key: const Key('ftp-reminder-how'),
                onPressed: () => showSheet<void>(
                  context,
                  builder: (_) => const _HowToTestSheet(),
                ),
                child: Text(l10n.ftpReminderHow),
              ),
              TextButton(
                key: const Key('ftp-reminder-not-now'),
                onPressed: busy ? null : onSnooze,
                child: Text(l10n.ftpReminderNotNow),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The one test protocol Pack 1 offers; the server notices the effort and suggests the new FTP.
class _HowToTestSheet extends StatelessWidget {
  const _HowToTestSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SheetFrame(
      title: l10n.ftpReminderHow,
      children: [
        Text(
          l10n.ftpReminderHowBody,
          key: const Key('ftp-reminder-how-body'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
