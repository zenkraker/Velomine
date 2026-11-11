import 'package:flutter/material.dart';

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
    child: Column(
      children: [
        TabBar(
          // Four labels fit 320 dp only with a tighter label padding; scrolling hid one at rest.
          labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
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
            children: [AccountsTab(), ClubsTab(), SettingsTab(), OverviewTab()],
          ),
        ),
      ],
    ),
  );
}
