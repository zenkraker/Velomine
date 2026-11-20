import 'package:material_ui/material_ui.dart';

import '../tokens.dart';
import 'app_card.dart';

/// A titled group of rows and fields, with one left edge for everything inside.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.description,
    this.menu,
    required this.children,
  });

  final String title;

  /// A line under the title, for what the whole group is for.
  final String? description;

  /// A [PageMenu] at the end of the title row, for the card's rare or destructive actions.
  final Widget? menu;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: text.titleMedium)),
              // The menu's tap area hangs over the card's padding, so it sits at the card's edge.
              if (menu case final menu?)
                Transform.translate(
                  offset: const Offset(AppSpacing.md, 0),
                  child: menu,
                ),
            ],
          ),
          if (description case final description?)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                description,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          for (final child in children)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: child,
            ),
        ],
      ),
    );
  }
}
