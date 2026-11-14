import 'package:material_ui/material_ui.dart';

import '../../core/l10n.dart';
import '../../core/tokens.dart';
import 'accounts_tab.dart';
import 'clubs_tab.dart';
import 'overview_tab.dart';
import 'settings_tab.dart';

/// The admin pages: accounts, clubs, settings and an overview of the server.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    // The tabs and their content share one measure, so a tab label sits over the table it labels.
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.contentMax),
        child: Column(
          children: [
            TabBar(
              // Four labels fit 320 dp only with a tighter label padding; scrolling hid one at rest.
              labelPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
              ),
              tabs: [
                Tab(
                  key: const Key('tab-accounts'),
                  text: context.l10n.adminAccounts,
                ),
                Tab(key: const Key('tab-clubs'), text: context.l10n.adminClubs),
                Tab(
                  key: const Key('tab-settings'),
                  text: context.l10n.adminSettings,
                ),
                Tab(
                  key: const Key('tab-overview'),
                  text: context.l10n.adminOverview,
                ),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  AccountsTab(),
                  ClubsTab(),
                  SettingsTab(),
                  OverviewTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
