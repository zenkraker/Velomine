import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// The error line under a form or a section: the message in the error colour, announced to a screen reader
/// when it appears. Put the test key on this widget.
class InlineError extends StatelessWidget {
  const InlineError(this.text, {super.key, this.showIcon = false});

  final String text;

  /// A small error icon before the text, for a message that stands alone on the page.
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.error;
    final message = Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(color: color),
    );
    return Semantics(
      liveRegion: true,
      container: true,
      child: showIcon
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.sm,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.error_outline,
                    size: AppLoading.errorIcon,
                    color: color,
                  ),
                ),
                Expanded(child: message),
              ],
            )
          : message,
    );
  }
}
