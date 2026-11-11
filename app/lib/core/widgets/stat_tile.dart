import 'package:flutter/material.dart';

import '../tokens.dart';

/// One number with the name of what it counts, so a row of them reads as a table.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(
          label,
          style: text.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: text.titleSmall),
      ],
    );
  }
}

/// The gap a row of [StatTile]s uses, so every row of numbers wraps the same way.
const statRowSpacing = AppSpacing.md;
