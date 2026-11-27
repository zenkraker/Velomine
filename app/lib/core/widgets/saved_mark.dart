import 'package:material_ui/material_ui.dart';

import '../l10n.dart';
import '../motion.dart';
import '../tokens.dart';

/// The "Saved." confirmation after a save: a check and the word, faded in while [visible] and out when not. Its
/// height is kept either way, so the card it sits in does not jump when it appears. Read once, when it shows, by
/// a screen reader.
class SavedMark extends StatelessWidget {
  const SavedMark({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return ExcludeSemantics(
      excluding: !visible,
      child: Semantics(
        liveRegion: true,
        container: true,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: motionDuration(context, AppMotion.standard),
          curve: motionCurve(context, AppMotion.emphasized),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSourceNote.minHeight,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: AppSpacing.xs,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.check,
                    size: AppLoading.errorIcon,
                    color: color,
                  ),
                ),
                Text(
                  context.l10n.saved,
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
