import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/widgets/chip_row.dart';
import '../../core/widgets/page_scaffold.dart';
import 'accounts_tab.dart';
import 'clubs_tab.dart';
import 'overview_tab.dart';
import 'settings_tab.dart';

/// The admin pages: an overview of the server, the accounts, the clubs and the settings.
///
/// The four areas are one segmented choice under the page title, and the chosen one's content is built
/// into the page's own scroll.
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabs = [
      (key: const Key('tab-overview'), label: l10n.adminOverview),
      (key: const Key('tab-accounts'), label: l10n.adminAccounts),
      (key: const Key('tab-clubs'), label: l10n.adminClubs),
      (key: const Key('tab-settings'), label: l10n.adminSettings),
    ];
    return PageScaffold(
      title: l10n.navAdmin,
      subtitle: switch (_tab) {
        1 => l10n.adminAccountsSubtitle,
        2 => l10n.adminClubsSubtitle,
        3 => l10n.adminSettingsSubtitle,
        _ => l10n.adminOverviewSubtitle,
      },
      maxWidth: AppLayout.contentMax,
      // Creating a club is this page's one main action, and only the clubs area has one.
      // Its words stay on the pill at every width, as the controls guide asks.
      primaryAction: _tab != 2
          ? null
          : FilledButton.icon(
              key: const Key('create-club'),
              onPressed: () => showCreateClubSheet(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.adminCreateClub),
            ),
      // The settings area is one form, so its Save is pinned under the content.
      bottomAction: _tab == 3 ? const AdminSettingsSave() : null,
      children: [
        // Chips in one row that scrolls sideways, as the admin pages draw them (`.vm-chips`): a
        // segmented track stretched across the whole window instead of sitting in its corner.
        ChipRow(
          rowKey: const Key('admin-tabs'),
          selected: _tab,
          chips: [
            for (final (i, tab) in tabs.indexed)
              ChoiceChip(
                key: tab.key,
                label: Text(tab.label),
                selected: _tab == i,
                onSelected: (_) => setState(() => _tab = i),
              ),
          ],
        ),
        switch (_tab) {
          1 => const AccountsTab(),
          2 => const ClubsTab(),
          3 => const SettingsTab(),
          _ => const OverviewTab(),
        },
      ],
    );
  }
}
