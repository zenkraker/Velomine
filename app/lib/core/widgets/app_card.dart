import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// A card in the page flow: a fill on the page colour, no border and no shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.onTap,
  });

  final Widget child;

  /// The card's inner margin: the card padding token unless a card draws its own rows.
  final EdgeInsetsGeometry padding;

  /// Makes the whole card a target, for a card that opens the page that explains it.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    if (onTap == null) return Card(child: content);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}
