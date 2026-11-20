import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// A card in the page flow: a fill on the page colour, no border and no shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  final Widget child;

  /// The card's inner margin: the card padding token unless a card draws its own rows.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: padding, child: child),
  );
}
