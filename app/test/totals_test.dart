import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
    server.totals['week'] = [
      totalsJson(
        '2026-10-26',
        '2026-11-01',
        rides: 1,
        distanceM: 60000,
        movingS: 7200,
        elevationGainM: 500,
      ),
      totalsJson(
        '2026-11-02',
        '2026-11-08',
        rides: 2,
        distanceM: 42500,
        movingS: 5400,
        elevationGainM: 400,
      ),
    ];
    server.totals['month'] = [
      totalsJson('2026-11-01', '2026-11-30', rides: 3, distanceM: 102500),
    ];
  });

  Future<void> openTotals(
    WidgetTester tester, {
    Size size = const Size(1000, 2400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/progress/totals');
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('TotalsScreen_ShouldShowOneColumnPerNumber_WhenShowingTheTable', (
    tester,
  ) async {
    await openTotals(tester);

    // The table's header names the columns once, as the mock-up draws them.
    final table = find.byKey(const Key('totals-table'));
    for (final column in ['Rides', 'Distance', 'Moving time', 'Climbing']) {
      expect(
        find.descendant(of: table, matching: find.text(column)),
        findsOneWidget,
        reason: column,
      );
    }
  });

  testWidgets('TotalsScreen_ShouldShowThisWeekFirst_WhenShowingTotals', (
    tester,
  ) async {
    await openTotals(tester);

    final thisWeek = find.byKey(const Key('total-0'));
    expect(
      find.descendant(of: thisWeek, matching: find.text('This week')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: thisWeek, matching: find.text('42.5 km')),
      findsOneWidget,
    );
    // One column per number, right-aligned: a row is not one sentence of numbers.
    for (final value in ['2', '1 h 30 min', '400 m']) {
      expect(
        find.descendant(of: thisWeek, matching: find.text(value)),
        findsOneWidget,
        reason: value,
      );
    }
    expect(find.byKey(const Key('total-1')), findsOneWidget);
  });

  testWidgets(
    'TotalsScreen_ShouldSwitchMeasureAndDrawTheAverage_WhenMeasureChanges',
    (tester) async {
      await openTotals(tester);

      expect(find.text('Distance per week'), findsOneWidget);
      // The average of 60 km and 42.5 km, beside the title, and the dashed line that draws it.
      expect(find.byKey(const Key('totals-average')), findsOneWidget);
      expect(find.text('Average 51.3 km'), findsOneWidget);
      final labelled = find.bySemanticsLabel(
        RegExp(r'Distance per week\. This week: 42\.5 km\.'),
      );
      expect(labelled, findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('totals-measure')),
          matching: find.text('Climbing'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('totals-measure')), findsOneWidget);
      expect(find.text('Climbing'), findsWidgets);
      expect(
        find.bySemanticsLabel(
          RegExp(r'Climbing per week\. This week: 400 m\.'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('TotalsScreen_ShouldAskMonthlyTotals_WhenSwitchingPeriods', (
    tester,
  ) async {
    await openTotals(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('totals-period')),
        matching: find.text('Months'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Distance per month'), findsOneWidget);
    expect(find.text('103 km'), findsWidgets); // 102.5 km, rounded
  });

  testWidgets('TotalsScreen_ShouldShowAllPeriods_WhenShowEarlierIsPressed', (
    tester,
  ) async {
    server.totals['week'] = [
      for (var i = 0; i < 12; i++)
        totalsJson(
          '2026-09-${(1 + i * 2).toString().padLeft(2, '0')}',
          '2026-09-${(7 + i * 2).toString().padLeft(2, '0')}',
          rides: i,
          distanceM: i * 9000.0,
          movingS: i * 3600.0,
          elevationGainM: i * 120.0,
        ),
    ];
    await openTotals(tester);

    await reveal(tester, find.byKey(const Key('totals-more')));
    expect(find.byKey(const Key('total-7')), findsOneWidget);
    expect(find.byKey(const Key('total-8')), findsNothing);

    await tester.tap(find.byKey(const Key('totals-more')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('total-11')), findsOneWidget);
    expect(find.byKey(const Key('totals-more')), findsNothing);
  });

  for (final width in [390.0, 600.0, 820.0, 1300.0]) {
    testWidgets('TotalsScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}', (
      tester,
    ) async {
      await openTotals(tester, size: Size(width, 2400));

      expect(find.byKey(const Key('total-0')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('TotalsScreen_ShouldNotOverflow_WhenTextIsTwiceItsSize', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openTotals(tester, size: const Size(390, 2800));

    expect(tester.takeException(), isNull);
  });
}
