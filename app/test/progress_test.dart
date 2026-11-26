import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velomine/core/tokens.dart';
import 'package:velomine/core/widgets/card_link.dart';

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

  testWidgets('ProgressScreen_ShouldShowFourStatCards_WhenTheRiderJustRides', (
    tester,
  ) async {
    // A rider who just rides sees the four numbers; the analysis waits behind one button.
    server.accounts['rider@example.com']!.riderMode = 'just_riding';
    await openProgress(tester);

    for (final key in [
      'metric-readiness',
      'metric-form',
      'metric-period',
      'metric-next-event',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    // The deep charts answer their own question on their own page: none of them is on the overview,
    // and there is no fold to open.
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
      'more-details',
    ]) {
      expect(find.byKey(Key(key)), findsNothing, reason: key);
    }
    // The overview still shows the totals chart and its period control, and links on to Totals.
    expect(find.byKey(const Key('progress-period')), findsOneWidget);
    expect(find.byKey(const Key('progress-totals-link')), findsOneWidget);
  });

  testWidgets(
    'ProgressScreen_ShouldKeepTheAnalysisOffTheOverview_WhenTheModeIsTraining',
    (tester) async {
      // A training rider gets the same overview as everyone else: the analysis lives on its sub-pages.
      server.accounts['rider@example.com']!.riderMode = 'training';
      await openProgress(tester);

      expect(find.byKey(const Key('metric-readiness')), findsOneWidget);
      expect(find.byKey(const Key('more-details')), findsNothing);
      expect(find.byKey(const Key('intensity-card')), findsNothing);
      expect(find.byKey(const Key('power-curve-card')), findsNothing);
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
    // The latest week is 42.5 km against a 60 km week before it: below the average, and the sentence
    // keeps the rides and the time the week took.
    expect(
      find.descendant(of: card, matching: find.text('42.5 km')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.text(
          '2 rides, 1 h 30 min. Below your 12-week average of 60.0 km.',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'ProgressScreen_ShouldGrowTheChartCardToTheWindowBottom_WhenWidthIs1300',
    (tester) async {
      await openProgress(tester, size: const Size(1300, 1000));

      // ProgressDesktop.md: "It grows to the bottom of the window, so the content ends level with the
      // sidebar." The card's link sits at its foot, well below the short chart.
      final link = find.byKey(const Key('progress-totals-link'));
      expect(link, findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(link).bottom,
        greaterThan(1000 - 4 * AppSpacing.xxl),
        reason: 'the card ends at the window bottom',
      );
    },
  );

  testWidgets(
    'ProgressScreen_ShouldNotOverflow_WhenTheWindowIsShortAndFillLastIsOn',
    (tester) async {
      // A 500 dp window at the sidebar width: the card is taller than the room left, so the page
      // scrolls rather than overflowing.
      await openProgress(tester, size: const Size(1300, 500));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('progress-totals-link')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

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
    'ProgressScreen_ShouldPutTheSportChipInTheTitleRow_WhenTheWindowIsAPhone',
    (tester) async {
      await openProgress(tester, size: const Size(390, 844));

      // The chip sits in the header, above the sub-pages' tabs.
      final chip = tester
          .getTopLeft(find.byKey(const Key('progress-filter-chip')))
          .dy;
      final tabs = tester
          .getTopLeft(find.byKey(const Key('progress-tab-overview')))
          .dy;
      expect(chip, lessThan(tabs));
    },
  );

  testWidgets(
    'ProgressScreen_ShouldOpenTheFitnessPage_WhenThePhoneTapsTheFormCard',
    (tester) async {
      await openProgress(tester, size: const Size(390, 844));

      final card = find.byKey(const Key('metric-form'));
      // Two cards side by side carry no link: the whole card is the way on.
      expect(
        find.descendant(of: card, matching: find.byType(CardLink)),
        findsNothing,
      );
      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fitness-chart')), findsOneWidget);
    },
  );

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
    'ProgressScreen_ShouldNotRepeatTheSportFilter_WhenTheChipsAlreadyDrawIt',
    (tester) async {
      await openProgress(tester);

      // The chips on the page are the only way to the filter: no menu repeats them.
      expect(find.byKey(const Key('progress-actions')), findsNothing);
      await tester.tap(find.byKey(const Key('progress-filter-gravel')));
      await tester.pumpAndSettle();

      expect(server.analyticsFilters, contains('gravel'));
    },
  );

  testWidgets('ProgressScreen_ShouldShowTheFormStateWord_WhenTheFormArrives', (
    tester,
  ) async {
    await openProgress(tester);

    final card = find.byKey(const Key('metric-form'));
    expect(
      find.descendant(of: card, matching: find.text('Building')),
      findsOneWidget,
    );
  });

  testWidgets(
    'ProgressScreen_ShouldShowEmptyCards_WhenTheRiderHasNoLoadAndNoRides',
    (tester) async {
      server.training = {...trainingJson(), 'days': const <Object?>[]};
      server.totals['week'] = [];
      await openProgress(tester);

      // No data is a fact the cards carry: they say what makes one appear instead of vanishing.
      for (final (key, sentence) in [
        (
          'metric-form',
          'No training load in this range. Rides with power or heart rate add to it.',
        ),
        (
          'metric-period',
          'No rides yet. Upload or record a ride to see your totals.',
        ),
      ]) {
        final card = find.byKey(Key(key));
        expect(card, findsOneWidget, reason: key);
        expect(
          find.descendant(of: card, matching: find.text(sentence)),
          findsOneWidget,
          reason: key,
        );
        expect(
          find.descendant(of: card, matching: find.text('–')),
          findsOneWidget,
          reason: key,
        );
      }
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
