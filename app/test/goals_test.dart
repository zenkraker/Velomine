import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/l10n.dart';
import 'package:velomine/core/theme.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';
import 'package:velomine/core/widgets/goal_gauge.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
  });

  /// The Goals destination, from the rail: it is one of the four at every width.
  Future<void> openGoals(
    WidgetTester tester, {
    Size size = const Size(1000, 2000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.text('Goals'));
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

  /// An event a whole number of days away, so the card reads the same whatever day the test runs.
  Map<String, Object?> eventJson() {
    final date = DateUtils.dateOnly(DateTime.now())
        .add(const Duration(days: 10));
    final day =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return {
      'id': 'event-1',
      'name': 'Gran Fondo',
      'date': day,
      'kind': 'sportive',
      'distanceM': 120000.0,
      'elevationGainM': null,
      'notes': null,
      'rideId': null,
      'createdAt': '2026-11-10T09:00:00Z',
    };
  }

  testWidgets('GoalsScreen_ShouldShowEmptyState_WhenTheRiderHasNoGoals', (
    tester,
  ) async {
    await openGoals(tester);

    expect(server.requests, contains('GET /api/v1/analytics/goals'));
    expect(find.byKey(const Key('no-goals')), findsOneWidget);
    expect(
      find.text(
        'No goals yet. Set a target for each week, month or year: distance, '
        'climbing, riding time or number of rides.',
      ),
      findsOneWidget,
    );
    // The way forward stays on the page.
    expect(find.byKey(const Key('add-goal')), findsOneWidget);
  });

  testWidgets('GoalsScreen_ShouldListGoalsAndNextEvent_WhenBothExist', (
    tester,
  ) async {
    server.goals.add({
      'id': 'goal-1',
      'period': 'week',
      'metric': 'distance',
      'target': 100000.0,
    });
    server.goalCurrent['distance'] = 40000;
    server.events.add(eventJson());
    await openGoals(tester);

    expect(find.byKey(const Key('goal-goal-1')), findsOneWidget);
    expect(find.text('Weekly distance'), findsOneWidget);
    expect(find.text('40.0 km of 100 km · 40 %'), findsOneWidget);
    expect(find.byKey(const Key('no-goals')), findsNothing);

    await reveal(tester, find.byKey(const Key('next-event')));
    expect(find.byKey(const Key('next-event')), findsOneWidget);
    expect(find.textContaining('Gran Fondo'), findsOneWidget);
    // The events page keeps its route.
    expect(find.byKey(const Key('all-events')), findsOneWidget);
  });

  testWidgets('GoalsScreen_ShouldAddGoal_WhenTheFormIsSaved', (tester) async {
    await openGoals(tester);

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
    expect(find.byKey(const Key('goal-goal-1')), findsOneWidget);
    expect(find.byKey(const Key('no-goals')), findsNothing);
  });

  testWidgets('GoalsScreen_ShouldSendGoalInMetres_WhenTargetIsInKm', (
    tester,
  ) async {
    server.goalCurrent['distance'] = 40000;
    await openGoals(tester);

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

  testWidgets('GoalsScreen_ShouldStoreMilesAsMetres_WhenUnitsAreImperial', (
    tester,
  ) async {
    server.accounts['rider@example.com']!.units = 'imperial';
    server.goalCurrent['distance'] = 40000;
    await openGoals(tester);

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

  testWidgets('GoalsScreen_ShouldUpdateAndDeleteGoal_WhenEditingGoal', (
    tester,
  ) async {
    server.goals.add({
      'id': 'goal-1',
      'period': 'month',
      'metric': 'time',
      'target': 36000.0,
    });
    server.goalCurrent['time'] = 36000;
    await openGoals(tester);
    expect(find.text('Reached'), findsOneWidget);

    // Edit and Delete live in the card's own menu now.
    await tester.tap(find.byKey(const Key('goal-menu-goal-1')));
    await tester.pumpAndSettle();
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

    await tester.tap(find.byKey(const Key('goal-menu-goal-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('goal-delete-goal-1')));
    await tester.pumpAndSettle();
    // Deleting asks first, and the button names what it does.
    await tester.tap(find.byKey(const Key('goal-delete-confirm')));
    await tester.pumpAndSettle();
    expect(server.goals, isEmpty);
    expect(find.byKey(const Key('no-goals')), findsOneWidget);
  });

  testWidgets('GoalsScreen_ShouldRejectEmptyTarget_WhenSavingGoal', (
    tester,
  ) async {
    await openGoals(tester);

    await tester.tap(find.byKey(const Key('add-goal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('goal-save')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a target above 0.'), findsOneWidget);
    expect(server.goals, isEmpty);
  });

  testWidgets(
    'GoalGauge_ShouldDrawAFullArcAndNoMore_WhenTheGoalIsReachedAndOver',
    (tester) async {
      late GoalGaugePainter painter;
      await tester.pumpWidget(
        MaterialApp(
          theme: nightTheme(),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return GoalGauge(progress: 1.7);
              },
            ),
          ),
        ),
      );
      await tester.pump();

      painter =
          tester
                  .widget<CustomPaint>(find.byKey(const Key('goal-gauge')))
                  .painter!
              as GoalGaugePainter;
      // Past the target the arc stops at the end instead of wrapping round.
      expect(painter.sweepFraction, 1.0);
      expect(find.text('170 %'), findsOneWidget);
    },
  );

  testWidgets(
    'GoalCard_ShouldSayWhatIsLeft_WhenRunningAndByHowMuch_WhenReached',
    (tester) async {
      server.goals.addAll([
        {
          'id': 'goal-1',
          'period': 'week',
          'metric': 'distance',
          'target': 100000.0,
        },
        {'id': 'goal-2', 'period': 'week', 'metric': 'rides', 'target': 3.0},
      ]);
      server.goalCurrent['distance'] = 60000;
      server.goalCurrent['rides'] = 5;
      await openGoals(tester);

      // Running: how far is left. Reached: by how much.
      expect(
        find.descendant(
          of: find.byKey(const Key('goal-goal-1')),
          matching: find.text('40.0 km to go'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('goal-goal-2')),
          matching: find.text('Reached by 2 rides'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('goal-reached-goal-2')), findsOneWidget);
      expect(find.byKey(const Key('goal-reached-goal-1')), findsNothing);
    },
  );

  testWidgets('GoalsScreen_ShouldOrderRunningGoalsFirst_WhenSomeAreReached', (
    tester,
  ) async {
    server.goals.addAll([
      {
        'id': 'goal-reached',
        'period': 'week',
        'metric': 'rides',
        'target': 1.0,
      },
      {
        'id': 'goal-running',
        'period': 'week',
        'metric': 'distance',
        'target': 100000.0,
      },
      {
        'id': 'goal-running-2',
        'period': 'month',
        'metric': 'elevation',
        'target': 5000.0,
      },
    ]);
    server.goalCurrent['rides'] = 4;
    server.goalCurrent['distance'] = 20000;
    server.goalCurrent['elevation'] = 1000;
    // A phone stacks the cards, so their order is their position down the page.
    await openGoals(tester, size: const Size(390, 2400));

    final running = tester
        .getTopLeft(find.byKey(const Key('goal-goal-running')))
        .dy;
    final reached = tester
        .getTopLeft(find.byKey(const Key('goal-goal-reached')))
        .dy;
    expect(running, lessThan(reached));
    // And the sentence under the title counts them.
    expect(find.byKey(const Key('goals-summary')), findsOneWidget);
    expect(find.text('2 goals running. One reached.'), findsOneWidget);
  });

  testWidgets(
    'GoalsScreen_ShouldShowTheEmptyStateAndAddGoal_WhenThereAreNoGoals',
    (tester) async {
      await openGoals(tester);

      expect(find.byKey(const Key('no-goals')), findsOneWidget);
      expect(find.byKey(const Key('add-goal')), findsOneWidget);
      // No summary when there is nothing to sum up.
      expect(find.byKey(const Key('goals-summary')), findsNothing);
    },
  );
}
