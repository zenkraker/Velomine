import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/tokens.dart';
import 'package:velomine/core/widgets/card_grid.dart';

void main() {
  /// Builds a grid whose cards are as tall as the numbers given, one per height.
  Future<void> pumpGrid(
    WidgetTester tester, {
    required double width,
    required List<double> heights,
    VoidCallback? onTap,
    int columns = 2,
    int tabletColumns = 2,
  }) async {
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CardGrid(
              columns: columns,
              tabletColumns: tabletColumns,
              children: [
                for (final (i, height) in heights.indexed)
                  GestureDetector(
                    key: Key('card-$i'),
                    onTap: onTap,
                    child: SizedBox(height: height, child: const Text('card')),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Rect cardRect(WidgetTester tester, int i) =>
      tester.getRect(find.byKey(Key('card-$i')));

  testWidgets(
    'CardGrid_ShouldGiveEveryCardTheRowsTallestHeight_WhenCardsDiffer',
    (tester) async {
      // 1300 dp is the desktop width: three columns, so the first three share one row.
      await pumpGrid(
        tester,
        width: 1300,
        heights: [40, 90, 60, 50],
        columns: 3,
      );

      final first = cardRect(tester, 0);
      expect(cardRect(tester, 1).height, first.height);
      expect(cardRect(tester, 2).height, first.height);
      expect(first.height, 90);
    },
  );

  testWidgets('CardGrid_ShouldFillTheLastRow_WhenOneCardIsLeftOver', (
    tester,
  ) async {
    await pumpGrid(tester, width: 1300, heights: [40, 40, 40, 40], columns: 3);

    // The fourth card has a row of its own, and it takes the whole width.
    final grid = tester.getRect(find.byType(CardGrid));
    final lone = cardRect(tester, 3);
    expect(lone.width, grid.width);
    expect(cardRect(tester, 0).width, lessThan(lone.width));
  });

  testWidgets('CardGrid_ShouldShowOneColumn_WhenTheWindowIsAPhone', (
    tester,
  ) async {
    await pumpGrid(tester, width: 390, heights: [40, 40, 40], columns: 3);

    final grid = tester.getRect(find.byType(CardGrid));
    expect(cardRect(tester, 0).width, grid.width);
    expect(cardRect(tester, 1).top, greaterThan(cardRect(tester, 0).bottom));
  });

  testWidgets('CardGrid_ShouldShowTwoColumns_WhenTheWindowIsATablet', (
    tester,
  ) async {
    await pumpGrid(tester, width: 800, heights: [40, 40, 40], columns: 3);

    final grid = tester.getRect(find.byType(CardGrid));
    expect(cardRect(tester, 0).width, (grid.width - AppSpacing.lg) / 2);
    expect(cardRect(tester, 1).top, cardRect(tester, 0).top);
    // The lone third card fills the row instead of leaving half of it empty.
    expect(cardRect(tester, 2).top, greaterThan(cardRect(tester, 0).bottom));
    expect(cardRect(tester, 2).width, grid.width);
  });

  testWidgets('CardGrid_ShouldShowThreeColumns_WhenTheWindowIsADesktop', (
    tester,
  ) async {
    await pumpGrid(tester, width: 1300, heights: [40, 40, 40], columns: 3);

    final grid = tester.getRect(find.byType(CardGrid));
    expect(cardRect(tester, 0).width, (grid.width - AppSpacing.lg * 2) / 3);
    expect(cardRect(tester, 1).top, cardRect(tester, 0).top);
    expect(cardRect(tester, 2).top, cardRect(tester, 0).top);
  });

  testWidgets('CardGrid_ShouldReachTheCard_WhenATapLandsOnTheFirstRow', (
    tester,
  ) async {
    var taps = 0;
    await pumpGrid(
      tester,
      width: 800,
      heights: [40, 40, 40],
      onTap: () => taps++,
    );

    await tester.tap(find.byKey(const Key('card-1')));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('CardGrid_ShouldReachTheCard_WhenATapLandsOnTheLastRow', (
    tester,
  ) async {
    var taps = 0;
    await pumpGrid(
      tester,
      width: 1300,
      heights: [40, 40, 40, 40],
      columns: 3,
      onTap: () => taps++,
    );

    await tester.tap(find.byKey(const Key('card-3')));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('CardGrid_ShouldGrowTheRow_WhenACardGrows', (tester) async {
    // A card whose content arrives after the first layout (a ride going from "reading" to read) must be
    // measured again, not laid out at the height it had when it was empty.
    final grow = GlobalKey<_GrowState>();
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CardGrid(
              children: [
                _Grow(key: grow),
                const SizedBox(key: Key('card-1'), height: 40),
              ],
            ),
          ),
        ),
      ),
    );

    grow.currentState!.makeTaller();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(const Key('card-1'))).height, 200);
  });
}

/// A card that grows to 200 when [taller] is set, the way a card does when its data arrives.
class _Grow extends StatefulWidget {
  const _Grow({super.key});

  @override
  State<_Grow> createState() => _GrowState();
}

class _GrowState extends State<_Grow> {
  bool taller = false;

  void makeTaller() => setState(() => taller = true);

  @override
  Widget build(BuildContext context) =>
      SizedBox(key: const Key('card-0'), height: taller ? 200 : 40);
}
