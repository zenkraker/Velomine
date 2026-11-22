import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../tokens.dart';

/// A card's one way on, as the mock-up draws it: the page's name in `accent-strong` with an arrow.
class CardLink extends StatelessWidget {
  const CardLink(this.label, {super.key, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = VelomineColors.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(48, 48),
        foregroundColor: colors.accentStrong,
        textStyle: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          // A narrow card wraps the label instead of overflowing its link.
          Flexible(child: Text(label)),
          const ExcludeSemantics(child: Icon(Icons.arrow_forward, size: 16)),
        ],
      ),
    );
  }
}
