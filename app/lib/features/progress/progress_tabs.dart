import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/widgets/chip_row.dart';

/// One Progress page as the tabs show it: its route, its name and the key a test finds it by.
typedef ProgressTab = ({String path, String label, Key key});

/// The five Progress pages, in the order the sidebar and the tabs show them.
List<ProgressTab> progressTabs(BuildContext context) {
  final l10n = context.l10n;
  return [
    (
      path: '/progress',
      label: l10n.navOverview,
      key: const Key('progress-tab-overview'),
    ),
    (
      path: '/progress/fitness',
      label: l10n.fitness,
      key: const Key('progress-tab-fitness'),
    ),
    (
      path: '/progress/power',
      label: l10n.metricPower,
      key: const Key('progress-tab-power'),
    ),
    (
      path: '/progress/totals',
      label: l10n.navTotals,
      key: const Key('progress-tab-totals'),
    ),
    (
      path: '/progress/wellbeing',
      label: l10n.wellbeing,
      key: const Key('progress-tab-wellbeing'),
    ),
  ];
}

/// The Progress sub-pages as chips in one row that scrolls sideways, under 600 dp only: a phone has
/// nowhere else to put them, while a wider window has the rail or the sidebar and a caption above the
/// title instead.
class ProgressTabs extends StatelessWidget {
  const ProgressTabs({super.key, required this.location});

  /// The route on screen: its chip is the chosen one.
  final String location;

  @override
  Widget build(BuildContext context) {
    final tabs = progressTabs(context);
    return ChipRow(
      selected: tabs.indexWhere((tab) => tab.path == location),
      chips: [
        for (final tab in tabs)
          ChoiceChip(
            key: tab.key,
            label: Text(tab.label),
            selected: location == tab.path,
            onSelected: (_) {
              if (location != tab.path) context.go(tab.path);
            },
          ),
      ],
    );
  }
}
