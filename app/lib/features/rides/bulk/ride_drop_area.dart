import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/tokens.dart';
import 'bulk_upload_state.dart';
import 'bulk_upload_view_model.dart';

/// Wraps the whole web app so a folder or ride files can be dropped on any page.
///
/// It shows a clear target while files are being dragged, says plainly when a drop cannot be used, and calls
/// [onStarted] when a drop begins so the app can bring the progress into view.
class RideDropArea extends ConsumerWidget {
  const RideDropArea({super.key, required this.onStarted, required this.child});

  final VoidCallback onStarted;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kIsWeb) return child;
    final l10n = context.l10n;

    ref.listen(bulkUploadViewModelProvider.select((s) => s.notice), (_, notice) {
      if (notice == null) return;
      final text = switch (notice) {
        BulkNotice.signedOut => l10n.bulkSignedOut,
        BulkNotice.nothingUsable => l10n.bulkNothing,
      };
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(text, key: const Key('bulk-notice'))),
      );
      ref.read(bulkUploadViewModelProvider.notifier).noticeShown();
    });
    ref.listen(bulkUploadViewModelProvider.select((s) => s.phase), (
      before,
      phase,
    ) {
      if (before == BulkPhase.idle && phase == BulkPhase.scanning) onStarted();
    });

    final dragging = ref.watch(
      bulkUploadViewModelProvider.select((s) => s.dragging),
    );
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        if (dragging)
          const Positioned.fill(
            child: IgnorePointer(child: _DropTarget()),
          ),
      ],
    );
  }
}

class _DropTarget extends StatelessWidget {
  const _DropTarget();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Material(
      key: const Key('bulk-drop-target'),
      color: scheme.surface.withValues(alpha: 0.88),
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.primary, width: 3),
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Center(
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.sm,
              children: [
                Icon(Icons.file_download_outlined, size: 48, color: scheme.primary),
                Text(
                  l10n.bulkDropTitle,
                  style: text.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                Text(
                  l10n.bulkDropHint,
                  style: text.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
