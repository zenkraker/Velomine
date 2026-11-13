import 'package:flutter/material.dart';

import '../tokens.dart';

/// A heading between the groups of a page, with the action that adds to the group.
class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.action});

  final String title;

  /// The button that adds to the group, right of the title.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final heading = Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
    final action = this.action;
    if (action == null) return heading;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [heading, action],
    );
  }
}
