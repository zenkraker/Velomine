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

  Future<void> openProgress(
    WidgetTester tester, {
    Size size = const Size(1000, 2000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/progress');
  }

  testWidgets(
    'ProgressScreen_ShouldShowFourStatCardsAndNoDeepCards_WhenOpened',
    (tester) async {
      await openProgress(tester);

      for (final key in [
        'metric-readiness',
        'metric-form',
        'metric-period',
        'metric-next-event',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: key);
      }
      // The deep charts answer their own question on their own page.
      for (final key in [
        'training-tss',
        'tss-chart',
        'fitness-chart',
        'power-curve-card',
        'intensity-card',
        'efficiency-card',
        'readiness-card',
        'wellbeing-card',
        'goal-goal-1',
      ]) {
        expect(find.byKey(Key(key)), findsNothing, reason: key);
      }
      // The overview still shows the totals chart and its period control.
      expect(find.byKey(const Key('progress-period')), findsOneWidget);
    },
  );

  testWidgets('ProgressScreen_ShouldShowThisWeek_WhenShowingTotals', (
    tester,
  ) async {
    await openProgress(tester);

    expect(server.requests, contains('GET /api/v1/analytics/totals'));
    final card = find.byKey(const Key('metric-period'));
    expect(
      find.descendant(of: card, matching: find.text('This week')),
      findsOneWidget,
    );
    // The latest week is 42.5 km against a 60 km week before it: below the average.
    expect(
      find.descendant(of: card, matching: find.text('42.5 km')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.text('Below your 12-week average of 60.0 km.'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('ProgressScreen_ShouldAskMonthlyTotals_WhenSwitchingToMonths', (
    tester,
  ) async {
    await openProgress(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('progress-period')),
        matching: find.text('Months'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Distance per month'), findsOneWidget);
  });

  testWidgets(
    'ProgressScreen_ShouldShowOnlyTheChosenPeriod_WhenThePeriodChangesDuringALoad',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));
      await goTo(tester, '/progress');

      final gate = server.delayNext('/api/v1/analytics/totals');
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('progress-period')),
          matching: find.text('Months'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Distance per month'), findsOneWidget);
      expect(find.text('Distance per week'), findsNothing);
    },
  );

  testWidgets('ProgressScreen_ShouldAskForOneDiscipline_WhenAFilterIsChosen', (
    tester,
  ) async {
    await openProgress(tester);

    await tester.tap(find.byKey(const Key('progress-filter-gravel')));
    await tester.pumpAndSettle();

    expect(server.analyticsFilters, contains('gravel'));
  });

  testWidgets(
    'ProgressScreen_ShouldOpenTheFilterInOneSheet_WhenAPhoneTapsTheSportChip',
    (tester) async {
      await openProgress(tester, size: const Size(390, 844));

      await tester.tap(find.byKey(const Key('progress-filter-chip')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byKey(const Key('progress-filter-gravel')),
        ),
      );
      await tester.pumpAndSettle();

      expect(server.analyticsFilters, contains('gravel'));
    },
  );

  testWidgets(
    'ProgressScreen_ShouldOpenTheFilterInASheet_WhenTheMenuEntryIsChosen',
    (tester) async {
      await openProgress(tester);

      await tester.tap(find.byKey(const Key('progress-actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('progress-filter')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byKey(const Key('progress-filter-gravel')),
        ),
      );
      await tester.pumpAndSettle();

      expect(server.analyticsFilters, contains('gravel'));
    },
  );

  testWidgets('ProgressScreen_ShouldShowTheNextEvent_WhenOneIsPlanned', (
    tester,
  ) async {
    final date = DateUtils.dateOnly(DateTime.now())
        .add(const Duration(days: 10))
        .toIso8601String()
        .substring(0, 10);
    server.events.add({
      'id': 'event-1',
      'name': 'Gran Fondo',
      'date': date,
      'kind': 'sportive',
      'distanceM': 120000.0,
      'elevationGainM': null,
      'notes': null,
      'rideId': null,
      'createdAt': '2026-11-10T09:00:00Z',
    });
    await openProgress(tester);

    final card = find.byKey(const Key('metric-next-event'));
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text('10 days')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.textContaining('Gran Fondo')),
      findsOneWidget,
    );
  });

  testWidgets('NextEventCard_ShouldShowFallback_WhenNoEventPlanned', (
    tester,
  ) async {
    await openProgress(tester);

    final card = find.byKey(const Key('metric-next-event'));
    expect(card, findsOneWidget);
    expect(
      find.descendant(
        of: card,
        matching: find.text('No event planned. Add one to see the days to go.'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('Goals and events')),
      findsOneWidget,
    );
  });

  testWidgets('ProgressScreen_ShouldOpenTheSubPage_WhenItsCardLinkIsChosen', (
    tester,
  ) async {
    await openProgress(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('metric-form')),
        matching: find.text('Fitness'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fitness-chart')), findsOneWidget);
  });

  testWidgets(
    'ProgressScreen_ShouldClearMemberData_WhenAnotherAccountSignsIn',
    (tester) async {
      final second = server.add('other@example.com');
      await openProgress(tester);
      expect(find.text('42.5 km'), findsWidgets);

      await openAccount(tester, 'sign-out');
      await tester.pumpAndSettle();
      server.totals.clear();

      await tester.enterText(find.byKey(const Key('email')), second.email);
      await tester.enterText(
        find.byKey(const Key('password')),
        second.password,
      );
      await tester.tap(find.byKey(const Key('sign-in')));
      await tester.pumpAndSettle();

      await goTo(tester, '/progress');

      expect(find.text('42.5 km'), findsNothing);
      expect(
        server.requests
            .where((r) => r == 'GET /api/v1/analytics/totals')
            .length,
        2,
      );
    },
  );

  for (final width in [390.0, 600.0, 820.0, 1300.0]) {
    testWidgets(
      'ProgressScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
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
        server.training = trainingJson();
        server.wellbeingConsent = true;
        await openProgress(tester, size: Size(width, 2000));

        for (final key in [
          'metric-readiness',
          'metric-form',
          'metric-period',
          'metric-next-event',
        ]) {
          expect(find.byKey(Key(key)), findsOneWidget, reason: key);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('ProgressScreen_ShouldNotOverflow_WhenTextIsTwiceItsSize', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    server.training = trainingJson();
    await openProgress(tester, size: const Size(390, 2400));

    expect(tester.takeException(), isNull);
  });
}
