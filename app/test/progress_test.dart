import 'package:flutter/material.dart';
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

  Future<void> openProgress(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'ProgressScreen_ShouldShowOnlyTheChosenPeriod_WhenThePeriodChangesDuringALoad',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));

      final gate = server.delayNext('/api/v1/analytics/totals');
      await tester.tap(find.text('Progress'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      await tester.tap(find.text('Months'));
      await tester.pumpAndSettle();

      expect(find.text('This month'), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('This month'), findsOneWidget);
      expect(find.text('This week'), findsNothing);
      expect(find.text('103 km'), findsWidgets);
    },
  );

  testWidgets('ProgressScreen_ShouldShowThisWeekFirst_WhenShowingTotals', (
    tester,
  ) async {
    await openProgress(tester);

    expect(server.requests, contains('GET /api/v1/analytics/totals'));
    final thisWeek = find.byKey(const Key('total-0'));
    expect(
      find.descendant(of: thisWeek, matching: find.text('This week')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: thisWeek, matching: find.text('42.5 km')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: thisWeek,
        matching: find.text('2 rides · 1 h 30 min · 400 m climbing'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('total-1')), findsOneWidget);
    expect(find.byKey(const Key('no-goals')), findsOneWidget);
  });

  testWidgets('ProgressScreen_ShouldAskMonthlyTotals_WhenSwitchingToMonths', (
    tester,
  ) async {
    await openProgress(tester);

    await tester.tap(find.text('Months'));
    await tester.pumpAndSettle();

    expect(find.text('This month'), findsOneWidget);
    expect(find.text('103 km'), findsWidgets); // 102.5 km, rounded
  });

  testWidgets('ProgressScreen_ShouldShowTrainingTotals_WhenChangingRange', (
    tester,
  ) async {
    await openProgress(tester);

    expect(server.trainingRequests, [90]);
    expect(
      tester.widget<Text>(find.byKey(const Key('training-tss'))).data,
      '240',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('training-trimp'))).data,
      '180',
    );
    expect(find.byKey(const Key('fitness-chart')), findsOneWidget);
    expect(find.byKey(const Key('tss-chart')), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('training-range')),
        matching: find.text('30 d'),
      ),
    );
    await tester.pumpAndSettle();

    expect(server.trainingRequests, [90, 30]);
  });

  testWidgets('ProgressScreen_ShouldSendGoalInMetres_WhenTargetIsInKm', (
    tester,
  ) async {
    server.goalCurrent['distance'] = 40000;
    await openProgress(tester);

    await reveal(tester, find.byKey(const Key('add-goal')));
    await tester.tap(find.byKey(const Key('add-goal')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('goal-target')), '100');
    await tester.tap(find.byKey(const Key('goal-save')));
    await tester.pumpAndSettle();

    expect(server.goals.single, {
      'id': 'goal-1',
      'period': 'week',
      'metric': 'distance',
      'target': 100000.0,
    });
    expect(find.text('Weekly distance'), findsOneWidget);
    expect(find.text('40.0 km of 100 km · 40 %'), findsOneWidget);
  });

  testWidgets('ProgressScreen_ShouldStoreMilesAsMetres_WhenUnitsAreImperial', (
    tester,
  ) async {
    server.accounts['rider@example.com']!.units = 'imperial';
    server.goalCurrent['distance'] = 40000;
    await openProgress(tester);

    await reveal(tester, find.byKey(const Key('add-goal')));
    await tester.tap(find.byKey(const Key('add-goal')));
    await tester.pumpAndSettle();
    // The field is labelled in miles: 100 mi is 160934.4 m.
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('goal-target')))
          .decoration!
          .suffixText,
      'mi',
    );
    await tester.enterText(find.byKey(const Key('goal-target')), '100');
    await tester.tap(find.byKey(const Key('goal-save')));
    await tester.pumpAndSettle();

    expect(server.goals.single['target'], closeTo(160934.4, 0.1));
    expect(find.text('24.9 mi of 100 mi · 24 %'), findsOneWidget);
  });

  testWidgets('ProgressScreen_ShouldUpdateAndDeleteGoal_WhenEditingGoal', (
    tester,
  ) async {
    server.goals.add({
      'id': 'goal-1',
      'period': 'month',
      'metric': 'time',
      'target': 36000.0,
    });
    server.goalCurrent['time'] = 36000;
    await openProgress(tester);
    expect(find.text('Reached'), findsOneWidget);

    await reveal(tester, find.byKey(const Key('goal-edit-goal-1')));
    await tester.tap(find.byKey(const Key('goal-edit-goal-1')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('goal-target')))
          .controller!
          .text,
      '10',
    );
    await tester.enterText(find.byKey(const Key('goal-target')), '20');
    await tester.tap(find.byKey(const Key('goal-save')));
    await tester.pumpAndSettle();
    expect(server.goals.single['target'], 72000.0);
    expect(find.text('10 h 00 min of 20 h 00 min · 50 %'), findsOneWidget);

    await reveal(tester, find.byKey(const Key('goal-delete-goal-1')));
    await tester.tap(find.byKey(const Key('goal-delete-goal-1')));
    await tester.pumpAndSettle();
    expect(server.goals, isEmpty);
    expect(find.byKey(const Key('no-goals')), findsOneWidget);
  });

  testWidgets('ProgressScreen_ShouldRejectEmptyTarget_WhenSavingGoal', (
    tester,
  ) async {
    await openProgress(tester);

    await reveal(tester, find.byKey(const Key('add-goal')));
    await tester.tap(find.byKey(const Key('add-goal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('goal-save')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a target above 0.'), findsOneWidget);
    expect(server.goals, isEmpty);
  });

  testWidgets('ProgressScreen_ShouldShowPowerAndReadiness_WhenAnalyticsLoad', (
    tester,
  ) async {
    await openProgress(tester);

    await reveal(tester, find.byKey(const Key('power-curve-card')));
    expect(find.byKey(const Key('readiness-card')), findsOneWidget);
    expect(find.byKey(const Key('power-curve-card')), findsOneWidget);
    expect(find.text('Estimated FTP'), findsOneWidget);
    expect(find.byKey(const Key('use-ftp')), findsOneWidget);

    await tester.tap(find.byKey(const Key('use-ftp')));
    await tester.pumpAndSettle();

    expect(server.profiles['rider@example.com']?['ftpW'], 266);
  });

  testWidgets('ProgressScreen_ShouldAskForConsent_WhenWellbeingIsNotSetUp', (
    tester,
  ) async {
    await openProgress(tester);

    await reveal(tester, find.byKey(const Key('wellbeing-consent')));
    expect(find.byKey(const Key('wellbeing-consent-card')), findsOneWidget);
    await tester.tap(find.byKey(const Key('wellbeing-consent')));
    await tester.pumpAndSettle();

    expect(server.wellbeingConsent, isTrue);
    await reveal(tester, find.byKey(const Key('wellbeing-save')));
    await tester.tap(find.byKey(const Key('wellbeing-save')));
    await tester.pumpAndSettle();

    expect(server.wellbeingToday?['fatigue'], 3);
    expect(server.wellbeingToday?['motivation'], 3);
    expect(find.byKey(const Key('readiness-card')), findsOneWidget);
    expect(find.text('How you feel'), findsOneWidget);
  });

  testWidgets(
    'ProgressScreen_ShouldClearMemberData_WhenAnotherAccountSignsIn',
    (tester) async {
      final second = server.add('other@example.com');
      await openProgress(tester);
      expect(find.byKey(const Key('total-0')), findsOneWidget);
      expect(find.text('42.5 km'), findsWidgets);

      await openAccount(tester, 'sign-out');
      await tester.pumpAndSettle();
      server.totals.clear();
      server.goals.clear();
      server.goalCurrent.clear();

      await tester.enterText(find.byKey(const Key('email')), second.email);
      await tester.enterText(
        find.byKey(const Key('password')),
        second.password,
      );
      await tester.tap(find.byKey(const Key('sign-in')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('total-0')), findsNothing);
      expect(find.text('42.5 km'), findsNothing);
      expect(find.byKey(const Key('no-goals')), findsOneWidget);
      expect(
        server.requests
            .where((r) => r == 'GET /api/v1/analytics/totals')
            .length,
        2,
      );
    },
  );

  testWidgets('ProgressScreen_ShouldWithdrawConsent_WhenTheButtonIsTapped', (
    tester,
  ) async {
    server.wellbeingConsent = true;
    server.wellbeingToday = {
      'date': '2026-11-08',
      'fatigue': 3,
      'soreness': 2,
      'mood': 4,
      'stress': 2,
      'motivation': 5,
    };
    await openProgress(tester);

    await reveal(tester, find.byKey(const Key('wellbeing-withdraw')));
    await tester.tap(find.byKey(const Key('wellbeing-withdraw')));
    await tester.pumpAndSettle();

    expect(server.wellbeingConsent, isFalse);
    expect(server.sharingChoices['wellbeing'], 'none');
    expect(find.byKey(const Key('wellbeing-consent-card')), findsOneWidget);
  });

  testWidgets('ProgressScreen_ShouldAskForOneDiscipline_WhenAFilterIsChosen', (
    tester,
  ) async {
    await openProgress(tester);

    await tester.tap(find.byKey(const Key('progress-filter-gravel')));
    await tester.pumpAndSettle();

    expect(server.analyticsFilters, contains('gravel'));
  });
}
