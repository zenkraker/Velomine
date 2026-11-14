import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/section_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../rides_screen.dart' show rideErrorText;
import 'bulk_upload_runner.dart';
import 'bulk_upload_state.dart';
import 'bulk_upload_view_model.dart';

/// Why a file in a bulk drop could not be read, in the language on screen.
String bulkReasonText(AppLocalizations l10n, String? code) => switch (code) {
  'offline' => l10n.failureUnreachable,
  'sign_in' => l10n.failureSessionEnded,
  'too_many' => l10n.failureTooMany,
  _ => rideErrorText(l10n, code),
};

/// The names of unreadable files shown at most; the rest are counted.
const _shownFailures = 20;

/// The progress of a folder being read, then one summary of how it went.
class BulkUploadCard extends ConsumerWidget {
  const BulkUploadCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bulkUploadViewModelProvider);
    if (state.phase == BulkPhase.idle) return const SizedBox.shrink();
    final l10n = context.l10n;
    final model = ref.read(bulkUploadViewModelProvider.notifier);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SectionCard(
        title: l10n.bulkTitle,
        description: switch (state.phase) {
          BulkPhase.scanning => l10n.bulkScanning,
          BulkPhase.running => null,
          _ =>
            (state.summary?.cancelled ?? false)
                ? l10n.bulkStopped
                : l10n.bulkDone,
        },
        children: [
          if (state.phase == BulkPhase.scanning)
            const LinearProgressIndicator(),
          if (state.phase == BulkPhase.running) ..._running(l10n, state, model),
          if (state.phase == BulkPhase.done && state.summary != null)
            ..._summary(context, l10n, state.summary!, model),
        ],
      ),
    );
  }

  List<Widget> _running(
    AppLocalizations l10n,
    BulkUploadState state,
    BulkUploadViewModel model,
  ) => [
    Semantics(
      liveRegion: true,
      child: Text(
        l10n.bulkProgress(state.completed, state.total),
        key: const Key('bulk-progress'),
      ),
    ),
    LinearProgressIndicator(
      value: state.total == 0 ? null : state.completed / state.total,
    ),
    if (state.waiting) Text(l10n.bulkWaiting, key: const Key('bulk-waiting')),
    Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        key: const Key('bulk-cancel'),
        onPressed: state.cancelling ? null : model.cancel,
        child: Text(state.cancelling ? l10n.bulkStopping : l10n.bulkCancel),
      ),
    ),
  ];

  List<Widget> _summary(
    BuildContext context,
    AppLocalizations l10n,
    BulkSummary summary,
    BulkUploadViewModel model,
  ) {
    final failures = summary.unreadable;
    return [
      Text(l10n.bulkAdded(summary.added), key: const Key('bulk-added')),
      Text(
        l10n.bulkAlreadyHere(summary.alreadyHere),
        key: const Key('bulk-already-here'),
      ),
      if (failures.isNotEmpty) ...[
        Text(
          l10n.bulkUnreadable(failures.length),
          key: const Key('bulk-unreadable'),
        ),
        // A big folder can have many; the box scrolls instead of pushing the rides off the screen.
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final failure in failures.take(_shownFailures))
                Text(
                  '${failure.name}: ${bulkReasonText(l10n, failure.error)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (failures.length > _shownFailures)
                Text(l10n.bulkAndMore(failures.length - _shownFailures)),
            ],
          ),
        ),
      ],
      if (summary.skipped > 0)
        Text(l10n.bulkSkipped(summary.skipped), key: const Key('bulk-skipped')),
      if (summary.notRead > 0)
        Text(
          l10n.bulkNotRead(summary.notRead),
          key: const Key('bulk-not-read'),
        ),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          key: const Key('bulk-close'),
          onPressed: model.dismiss,
          child: Text(l10n.bulkClose),
        ),
      ),
    ];
  }
}
