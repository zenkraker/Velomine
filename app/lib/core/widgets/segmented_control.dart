import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../tokens.dart';

/// A choice of two to four values on a track, with the chosen one raised on the card colour.
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    this.buttonKey,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  /// A key on the button itself, for a test that finds or taps it.
  final Key? buttonKey;

  final List<ButtonSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: VelomineColors.of(context).track,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: SegmentedButton<T>(
        key: buttonKey,
        showSelectedIcon: false,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.surfaceContainer
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          // Material's 12 dp each side leaves "Mountain" 46 dp on a phone with five segments, so it broke
          // in the middle of the word; 4 dp keeps whole words on a line.
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          ),
          textStyle: WidgetStatePropertyAll(
            text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        segments: segments,
        selected: {selected},
        onSelectionChanged: (selection) => onChanged(selection.single),
      ),
    );
  }
}
