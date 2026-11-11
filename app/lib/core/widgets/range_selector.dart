import 'package:flutter/material.dart';

import '../tokens.dart';

/// A card title with the range it shows. The segments move under the title when the row does not
/// fit, which is what a phone at a large text size asks for.
class RangeSelector<T> extends StatelessWidget {
  const RangeSelector({
    super.key,
    required this.title,
    required this.segmentKey,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final Key segmentKey;
  final List<ButtonSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: AppSpacing.md,
    runSpacing: 8,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      SegmentedButton<T>(
        key: segmentKey,
        // The selected state is already visible; the tick costs the width a label needs on a phone.
        showSelectedIcon: false,
        segments: segments,
        selected: {selected},
        onSelectionChanged: (selection) => onChanged(selection.single),
      ),
    ],
  );
}
