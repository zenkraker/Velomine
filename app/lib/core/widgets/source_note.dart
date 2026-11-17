import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// Where a number came from: one small muted line with an info icon, read as one label by a screen
/// reader. Every screen that explains a computed number uses it. A note that opens something takes
/// [onTap]; the whole line is its tap target.
class SourceNote extends StatelessWidget {
  const SourceNote(this.text, {super.key, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final style = (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12))
        .copyWith(color: color);
    return Semantics(
      container: true,
      button: onTap != null,
      label: text,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: AppSourceNote.minHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: AppSpacing.xs,
            children: [
              Icon(
                onTap == null ? Icons.info_outline : Icons.directions_bike,
                size: AppLoading.errorIcon,
                color: color,
              ),
              Flexible(child: Text(text, style: style)),
            ],
          ),
        ),
      ),
    );
  }
}
