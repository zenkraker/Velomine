import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../tokens.dart';

/// The tile provider's credit, one look on every map.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    color: VelomineColors.of(context).glass,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
            backgroundColor: VelomineColors.of(context).glass,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
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
            width: AppSpacing.md,
            height: AppSpacing.md,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        // The title takes what it needs and the readout the rest, flush with the end: a Flexible next to an
        // Expanded would split the row in half and leave the readout floating at its middle.
        Text(title, style: text.titleSmall),
        if (readout != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              readout!,
              key: readoutKey,
              textAlign: TextAlign.end,
              style: text.bodySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The style of the numbers written inside a chart's plot area: the axis size in the muted ink.
TextStyle chartLabelStyle(BuildContext context) {
  final theme = Theme.of(context);
  return (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
    color: theme.colorScheme.onSurfaceVariant,
  );
}
