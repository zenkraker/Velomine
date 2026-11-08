import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import 'accounts_tab.dart';
import 'admin_controller.dart';
import 'overview_tab.dart';
import 'settings_tab.dart';

/// The admin pages: accounts, settings and an overview of the server.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, required this.controller});

  final AdminController controller;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.refresh();
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Column(
      children: [
        TabBar(
          tabs: [
            Tab(
              key: const Key('tab-accounts'),
              text: context.l10n.adminAccounts,
            ),
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
        Expanded(
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) => TabBarView(
              children: [
                AccountsTab(controller: widget.controller),
                SettingsTab(controller: widget.controller),
                OverviewTab(controller: widget.controller),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
