import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import 'admin_view_models.dart';
import '../../core/tokens.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/section_card.dart';

/// Totals for the whole server. Counts only: an admin never sees whose rides they are.
class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(adminOverviewViewModelProvider);
    final l10n = context.l10n;
    final o = s.load.value;
    if (o == null) {
      return Center(
        child: s.load.running
            ? const LoadingState()
            : ErrorState(
                message: s.load.failure == null
                    ? l10n.noOverview
                    : failureText(l10n, s.load.failure!),
                onRetry: () =>
                    ref.read(adminOverviewViewModelProvider.notifier).refresh(),
                actionKey: const Key('overview-retry'),
              ),
      );
    }
    Widget tile(String key, String label, String value) => ListTile(
      key: Key(key),
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.titleLarge),
    );
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
      children: [
        SectionCard(
          title: l10n.adminPeopleAndRides,
          children: [
            tile('overview-accounts', l10n.adminAccounts, '${o.accounts}'),
            tile(
              'overview-waiting',
              l10n.waitingForApproval,
              '${o.waitingForApproval}',
            ),
            tile('overview-locked', l10n.locked, '${o.locked}'),
            tile('overview-rides', l10n.navRides, '${o.rides}'),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: l10n.adminServer,
          children: [
            tile(
              'overview-storage',
              l10n.rideFilesOnDisk,
              bytes(o.rideFilesBytes),
            ),
            tile('overview-version', l10n.serverVersion, o.version),
            tile(
              'overview-parser-version',
              l10n.rideReaderVersion,
              '${o.parserVersion}',
            ),
            tile('overview-reread', l10n.ridesToReread, '${o.ridesToReread}'),
            tile(
              'overview-not-reread',
              l10n.ridesNotReread,
              '${o.ridesNotReread}',
            ),
          ],
        ),
      ],
    );
  }
}
