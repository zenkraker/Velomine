import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/l10n.dart';
import '../../core/widgets/page_menu.dart';

/// The `⋯` at the end of a row: the row's own actions from [actions], then one destructive Remove that
/// keeps the row's own [removeKey]. An entry opens a sheet or asks a question, so it runs after the menu
/// has closed.
class RowActionMenu extends StatelessWidget {
  const RowActionMenu({
    super.key,
    required this.menuKey,
    required this.removeKey,
    required this.onRemove,
    this.actions = const [],
  });

  final Key menuKey;
  final Key removeKey;
  final VoidCallback onRemove;

  /// The row's own jobs, before the remove: Edit, Replace, Pause, and so on.
  final List<PageMenuEntry> actions;

  static void _later(VoidCallback run) => scheduleMicrotask(run);

  @override
  Widget build(BuildContext context) => PageMenu(
    buttonKey: menuKey,
    entries: [
      for (final entry in actions)
        PageMenuEntry(
          key: entry.key,
          label: entry.label,
          icon: entry.icon,
          onSelected: () => _later(entry.onSelected),
        ),
      PageMenuEntry(
        key: removeKey,
        icon: Icons.delete_outline,
        label: context.l10n.remove,
        destructive: true,
        onSelected: () => _later(onRemove),
      ),
    ],
  );
}
