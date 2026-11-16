import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/l10n.dart';
import '../../core/widgets/page_menu.dart';

/// The `⋯` at the end of a row: one destructive Remove entry that keeps the row's own [removeKey].
/// The entry opens a confirmation, so it waits for the menu to close first.
class RowRemoveMenu extends StatelessWidget {
  const RowRemoveMenu({
    super.key,
    required this.menuKey,
    required this.removeKey,
    required this.onRemove,
  });

  final Key menuKey;
  final Key removeKey;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => PageMenu(
    buttonKey: menuKey,
    entries: [
      PageMenuEntry(
        key: removeKey,
        icon: Icons.delete_outline,
        label: context.l10n.remove,
        destructive: true,
        onSelected: () => scheduleMicrotask(() {
          if (context.mounted) onRemove();
        }),
      ),
    ],
  );
}
