import 'package:flutter/material.dart';

import '../tokens.dart';

/// Cards in a grid that uses the window's width: [columns] across from a desktop window, one under
/// the other on anything narrower. A card decides its own height; a short one leaves the room to its
/// neighbour.
class CardGrid extends StatelessWidget {
  const CardGrid({
    super.key,
    required this.children,
    this.columns = 2,
    this.hero = 0,
  });

  final List<Widget> children;

  /// How many cards across a wider row's first cell takes; 0 for none. A dashboard's main card reads
  /// first and larger, and the others sit beside it.
  final int hero;

  /// How many cards a desktop window shows; below [AppBreakpoint.expandedWidth] there is always one.
  final int columns;

  static const double _gap = AppSpacing.lg;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final count =
          MediaQuery.sizeOf(context).width >= AppBreakpoint.expandedWidth
          ? columns
          : 1;
      if (count == 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: _gap,
          children: children,
        );
      }
      final width = (constraints.maxWidth - _gap * (count - 1)) / count;
      final heroSpan = hero.clamp(0, count);
      return Wrap(
        spacing: _gap,
        runSpacing: _gap,
        children: [
          for (final (i, child) in children.indexed)
            SizedBox(
              width: i == 0 && heroSpan > 0
                  ? width * heroSpan + _gap * (heroSpan - 1)
                  : width,
              child: child,
            ),
        ],
      );
    },
  );
}
