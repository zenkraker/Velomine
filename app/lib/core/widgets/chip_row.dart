import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// Chips in one row that scrolls sideways, as the mock-ups' `.vm-chips` draw them, scrolled so the
/// chosen chip is in view: on a phone the row is wider than the window, and a page whose own chip is
/// cut off at the edge looks as if none were chosen.
class ChipRow extends StatefulWidget {
  const ChipRow({
    super.key,
    this.rowKey,
    required this.chips,
    required this.selected,
  });

  /// A key on the scrolling row, for a test that drags it.
  final Key? rowKey;
  final List<Widget> chips;

  /// The index of the chosen chip.
  final int selected;

  @override
  State<ChipRow> createState() => _ChipRowState();
}

class _ChipRowState extends State<ChipRow> {
  final _keys = <GlobalKey>[];

  @override
  void initState() {
    super.initState();
    _reveal();
  }

  @override
  void didUpdateWidget(ChipRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) _reveal();
  }

  void _reveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.selected >= _keys.length) return;
      final chip = _keys[widget.selected].currentContext;
      if (chip != null) {
        Scrollable.ensureVisible(chip, alignment: 0.5, duration: Duration.zero);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    while (_keys.length < widget.chips.length) {
      _keys.add(GlobalKey());
    }
    return SingleChildScrollView(
      key: widget.rowKey,
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          for (final (i, chip) in widget.chips.indexed)
            KeyedSubtree(key: _keys[i], child: chip),
        ],
      ),
    );
  }
}
