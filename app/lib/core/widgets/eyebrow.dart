import 'package:material_ui/material_ui.dart';

/// A short uppercase line above a title, saying what a page or section is for in two or three words.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.76,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
