import 'package:material_ui/material_ui.dart';

import '../l10n.dart';

/// One row of a [PageMenu]. A destructive entry is drawn last, after a divider, in the error colour.
class PageMenuEntry {
  const PageMenuEntry({
    required this.key,
    required this.label,
    required this.onSelected,
    this.icon,
    this.destructive = false,
  });

  final Key key;
  final String label;
  final IconData? icon;
  final VoidCallback onSelected;
  final bool destructive;
}

/// The `⋯` menu of a page: rare and dangerous actions in one predictable place.
class PageMenu extends StatelessWidget {
  const PageMenu({
    super.key,
    required this.entries,
    this.buttonKey,
    this.badge = false,
  });

  final List<PageMenuEntry> entries;
  final Key? buttonKey;

  /// Shows a dot on the button, for example when a filter is on.
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    final normal = entries.where((e) => !e.destructive).toList();
    final destructive = entries.where((e) => e.destructive).toList();

    MenuItemButton item(PageMenuEntry e) {
      final color = e.destructive ? error : null;
      return MenuItemButton(
        key: e.key,
        leadingIcon: e.icon == null ? null : Icon(e.icon, color: color),
        style: color == null
            ? null
            : MenuItemButton.styleFrom(foregroundColor: color),
        onPressed: e.onSelected,
        child: Text(e.label),
      );
    }

    final tooltip = context.l10n.moreActions;
    return MenuAnchor(
      menuChildren: [
        ...normal.map(item),
        if (normal.isNotEmpty && destructive.isNotEmpty) const Divider(),
        ...destructive.map(item),
      ],
      builder: (context, controller, _) => IconButton(
        key: buttonKey,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: Badge(
          isLabelVisible: badge,
          smallSize: 8,
          child: Icon(
            Icons.more_vert,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
