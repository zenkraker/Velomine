import 'package:flutter/material.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import 'admin_controller.dart';

/// Totals for the whole server. Counts only: an admin never sees whose rides they are.
class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, required this.controller});

  final AdminController controller;

  @override
  Widget build(BuildContext context) {
    final o = controller.overview;
    if (o == null) {
      return Center(
        child: controller.loading
            ? const CircularProgressIndicator()
            : Text(
                controller.error == null
                    ? context.l10n.noOverview
                    : failureText(context.l10n, controller.error!),
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
    final l10n = context.l10n;
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
