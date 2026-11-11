import 'package:flutter/material.dart';

import '../tokens.dart';

/// What a list says when it has nothing to show: one line, centred, with room around it.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.xl,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: [
        if (icon != null)
          Icon(
            icon,
            size: 32,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}
