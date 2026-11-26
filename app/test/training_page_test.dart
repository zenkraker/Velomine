import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/widgets/loading_state.dart';
import 'package:velomine/core/widgets/week_day_row.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;
  final today = DateUtils.dateOnly(DateTime.now());
  final monday = weekStart(today);

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
    server.trainingPlan = {
      'on': true,
      'goal': 'fitter',
      'days': ['tuesday', 'thursday', 'sunday'],
      'hoursPerWeek': 6,
      'lastPlannedFor': fakeDay(monday),
    };
  });

  /// The Training page, with [sessions] on their days of this week.
  Future<void> openTraining(
    WidgetTester tester, {
    List<Map<String, Object?>> sessions = const [],
    bool on = true,
    double width = 700,
  }) async {
    if (!on) server.trainingPlan = {...server.trainingPlan!, 'on': false};
    server.trainingWeeks = [
      trainingWeekJson(start: monday, sessions: sessions),
    ];
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/training');
  }

  /// A session of 75 minutes, whose main set is 40 minutes at 220–235 W.
  Map<String, Object?> session({
    DateTime? date,
    String state = 'planned',
    List<Map<String, Object?>>? blocks,
    List<Map<String, Object?>> notes = const [],
    bool estimated = false,
  }) => trainingSessionJson(
    date: date ?? today,
    state: state,
    blocks:
        blocks ??
        [
          trainingBlockJson(
            role: 'warmup',
            minutes: 15,
            wattsLow: 140,
            wattsHigh: 185,
            heartRateLow: 115,
            heartRateHigh: 140,
            feelLow: 2,
            feelHigh: 3,
          ),
          trainingBlockJson(),
          trainingBlockJson(
            role: 'cooldown',
            minutes: 20,
            wattsLow: 140,
            wattsHigh: 140,
            heartRateLow: 125,
            heartRateHigh: 125,
            feelLow: 2,
            feelHigh: 2,
          ),
        ],
    notes: notes,
    heartRateEstimated: estimated,
  );

  testWidgets(
    'TrainingScreen_ShouldShowTheSessionsNameLengthAndTargets_WhenTodayHasASession',
    (tester) async {
      await openTraining(tester, sessions: [session()]);

      expect(find.byKey(const Key('training-today')), findsOneWidget);
      expect(find.text('Today · ${_weekday(today)}'), findsOneWidget);
      // The today card and today's row of the week both name it.
      expect(find.text('Strong and steady 3×10'), findsWidgets);
      expect(find.text('1 h 15'), findsOneWidget);
      expect(find.text('Long efforts just below your limit.'), findsOneWidget);
      // The main set's three targets, the watts leading.
      expect(find.text('220–235 W · 152–160 bpm · feel 5–6'), findsOneWidget);
      expect(find.byKey(const Key('training-open-session')), findsOneWidget);
    },
  );

  testWidgets(
    'TrainingScreen_ShouldShowTheServersItalianWords_WhenTheLanguageIsItalian',
    (tester) async {
      server = FakeServer();
      server.signInBrowser(server.add('rider@example.com', language: 'it'));
      server.trainingPlan = {
        'on': true,
        'goal': 'fitter',
        'days': ['tuesday'],
        'hoursPerWeek': 6,
        'lastPlannedFor': fakeDay(monday),
      };
      await openTraining(tester, sessions: [session()]);

      expect(find.text('Forte e costante 3×10'), findsWidgets);
      expect(
        find.text('Sforzi lunghi appena sotto il limite.'),
        findsOneWidget,
      );
      // The app's own words around them are Italian too.
      expect(find.text('Questa settimana'), findsOneWidget);
      expect(find.textContaining('Oggi · '), findsOneWidget);
      expect(find.text('Strong and steady 3×10'), findsNothing);
    },
  );

  testWidgets(
    'TrainingScreen_ShouldShowTheLoadingState_WhenTheWeekHasNotAnsweredYet',
    (tester) async {
      final gate = server.delayNext('/api/v1/training/week');
      await openTraining(tester, sessions: [session()]);
      expect(find.byType(LoadingState), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(LoadingState), findsNothing);
      expect(find.byKey(const Key('training-today')), findsOneWidget);
    },
  );

  testWidgets('TrainingScreen_ShouldOfferToTryAgain_WhenTheWeekDidNotArrive', (
    tester,
  ) async {
    server.broken.add('/api/v1/training/week');
    addTearDown(server.broken.clear);
    await openTraining(tester, sessions: [session()]);

    expect(find.byKey(const Key('training-error')), findsOneWidget);
    expect(
      find.text('Could not load your training plan (500). Try again.'),
      findsOneWidget,
    );

    server.broken.remove('/api/v1/training/week');
    await tester.tap(find.byKey(const Key('training-error')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('training-error')), findsNothing);
    expect(find.byKey(const Key('training-today')), findsOneWidget);
  });

  testWidgets('TrainingScreen_ShouldSayRestDay_WhenTodayHasNoSession', (
    tester,
  ) async {
    // A session later in the week, never today.
    final other = DateUtils.addDaysToDate(monday, (today.weekday % 7));
    await openTraining(tester, sessions: [session(date: other)]);

    expect(find.byKey(const Key('training-today-rest')), findsOneWidget);
    expect(find.text('Rest day'), findsOneWidget);
    expect(
      find.text('Nothing today. Rest is part of the plan.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('training-open-session')), findsNothing);
  });

  testWidgets(
    'TrainingScreen_ShouldNameTheFirstDayOfTheWeek_WhenNoWeekHasBeenPlanned',
    (tester) async {
      server.trainingPlan = {
        'on': true,
        'goal': 'fitter',
        'days': ['tuesday'],
        'hoursPerWeek': 6,
        'lastPlannedFor': null,
      };
      await openTraining(tester);

      expect(find.byKey(const Key('training-plan-starts')), findsOneWidget);
      expect(find.text('Your plan starts Monday.'), findsOneWidget);
      expect(find.text('Rest day'), findsNothing);
      expect(find.byKey(const Key('training-this-week')), findsNothing);
    },
  );

  testWidgets(
    'TrainingScreen_ShouldBadgeEachDaysState_WhenTheWeekIsPartlyDone',
    (tester) async {
      final tuesday = DateUtils.addDaysToDate(monday, 1);
      final wednesday = DateUtils.addDaysToDate(monday, 2);
      final thursday = DateUtils.addDaysToDate(monday, 3);
      await openTraining(
        tester,
        sessions: [
          session(date: tuesday, state: 'done'),
          session(date: wednesday, state: 'moved'),
          session(date: thursday, state: 'skipped'),
          session(state: 'planned'),
        ],
      );

      expect(find.byKey(const Key('training-this-week')), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Moved'), findsOneWidget);
      expect(find.text('Skipped'), findsOneWidget);
      expect(
        find.text('1 of 4 done. A good start to the week.'),
        findsOneWidget,
      );
      // A planned day carries no badge, and a day without a session says Rest.
      expect(find.text('Planned'), findsNothing);
      expect(find.text('Rest'), findsWidgets);
    },
  );

  testWidgets(
    'TrainingScreen_ShouldPreviewNextWeek_WhenTheServerSendsItOnTheLastDay',
    (tester) async {
      final next = DateUtils.addDaysToDate(monday, 7);
      server.trainingWeeks = [
        trainingWeekJson(start: monday, sessions: [session()]),
        trainingWeekJson(
          start: next,
          sessions: [
            trainingSessionJson(
              id: 'next-1',
              date: DateUtils.addDaysToDate(next, 1),
              minutes: 60,
              englishName: 'Easy ride',
              italianName: 'Giro tranquillo',
            ),
          ],
        ),
      ];
      tester.view.physicalSize = const Size(700, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));
      await goTo(tester, '/training');

      expect(find.byKey(const Key('training-next-week')), findsOneWidget);
      expect(find.text('Next week (preview)'), findsOneWidget);
    },
  );

  testWidgets(
    'TrainingScreen_ShouldShowTheReasonsGoalOnly_WhenTheGoalInForceIsTheSuggestedOne',
    (tester) async {
      server.trainingPlan = {...server.trainingPlan!, 'goal': 'fitter'};
      server.suggestedTrainingGoal = 'fitter';
      server.trainingSuggestionReason = 'regular_rider';
      await openTraining(tester, sessions: [session()]);

      expect(find.text('Get fitter'), findsWidgets);
      expect(find.byKey(const Key('training-goal-reason')), findsOneWidget);
      expect(
        find.text(
          'You ride regularly. We build both your base and a little speed.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'TrainingScreen_ShouldSayTheGoalsOwnLine_WhenTheGoalChosenIsAnother',
    (tester) async {
      // The rider picked faster riding; the reason the server sends belongs to the goal it suggested.
      server.trainingPlan = {...server.trainingPlan!, 'goal': 'faster'};
      server.suggestedTrainingGoal = 'fitter';
      server.trainingSuggestionReason = 'regular_riding';
      await openTraining(tester, sessions: [session()]);

      expect(find.text('Get faster'), findsOneWidget);
      // TrainingPage.md: the goal card is "the goal's name, its one-line reason".
      expect(
        find.text('On climbs and on the flat'),
        findsOneWidget,
        reason: 'the chosen goal says what it means',
      );
      expect(find.textContaining('Regular riding comes before'), findsNothing);
    },
  );

  testWidgets(
    'TrainingScreen_ShouldDrawTheNextWeekRowsPlain_WhenTheServerSendsThePreview',
    (tester) async {
      final next = DateUtils.addDaysToDate(monday, 7);
      server.trainingWeeks = [
        trainingWeekJson(start: monday, sessions: [session()]),
        trainingWeekJson(
          start: next,
          sessions: [
            trainingSessionJson(
              id: 'next-1',
              date: DateUtils.addDaysToDate(next, 1),
              minutes: 60,
              englishName: 'Easy ride',
              italianName: 'Giro tranquillo',
            ),
          ],
        ),
      ];
      tester.view.physicalSize = const Size(700, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));
      await goTo(tester, '/training');

      final previewRow = tester
          .widgetList<WeekDayRow>(
            find.descendant(
              of: find.byKey(const Key('training-next-week')),
              matching: find.byType(WeekDayRow),
            ),
          )
          .singleWhere((row) => row.title == 'Easy ride');
      expect(previewRow.onTap, isNull);
      // This week's own rows still open their session: only the preview is plain.
      final weekRow = tester
          .widgetList<WeekDayRow>(
            find.descendant(
              of: find.byKey(const Key('training-this-week')),
              matching: find.byType(WeekDayRow),
            ),
          )
          .singleWhere((row) => row.title == 'Strong and steady 3×10');
      expect(weekRow.onTap, isNotNull);
    },
  );

  testWidgets(
    'SessionScreen_ShouldShowEveryBlockAndExplainFeelOnce_WhenTheSessionIsOpened',
    (tester) async {
      await openTraining(tester, sessions: [session()]);
      await tester.tap(find.byKey(const Key('training-open-session')));
      await tester.pumpAndSettle();

      expect(find.text('Why this session'), findsOneWidget);
      expect(find.text('Coaches call this Sweet spot.'), findsOneWidget);
      expect(find.text('The session'), findsOneWidget);
      for (final role in ['Warm-up', 'Main set', 'Cool-down']) {
        expect(find.text(role), findsOneWidget, reason: role);
      }
      expect(find.text('220–235 W'), findsOneWidget);
      expect(find.text(' · 152–160 bpm · feel 5–6'), findsOneWidget);
      expect(
        find.text('Feel 7: hard, you could hold it about an hour.'),
        findsOneWidget,
      );
      // The heart rate is the threshold in use, not an estimate.
      expect(find.byKey(const Key('session-heart-estimated')), findsNothing);
    },
  );

  testWidgets(
    'SessionScreen_ShouldShowNoWattTargetAndThePowerMeterLine_WhenTheRiderHasNoPowerMeter',
    (tester) async {
      await openTraining(
        tester,
        sessions: [
          session(
            blocks: [
              trainingBlockJson(
                role: 'warmup',
                minutes: 15,
                wattsLow: null,
                wattsHigh: null,
                heartRateLow: 115,
                heartRateHigh: 140,
                feelLow: 2,
                feelHigh: 3,
              ),
              trainingBlockJson(wattsLow: null, wattsHigh: null),
            ],
            notes: [trainingNoteJson('add_power_meter')],
          ),
        ],
      );
      await tester.tap(find.byKey(const Key('training-open-session')));
      await tester.pumpAndSettle();

      expect(find.text('220–235 W'), findsNothing);
      expect(find.textContaining(' W'), findsNothing);
      expect(find.text('Add a power meter for watt targets'), findsOneWidget);
      // The line the rider can follow leads instead: heart rate, then feel.
      expect(find.text('152–160 bpm'), findsOneWidget);
    },
  );

  testWidgets(
    'SessionScreen_ShouldMarkHeartRateAsEstimated_WhenTheServerSaysItIs',
    (tester) async {
      await openTraining(tester, sessions: [session(estimated: true)]);
      await tester.tap(find.byKey(const Key('training-open-session')));
      await tester.pumpAndSettle();

      expect(find.textContaining('152–160 bpm (estimated)'), findsWidgets);
      expect(
        find.text('Heart rate estimated from your maximum.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('ProgressScreen_ShouldShowTodaysSession_WhenAutoTrainingIsOn', (
    tester,
  ) async {
    await openTraining(tester, sessions: [session()]);
    await goTo(tester, '/progress');

    expect(find.byKey(const Key('progress-today-training')), findsOneWidget);
    expect(
      find.text('Today · Strong and steady 3×10 · 1 h 15'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('progress-today-training')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('training-today')), findsOneWidget);
  });

  testWidgets('ProgressScreen_ShouldHideTheTodayStrip_WhenAutoTrainingIsOff', (
    tester,
  ) async {
    await openTraining(tester, sessions: [session()], on: false);
    await goTo(tester, '/progress');

    expect(find.byKey(const Key('progress-today-training')), findsNothing);
  });

  for (final width in [390.0, 600.0, 820.0, 1300.0]) {
    testWidgets(
      'TrainingScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
        final tuesday = DateUtils.addDaysToDate(monday, 1);
        await openTraining(
          tester,
          width: width,
          sessions: [
            session(date: tuesday, state: 'done'),
            session(state: 'planned'),
          ],
        );
        await tester.pumpAndSettle();
      },
    );

    testWidgets('SessionScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}', (
      tester,
    ) async {
      await openTraining(
        tester,
        width: width,
        sessions: [
          session(estimated: true, notes: [trainingNoteJson('set_ftp')]),
        ],
      );
      await tester.tap(find.byKey(const Key('training-open-session')));
      await tester.pumpAndSettle();
    });
  }
}

/// The weekday as the page writes it: "Thursday".
String _weekday(DateTime date) => const [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][date.weekday - 1];
