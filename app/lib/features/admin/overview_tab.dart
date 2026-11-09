import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import 'admin_view_models.dart';

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
            ? const CircularProgressIndicator()
            : Text(
                s.load.failure == null
                    ? l10n.noOverview
                    : failureText(l10n, s.load.failure!),
              ),
      );
    }
    Widget tile(String key, String label, String value) => Card(
      child: ListTile(
        key: Key(key),
        title: Text(label),
        trailing: Text(value, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                tile('overview-accounts', l10n.adminAccounts, '${o.accounts}'),
                tile(
                  'overview-waiting',
                  l10n.waitingForApproval,
                  '${o.waitingForApproval}',
                ),
                tile('overview-locked', l10n.locked, '${o.locked}'),
                tile('overview-rides', l10n.navRides, '${o.rides}'),
                tile(
                  'overview-storage',
                  l10n.rideFilesOnDisk,
                  bytes(o.rideFilesBytes),
                ),
                tile('overview-version', l10n.serverVersion, o.version),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
