import 'package:flutter/material.dart';

/// A neutral block the size of content that is still loading, so the layout does not jump when it arrives.
class PlaceholderBlock extends StatelessWidget {
  const PlaceholderBlock({
    super.key,
    required this.height,
    this.width,
    this.radius = 12,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}
