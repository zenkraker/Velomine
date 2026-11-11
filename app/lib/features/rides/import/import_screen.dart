import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../../core/failure.dart';
import '../../../core/l10n.dart';
import '../../../core/tokens.dart';
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

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (state.load.failure case final failure?)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                failureText(l10n, failure),
                key: const Key('import-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              TextButton(
                onPressed: ref.read(importViewModelProvider(id).notifier).retry,
                child: Text(l10n.retry),
              ),
            ],
          )
        else if (status == null)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          )
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

    return SectionCard(
      title: l10n.importTitle,
      description: processing ? l10n.importRunning : l10n.importFinished,
      children: [
        if (processing) ...[
          LinearProgressIndicator(
            value: status.total == 0
                ? null
                : (done / status.total).clamp(0.0, 1.0),
          ),
          if (status.total > 0) Text(l10n.importProgress(done, status.total)),
        ],
        if (!processing) ...[
          Text(
            l10n.importSummaryImported(status.imported),
            key: const Key('import-imported'),
          ),
          if (status.duplicates > 0)
            Text(l10n.importSummaryDuplicates(status.duplicates)),
          if (status.failed > 0) Text(l10n.importSummaryFailed(status.failed)),
          if (status.skipped > 0)
            Text(l10n.importSummarySkipped(status.skipped)),
          if (status.status == 'failed')
            Text(
              importErrorText(l10n, status.error),
              key: const Key('import-failure'),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const Key('import-back'),
              onPressed: onDone,
              child: Text(l10n.importBackToRides),
            ),
          ),
        ],
      ],
    );
  }
}
