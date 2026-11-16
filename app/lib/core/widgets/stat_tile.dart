import 'package:material_ui/material_ui.dart';

import '../tokens.dart';
import 'eyebrow.dart';

/// One number with the name of what it counts, so a row of them reads as a table.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.valueKey,
    this.boxed = false,
    this.headline = false,
    this.detail,
  });

  final String label;
  final String value;

  /// A key on the number alone, for a test that reads it.
  final Key? valueKey;

  /// A surface behind the tile, for a grid of numbers rather than a row.
  final bool boxed;

  /// A dashboard number: an uppercase [Eyebrow] label over a large value, filling the width it is given.
  final bool headline;

  /// A line under the number, for what it means.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs / 2,
      children: [
        if (headline)
          Eyebrow(label)
        else
          Text(
            label,
            style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        Text(
          value,
          key: valueKey,
          style: headline
              ? text.headlineMedium?.copyWith(fontWeight: FontWeight.w400)
              : text.titleSmall,
        ),
        if (detail case final detail?)
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
      ],
    );
    if (!boxed) return column;
    return Container(
      width: headline ? null : AppStat.boxWidth,
      padding: EdgeInsets.all(headline ? AppSpacing.lg : AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: column,
    );
  }
}

/// The gap a row of [StatTile]s uses, so every row of numbers wraps the same way.
const statRowSpacing = AppSpacing.md;
