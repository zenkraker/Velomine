import 'package:material_ui/material_ui.dart';

import '../l10n.dart';
import '../tokens.dart';

/// The rest of a page, folded behind one button: what a simple rider does not want to read first, one tap away.
///
/// The open state is local to the visit, so every time the page is opened the simple view is what it shows. In
/// training the screen folds nothing and passes an empty list, so nothing is drawn.
class MoreDetails extends StatefulWidget {
  const MoreDetails({super.key, required this.label, required this.children});

  /// "Show more analysis" or "Show all details", depending on what is behind it.
  final String label;

  final List<Widget> children;

  @override
  State<MoreDetails> createState() => _MoreDetailsState();
}

class _MoreDetailsState extends State<MoreDetails> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpacing.md,
    children: [
      if (_open) ...widget.children,
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const Key('more-details'),
          onPressed: () => setState(() => _open = !_open),
          icon: Icon(_open ? Icons.expand_less : Icons.expand_more),
          // Folding again is the same button, so the way back is where the way in was.
          label: Text(_open ? context.l10n.showLess : widget.label),
        ),
      ),
    ],
  );
}
