import '../../../core/widgets/loading_state.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../../core/failure.dart';
import '../../../core/l10n.dart';
import '../../../core/theme.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/section_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'import_view_model.dart';

String importErrorText(AppLocalizations l10n, String? code) => switch (code) {
  'not_a_strava_export' => l10n.importErrorNotStrava,
  'archive_missing' => l10n.importErrorMissing,
  _ => l10n.importErrorUnknown,
};

/// The progress of one import, then what it brought in.
class ImportScreen extends ConsumerWidget {
  const ImportScreen({super.key, required this.id, required this.onDone});

  final String id;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(importViewModelProvider(id));
    final status = state.load.value;

    return PageScaffold(
      parent: l10n.navRides,
      title: l10n.importTitle,
      maxWidth: AppLayout.contentNarrow,
      children: [
        if (state.load.failure case final failure?)
          ErrorState(
            message: failureText(l10n, failure),
            actionKey: const Key('import-error'),
            onRetry: ref.read(importViewModelProvider(id).notifier).retry,
          )
        else if (status == null)
          const LoadingState()
        else
          _Status(status: status, onDone: onDone),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.status, required this.onDone});

  final RideImportResponse status;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final processing = status.status == 'processing';
    final done =
        status.imported + status.duplicates + status.failed + status.skipped;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    // One outcome, as the mock-up draws it: a glyph, then what it says.
    Widget outcome(String key, IconData icon, String label, {Color? color}) =>
        Row(
          key: Key(key),
          spacing: AppSpacing.md,
          children: [
            Icon(icon, color: color ?? scheme.onSurfaceVariant),
            Expanded(child: Text(label, style: text.bodyLarge)),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        SectionCard(
          key: const Key('import-status'),
          // The card's own title, not the page's: it says what is happening, as the mock-up has it.
          title: processing ? l10n.importRunning : l10n.importFinished,
          children: [
            if (status.total > 0)
              // The count read of the total is the card's number, its unit under it.
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$done',
                      style: VelomineText.of(context).kpi,
                    ),
                    TextSpan(
                      text: ' ${l10n.importProgressUnit(status.total)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                key: const Key('import-progress'),
              ),
            if (processing)
              LinearProgressIndicator(
                value: status.total == 0
                    ? null
                    : (done / status.total).clamp(0.0, 1.0),
              ),
            // What came of them, from the first file on: the mock-up's rows are there while the archive
            // is still being read, so the import shows its work instead of only its ending.
            if (status.imported > 0)
              outcome(
                'import-imported',
                Icons.check,
                l10n.importSummaryImported(status.imported),
              ),
            if (status.duplicates > 0)
              outcome(
                'import-duplicates',
                Icons.copy_all_outlined,
                l10n.importSummaryDuplicates(status.duplicates),
              ),
            if (status.failed > 0)
              outcome(
                'import-failed',
                Icons.description_outlined,
                l10n.importSummaryFailed(status.failed),
                color: scheme.error,
              ),
            if (status.skipped > 0)
              outcome(
                'import-skipped',
                Icons.skip_next_outlined,
                l10n.importSummarySkipped(status.skipped),
              ),
            if (status.status == 'failed')
              outcome(
                'import-failure',
                Icons.error_outline,
                importErrorText(l10n, status.error),
                color: scheme.error,
              ),
          ],
        ),
        // The quiet way out, under the card, as the mock-up draws it.
        if (!processing)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton(
              key: const Key('import-back'),
              onPressed: onDone,
              child: Text(l10n.importBackToRides),
            ),
          ),
      ],
    );
  }
}
