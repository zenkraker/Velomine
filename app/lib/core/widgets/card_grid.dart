import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// Cards in a grid that uses the window's width: [columns] across from a desktop window, two from a
/// tablet window and one on a phone. A row is as tall as its tallest card, and a card left alone in
/// the last row takes the whole width, so no card is squashed and no row is half empty.
class CardGrid extends StatelessWidget {
  const CardGrid({
    super.key,
    required this.children,
    this.columns = 2,
    this.tabletColumns = 2,
    this.hero = 0,
  });

  final List<Widget> children;

  /// How many cards across a wider row's first cell takes; 0 for none. A dashboard's main card reads
  /// first and larger, and the others sit beside it.
  final int hero;

  /// How many cards a desktop window shows; below [AppBreakpoint.expandedWidth] there is [tabletColumns].
  final int columns;

  /// How many cards a window from [AppBreakpoint.compactWidth] shows: two, as the design's size classes
  /// say, one only for a grid that asks for it.
  final int tabletColumns;

  @override
  Widget build(BuildContext context) {
    final windowWidth = MediaQuery.sizeOf(context).width;
    final count = windowWidth >= AppBreakpoint.expandedWidth
        ? columns
        : windowWidth >= AppBreakpoint.compactWidth
        ? tabletColumns
        : 1;
    return _CardGridLayout(
      columns: count < 1 ? 1 : count,
      hero: hero,
      children: children,
    );
  }
}

/// The grid itself. It measures each card at the width it will really get and then gives it its row's
/// tallest card as a minimum height, so a card's own idea of its height and the room it is given never
/// disagree — which is what overflows when a row is forced to a tight height.
class _CardGridLayout extends MultiChildRenderObjectWidget {
  const _CardGridLayout({
    required this.columns,
    required this.hero,
    super.children,
  });

  final int columns;
  final int hero;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCardGrid(columns, hero);

  @override
  void updateRenderObject(BuildContext context, _RenderCardGrid renderObject) {
    renderObject
      ..columns = columns
      ..hero = hero;
  }
}

class _CardGridParentData extends ContainerBoxParentData<RenderBox> {}

/// One card and how many columns of its row it takes.
typedef _Cell = (RenderBox child, int span);

class _RenderCardGrid extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _CardGridParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _CardGridParentData> {
  _RenderCardGrid(this._columns, this._hero);

  static const double _gap = AppSpacing.lg;

  int get columns => _columns;
  int _columns;
  set columns(int value) {
    if (value == _columns) return;
    _columns = value;
    markNeedsLayout();
  }

  int get hero => _hero;
  int _hero;
  set hero(int value) {
    if (value == _hero) return;
    _hero = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _CardGridParentData) {
      child.parentData = _CardGridParentData();
    }
  }

  /// The cards, packed into rows of [columns] slots, the first taking [hero] of them.
  List<List<_Cell>> _rows() {
    final rows = <List<_Cell>>[];
    var row = <_Cell>[];
    var used = 0;
    var index = 0;
    for (
      RenderBox? child = firstChild;
      child != null;
      child = childAfter(child)
    ) {
      final span = index++ == 0 ? hero.clamp(1, columns) : 1;
      if (used + span > columns) {
        rows.add(row);
        row = <_Cell>[];
        used = 0;
      }
      row.add((child, span));
      used += span;
    }
    if (row.isNotEmpty) rows.add(row);
    if (rows.isEmpty) return rows;

    // A card alone in the last row fills it, so the grid never leaves a column of dead space.
    final last = rows.last;
    if (last.length == 1) last[0] = (last[0].$1, columns);
    return rows;
  }

  double _widthOf(int span, double width) =>
      (width - _gap * (columns - 1)) / columns * span + _gap * (span - 1);

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    var y = 0.0;
    for (final row in _rows()) {
      // Measure every card at the width it is about to get, then give the row its tallest height:
      // every card in the row is then at least that tall, so they match.
      for (final (child, span) in row) {
        child.layout(
          BoxConstraints.tightFor(width: _widthOf(span, width)),
          parentUsesSize: true,
        );
      }
      var rowHeight = 0.0;
      for (final (child, _) in row) {
        if (child.size.height > rowHeight) rowHeight = child.size.height;
      }
      var x = 0.0;
      for (final (child, span) in row) {
        final cardWidth = _widthOf(span, width);
        // The row's height as a *minimum*, not a tight size: a child laid out tight becomes its own
        // relayout boundary, and then a card whose content grows is re-laid out at the old height
        // without this grid measuring it again, overflowing the card. Non-tight keeps the grid in the
        // chain, and a card fills its row because it is at least as tall as the row's tallest card.
        child.layout(
          BoxConstraints(
            minWidth: cardWidth,
            maxWidth: cardWidth,
            minHeight: rowHeight,
          ),
          parentUsesSize: true,
        );
        (child.parentData! as _CardGridParentData).offset = Offset(x, y);
        x += cardWidth + _gap;
      }
      y += rowHeight + _gap;
    }
    size = constraints.constrain(Size(width, y == 0 ? 0 : y - _gap));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
