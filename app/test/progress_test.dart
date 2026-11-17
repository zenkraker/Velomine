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
    'ProgressScreen_ShouldSayHowTheRangeSplits_WhenThereIsIntensityData',
    (tester) async {
      server.training = {
        ...trainingJson(),
        'intensity': {
          'easyS': 6000.0,
          'moderateS': 3000.0,
          'hardS': 1000.0,
          'easyPct': 60.0,
          'moderatePct': 30.0,
          'hardPct': 10.0,
          'polarisationIndex': 1.3,
          'label': 'pyramidal',
          'rides': 3,
        },
        'intensityWeeks': [
          {
            'weekStart': '2026-11-02',
            'easyS': 6000.0,
            'moderateS': 3000.0,
            'hardS': 1000.0,
          },
        ],
      };
      await openProgress(tester);

      await reveal(tester, find.byKey(const Key('intensity-card')));

      expect(
        find.text('Pyramidal: most easy, less moderate, least hard'),
        findsOneWidget,
      );
      expect(
        find.textContaining('60.0 % easy'),
        findsOneWidget,
        reason: 'the three shares, one decimal each',
      );
      expect(
        find.text('From power where you have it, otherwise heart rate.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ProgressScreen_ShouldHideTheIntensityCard_WhenNoRideHadPowerOrHeartRate',
    (tester) async {
      await openProgress(tester);

      expect(find.byKey(const Key('intensity-card')), findsNothing);
    },
  );

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

    await reveal(tester, find.byKey(const Key('training-tss')));
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

  const consented = {
    'date': '2026-11-08',
    'fatigue': 3,
    'soreness': 2,
    'mood': 4,
    'stress': 2,
    'motivation': 5,
  };

  Future<void> openWithdraw(WidgetTester tester) async {
    await reveal(tester, find.byKey(const Key('wellbeing-actions')));
    await tester.tap(find.byKey(const Key('wellbeing-actions')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'ProgressScreen_ShouldWithdrawConsent_WhenTheMenuEntryIsConfirmed',
    (tester) async {
      server.wellbeingConsent = true;
      server.wellbeingToday = consented;
      await openProgress(tester);

      await openWithdraw(tester);
      // The only red thing in the card is the menu entry; no button stays on the card.
      final entry = tester.widget<MenuItemButton>(
        find.byKey(const Key('wellbeing-withdraw')),
      );
      final scheme = Theme.of(
        tester.element(find.byKey(const Key('wellbeing-withdraw'))),
      ).colorScheme;
      expect(entry.style?.foregroundColor?.resolve({}), scheme.error);
      await tester.tap(find.byKey(const Key('wellbeing-withdraw')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('wellbeing-withdraw-confirm')));
      await tester.pumpAndSettle();

      expect(server.wellbeingConsent, isFalse);
      expect(server.sharingChoices['wellbeing'], 'none');
      expect(find.byKey(const Key('wellbeing-consent-card')), findsOneWidget);
    },
  );

  testWidgets('ProgressScreen_ShouldKeepConsent_WhenWithdrawIsCancelled', (
    tester,
  ) async {
    server.wellbeingConsent = true;
    server.wellbeingToday = consented;
    await openProgress(tester);

    await openWithdraw(tester);
    await tester.tap(find.byKey(const Key('wellbeing-withdraw')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(server.wellbeingConsent, isTrue);
    expect(find.byKey(const Key('wellbeing-card')), findsOneWidget);
  });

  for (final (name, size) in [
    ('Phone', const Size(390, 844)),
    ('Wide', const Size(1000, 2000)),
  ]) {
    testWidgets(
      'ProgressScreen_ShouldFilterFromOneSheet_WhenA${name}OpensTheMenuFilter',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await startApp(tester, server.session(useCookies: true));
        await tester.tap(find.text('Progress'));
        await tester.pumpAndSettle();

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
  }

  testWidgets('ProgressScreen_ShouldAskForOneDiscipline_WhenAFilterIsChosen', (
    tester,
  ) async {
    await openProgress(tester);

    await tester.tap(find.byKey(const Key('progress-filter-gravel')));
    await tester.pumpAndSettle();

    expect(server.analyticsFilters, contains('gravel'));
  });

  testWidgets('ProgressScreen_ShouldShowTheFtpReminder_WhenTheCheckHasAReason', (
    tester,
  ) async {
    server.ftpCheck['rider@example.com'] = {
      'reason': 'stale',
      'ftpW': 250,
      'ftpAgeDays': 49,
      'estimateW': 268,
      'estimateMethod': '20min',
    };
    await openProgress(tester);

    final card = find.byKey(const Key('ftp-reminder'));
    await reveal(tester, card);
    expect(find.text('Your FTP is 7 weeks old'), findsOneWidget);
    expect(find.byKey(const Key('ftp-reminder-use')), findsOneWidget);

    await tester.tap(find.byKey(const Key('ftp-reminder-how')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Warm up for 15 minutes, with three short hard efforts. Ride 5 '
        'minutes hard, then 10 minutes easy. Then ride 20 minutes as hard as '
        'you can hold evenly. Velomine will notice the effort and suggest your '
        'new FTP (95 % of the 20 minutes).',
      ),
      findsOneWidget,
    );
    // The card is behind the sheet, so closing it is the way back to "Use ... W".
    Navigator.of(tester.element(find.byKey(const Key('ftp-reminder-how-body'))))
        .pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ftp-reminder-how-body')), findsNothing);

    await tester.tap(find.byKey(const Key('ftp-reminder-use')));
    await tester.pumpAndSettle();
    expect(server.profiles['rider@example.com']?['ftpW'], 268);
  });

  testWidgets('ProgressScreen_ShouldHideIt_WhenSnoozed', (tester) async {
    server.ftpCheck['rider@example.com'] = {
      'reason': 'missing',
      'ftpW': null,
      'estimateW': 268,
      'estimateMethod': '20min',
    };
    await openProgress(tester);

    await reveal(tester, find.byKey(const Key('ftp-reminder')));
    expect(find.text('Set your FTP'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ftp-reminder-not-now')));
    await tester.pumpAndSettle();

    expect(server.snoozeRequests, 1);
    expect(find.byKey(const Key('ftp-reminder')), findsNothing);
  });
}
