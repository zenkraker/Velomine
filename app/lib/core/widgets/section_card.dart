import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

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
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            if (menu == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(title, style: text.titleMedium),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(child: Text(title, style: text.titleMedium)),
                    menu!,
                  ],
                ),
              ),
            if (description != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(description!, style: text.bodySmall),
              ),
            // Rows bring their own vertical rhythm; the card only fixes the left and right edge.
            for (final child in children)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}
