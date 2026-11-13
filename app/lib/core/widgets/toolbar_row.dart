import 'package:flutter/material.dart';

import '../tokens.dart';

/// A row of filters or actions that wraps instead of clipping: a phone at a large text size
/// gets a second line, never a scroller.
class ToolbarRow extends StatelessWidget {
  const ToolbarRow({super.key, required this.children, this.alignment});

  final List<Widget> children;

  /// Where the row sits when it is narrower than the page; left by default.
  final WrapAlignment? alignment;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: alignment ?? WrapAlignment.start,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: children,
  );
}
