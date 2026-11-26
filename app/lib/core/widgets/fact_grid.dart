import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../tokens.dart';

/// Named numbers on a list card, as the mock-ups draw them: columns at least [AppFacts.minColumn] wide
/// that fill the card, each a `caption` name over a body-weight number. A bigger number a page leads
/// with is a [StatFigure]; a card in a list is read as a table of these.
class FactGrid extends StatelessWidget {
  const FactGrid({super.key, required this.facts});

  /// The name and the number of each fact, in reading order.
  final List<(String, String)> facts;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.lg;
        final columns =
            ((constraints.maxWidth + gap) / (AppFacts.minColumn + gap))
                .floor()
                .clamp(1, facts.isEmpty ? 1 : facts.length);
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (label, value) in facts)
              SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      value,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
