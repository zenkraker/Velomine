import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
    server.trainingPlan = {
      'on': true,
      'goal': 'fitter',
      'days': ['tuesday', 'thursday', 'sunday'],
      'hoursPerWeek': 6,
      'longRideDay': 'sunday',
    };
  });

  Future<void> openTraining(WidgetTester tester, {double width = 700}) async {
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/training');
    await tester.pumpAndSettle();
  }

  /// A week whose Monday is done with its score and whose Wednesday is still planned.
  Map<String, Object?> week() => {
    'weeks': [
      {
        'start': '2026-11-02',
        'end': '2026-11-08',
        'plannedLoad': 210.4,
        'isLighterWeek': false,
        'skipsThisWeek': 0,
        'note': null,
        'sessions': [
          trainingWeekSessionJson(
            's-mon',
            localDate: '2026-11-02',
            state: 'done',
            rideId: 'r1',
            result: sessionResultJson(),
          ),
          trainingWeekSessionJson(
            's-thu',
            localDate: '2026-11-05',
            state: 'planned',
          ),
        ],
      },
    ],
  };

  testWidgets(
    'TrainingScreen_ShouldReadOneOfTwoDoneWithAKindLine_WhenOneSessionIsDone',
    (tester) async {
      server.trainingWeek = week();

      await openTraining(tester);

      expect(find.byKey(const Key('training-this-week')), findsOneWidget);
      expect(find.text('Done · 92'), findsOneWidget);
      expect(find.text('1 of 2 done. Nicely on track.'), findsOneWidget);
      expect(find.text('Rest'), findsWidgets);
    },
  );

  testWidgets(
    'TrainingScreen_ShouldSayTheWholeWeekIsDone_WhenEverySessionIsDone',
    (tester) async {
      server.trainingWeek = {
        'weeks': [
          {
            'start': '2026-11-02',
            'end': '2026-11-08',
            'plannedLoad': 120.0,
            'isLighterWeek': false,
            'skipsThisWeek': 0,
            'skipsThisWeek': 0,
            'note': null,
            'sessions': [
              trainingWeekSessionJson(
                's-mon',
                localDate: '2026-11-02',
                state: 'done',
                rideId: 'r1',
                result: sessionResultJson(score: 100),
              ),
            ],
          },
        ],
      };

      await openTraining(tester);

      expect(find.text('Done · 100'), findsOneWidget);
      expect(
        find.text('1 of 1 done. That is the week, all of it.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'TrainingScreen_ShouldCountASessionMadeEasyAsDone_WhenItWasRidden',
    (tester) async {
      // A session made easy on the day and ticked by a ride is done: the week counts it, and the row says so.
      server.trainingWeek = {
        'weeks': [
          {
            'start': '2026-11-02',
            'end': '2026-11-08',
            'plannedLoad': 120.0,
            'isLighterWeek': false,
            'skipsThisWeek': 0,
            'skipsThisWeek': 0,
            'note': null,
            'sessions': [
              trainingWeekSessionJson(
                's-mon',
                localDate: '2026-11-02',
                state: 'easy',
                rideId: 'r1',
                result: sessionResultJson(score: 80),
              ),
              trainingWeekSessionJson(
                's-thu',
                localDate: '2026-11-05',
                state: 'planned',
              ),
            ],
          },
        ],
      };

      await openTraining(tester);

      expect(find.text('Easy instead'), findsOneWidget);
      expect(find.text('1 of 2 done. Nicely on track.'), findsOneWidget);
    },
  );

  testWidgets(
    'SessionScreen_ShouldShowTheScoreAndPlannedBesideDone_WhenTheSessionIsDone',
    (tester) async {
      server.trainingWeek = week();

      await openTraining(tester);
      await tester.tap(find.byKey(const Key('training-day-2026-11-02')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('session-how-it-went')), findsOneWidget);
      expect(find.byKey(const Key('session-score')), findsOneWidget);
      expect(find.text('92'), findsOneWidget);
      expect(
        find.text('Right on plan. That is how it should feel.'),
        findsOneWidget,
      );
      expect(
        find.text('1 h 00 min planned · 1 h 00 min ridden'),
        findsOneWidget,
      );
      expect(find.text('58 planned · 56 ridden'), findsOneWidget);
      expect(find.text('228 W planned · 224 W ridden'), findsOneWidget);
      expect(find.text('Open the ride →'), findsOneWidget);
    },
  );

  testWidgets('SessionScreen_ShouldShowNoScore_WhenTheSessionIsStillPlanned', (
    tester,
  ) async {
    server.trainingWeek = week();

    await openTraining(tester);
    await tester.tap(find.byKey(const Key('training-day-2026-11-05')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('session-how-it-went')), findsNothing);
    expect(find.byKey(const Key('session-why')), findsOneWidget);
    expect(find.byKey(const Key('session-blocks')), findsOneWidget);
    // The leading number is bold, so the block reads it and the other two as its own line.
    expect(find.text('220–235 W'), findsOneWidget);
    expect(find.text(' · 152–160 bpm · feel 5–6'), findsOneWidget);
  });
}
