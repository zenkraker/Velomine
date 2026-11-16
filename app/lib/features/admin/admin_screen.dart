import 'package:material_ui/material_ui.dart';

import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/widgets/page_scaffold.dart';
import 'accounts_tab.dart';
import 'clubs_tab.dart';
import 'overview_tab.dart';
import 'settings_tab.dart';

/// The admin pages: accounts, clubs, settings and an overview of the server.
///
/// The tabs sit under the page header and the selected tab's content is laid out in the page's own
/// scroll, so each tab is built as a list that takes the height of its children.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: PageScaffold(
      title: context.l10n.navAdmin,
      maxWidth: AppLayout.contentMax,
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
        const _SelectedTab(),
      ],
    ),
  );
}

/// The content of the tab that is selected, swapped as the tab changes.
class _SelectedTab extends StatelessWidget {
  const _SelectedTab();

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => switch (controller.index) {
        0 => const AccountsTab(),
        1 => const ClubsTab(),
        2 => const SettingsTab(),
        _ => const OverviewTab(),
      },
    );
  }
}
