import 'package:flutter/material.dart';

import '../tokens.dart';

/// The tile provider's credit, one look on every map.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white.withValues(alpha: 0.75),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: Colors.black87),
    ),
  );
}

/// A round control that floats over a map, so both maps place the same button.
class MapControl extends StatelessWidget {
  const MapControl({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  /// Filled for a control that closes or expands; plain for one that toggles a layer.
  final bool filled;

  @override
  Widget build(BuildContext context) => filled
      ? IconButton.filledTonal(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon),
        )
      : IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: Colors.black.withValues(alpha: 0.45),
            foregroundColor: Colors.white,
          ),
          icon: Icon(icon, size: 18),
        );
}

/// The title row every chart carries: its colour, its name and the value under the finger.
class ChartHeader extends StatelessWidget {
  const ChartHeader({
    super.key,
    required this.title,
    this.color,
    this.readout,
    this.readoutKey,
  });

  final String title;
  final Color? color;
  final String? readout;
  final Key? readoutKey;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        if (color != null) ...[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(title, style: text.titleSmall),
        if (readout != null) ...[
          const Spacer(),
          Text(
            readout!,
            key: readoutKey,
            style: text.bodySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}

/// The style of the numbers written inside a chart's plot area.
TextStyle chartLabelStyle(BuildContext context) =>
    (Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11))
        .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
