import 'package:flutter/material.dart';

import '../../core/format.dart';
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
            : Text(controller.error ?? 'No overview.'),
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
                tile('overview-accounts', 'Accounts', '${o.accounts}'),
                tile(
                  'overview-waiting',
                  'Waiting for approval',
                  '${o.waitingForApproval}',
                ),
                tile('overview-locked', 'Locked', '${o.locked}'),
                tile('overview-rides', 'Rides', '${o.rides}'),
                tile(
                  'overview-storage',
                  'Ride files on disk',
                  bytes(o.rideFilesBytes),
                ),
                tile('overview-version', 'Server version', o.version),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
