import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// A titled group of rows and fields, with one left edge for everything inside.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.description,
    required this.children,
  });

  final String title;

  /// A line under the title, for what the whole group is for.
  final String? description;
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(title, style: text.titleMedium),
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
