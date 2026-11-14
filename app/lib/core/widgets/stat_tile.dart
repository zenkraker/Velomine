import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// One number with the name of what it counts, so a row of them reads as a table.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.valueKey,
    this.boxed = false,
  });

  final String label;
  final String value;

  /// A key on the number alone, for a test that reads it.
  final Key? valueKey;

  /// A surface behind the tile, for a grid of numbers rather than a row.
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(
          label,
          style: text.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, key: valueKey, style: text.titleSmall),
      ],
    );
    if (!boxed) return column;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: column,
    );
  }
}

/// The gap a row of [StatTile]s uses, so every row of numbers wraps the same way.
const statRowSpacing = AppSpacing.md;
