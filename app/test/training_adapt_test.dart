import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show Intl;
import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';
import 'package:velomine/features/notifications/notifications_text.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';

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

  /// The Training page with [sessions] on their days of this week.
  Future<void> openTraining(
    WidgetTester tester, {
    required List<Map<String, Object?>> sessions,
    double width = 390,
  }) async {
    server.trainingWeeks = [
      trainingWeekJson(start: monday, sessions: sessions),
    ];
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/training');
  }

  /// The days left this week from today, the way the server offers them to the move sheet.
  List<Map<String, Object?>> moveDays({bool withLongRideBeside = true}) => [
    for (var i = 1; i <= 6 - today.weekday + 1; i++)
      if (DateUtils.addDaysToDate(
        today,
        i,
      ).isBefore(DateUtils.addDaysToDate(monday, 7)))
        moveDayJson(
          fakeDay(DateUtils.addDaysToDate(today, i)),
          allowed: !(withLongRideBeside && i == 1),
          reason: withLongRideBeside && i == 1 ? 'next_to_long_ride' : null,
        ),
  ];

  testWidgets(
    'TrainingScreen_ShouldSayWhyTodayIsEasy_WhenTheSessionWasMadeEasy',
    (tester) async {
      await openTraining(
        tester,
        sessions: [
          trainingSessionJson(
            date: today,
            state: 'easy',
            recipe: 'R02',
            englishName: 'Easy ride',
            easyReason: 'slept_poorly',
            easyMovedTo: DateUtils.addDaysToDate(today, 2),
          ),
        ],
      );

      expect(
        find.text(
          'Easy today: you slept poorly. The hard day moves to '
          '${['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][DateUtils.addDaysToDate(today, 2).weekday - 1]}.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('TrainingScreen_ShouldSayNothing_WhenTodayIsAsPlanned', (
    tester,
  ) async {
    await openTraining(tester, sessions: [trainingSessionJson(date: today)]);

    expect(find.byKey(const Key('training-today-reason')), findsNothing);
  });

  testWidgets('TrainingScreen_ShouldMakeTodayEasy_WhenTheRiderTapsTheButton', (
    tester,
  ) async {
    await openTraining(
      tester,
      sessions: [trainingSessionJson(date: today, canMakeEasy: true)],
    );

    await tester.tap(find.byKey(const Key('training-make-easy')));
    await tester.pumpAndSettle();

    expect(server.sessionActions, hasLength(1));
    expect(server.sessionActions.single['what'], 'easy');
    expect(server.sessionActions.single['sessionId'], 'session-1');
  });

  testWidgets('TrainingScreen_ShouldNotOfferMakeEasy_WhenTodayIsAlreadyEasy', (
    tester,
  ) async {
    await openTraining(
      tester,
      sessions: [
        trainingSessionJson(
          date: today,
          state: 'easy',
          recipe: 'R02',
          easyReason: 'slept_poorly',
        ),
      ],
    );

    expect(find.byKey(const Key('training-make-easy')), findsNothing);
    expect(find.byKey(const Key('training-open-session')), findsOneWidget);
  });

  testWidgets(
    'SessionScreen_ShouldOfferMakeEasyMoveAndSkip_WhenTheSessionIsStillToBeRidden',
    (tester) async {
      await openTraining(
        tester,
        sessions: [
          trainingSessionJson(date: today, canMakeEasy: true, move: moveDays()),
        ],
      );
      await tester.tap(find.byKey(const Key('training-open-session')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('session-menu')));
      await tester.pumpAndSettle();

      expect(find.text('Make today easy'), findsOneWidget);
      expect(find.text('Move'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Back to the plan'), findsNothing);
    },
  );

  testWidgets('SessionScreen_ShouldOfferBackToThePlan_WhenTodayWasMadeEasy', (
    tester,
  ) async {
    await openTraining(
      tester,
      sessions: [
        trainingSessionJson(
          date: today,
          state: 'easy',
          recipe: 'R02',
          easyReason: 'asked',
        ),
      ],
    );
    await tester.tap(find.byKey(const Key('training-open-session')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('session-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to the plan'));
    await tester.pumpAndSettle();

    expect(server.sessionActions.single['what'], 'back');
  });

  testWidgets(
    'SessionScreen_ShouldDisableTheDayWithTheReason_WhenTheMoveSheetOpens',
    (tester) async {
      await openTraining(
        tester,
        sessions: [trainingSessionJson(date: today, move: moveDays())],
      );
      await tester.tap(find.byKey(const Key('training-open-session')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('session-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move'));
      await tester.pumpAndSettle();

      expect(find.text('Next to the long ride'), findsOneWidget);
      // The nearest day that works is offered under the days.
      expect(find.byKey(const Key('move-nearest')), findsOneWidget);
    },
  );

  testWidgets('SessionScreen_ShouldMoveTheSession_WhenTheRiderPicksADay', (
    tester,
  ) async {
    await openTraining(
      tester,
      sessions: [trainingSessionJson(date: today, move: moveDays())],
    );
    await tester.tap(find.byKey(const Key('training-open-session')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('session-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('move-nearest')));
    await tester.pumpAndSettle();

    final action = server.sessionActions.single;
    expect(action['what'], 'move');
    expect(action['localDate'], isNotNull);
  });

  testWidgets('SessionScreen_ShouldSkipWithTheReason_WhenTheRiderPicksTired', (
    tester,
  ) async {
    await openTraining(tester, sessions: [trainingSessionJson(date: today)]);
    await tester.tap(find.byKey(const Key('training-open-session')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('session-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('skip-tired')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('skip-session')));
    await tester.pumpAndSettle();

    expect(server.sessionActions.single['what'], 'skip');
    expect(server.sessionActions.single['reason'], 'tired');
    expect(server.sessionActions.single['restOfWeek'], false);
  });

  testWidgets(
    'SessionScreen_ShouldAskAboutTheRestOfTheWeek_WhenTheServerSaysItIsTheSecondSkip',
    (tester) async {
      server.askRestOfWeekOnSkip = true;
      await openTraining(tester, sessions: [trainingSessionJson(date: today)]);
      await tester.tap(find.byKey(const Key('training-open-session')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('session-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('skip-session')));
      await tester.pumpAndSettle();

      // "Skip the rest of this week?" is asked, and saying yes skips the week.
      expect(find.text('Skip the rest of this week?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('skip-rest-of-week')));
      await tester.pumpAndSettle();

      expect(server.sessionActions, hasLength(2));
      expect(server.sessionActions.last['restOfWeek'], true);
    },
  );

  testWidgets('SessionScreen_ShouldNotOverflow_WhenTheMenuIsOpenAtWidth390', (
    tester,
  ) async {
    await openTraining(
      tester,
      sessions: [
        trainingSessionJson(date: today, canMakeEasy: true, move: moveDays()),
      ],
    );
    await tester.tap(find.byKey(const Key('training-open-session')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('session-menu')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('SessionScreen_ShouldNotOverflow_WhenTheMoveSheetIsOpen', (
    tester,
  ) async {
    await openTraining(
      tester,
      sessions: [trainingSessionJson(date: today, move: moveDays())],
    );
    await tester.tap(find.byKey(const Key('training-open-session')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('session-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  test(
    'NotificationText_ShouldSayWhyTodayIsEasy_WhenTheNoticeCarriesTheReason',
    () async {
      await initializeDateFormatting('en');
      await initializeDateFormatting('it');
      NotificationResponse note(String type, TrainingSessionNotice notice) =>
          NotificationResponse(
            id: 'n1',
            type: type,
            subject: notice.easyReason ?? notice.englishName,
            rideId: null,
            plannedRideId: null,
            bikeId: null,
            componentId: null,
            aboutUserId: null,
            createdAt: DateTime.utc(2026, 11, 24),
            isRead: false,
            notice: Optional.present(notice),
          );
      final notice = TrainingSessionNotice(
        sessionId: 's-1',
        localDate: DateTime(2026, 11, 24),
        minutes: 60,
        recipe: 'R02',
        englishName: 'Easy ride',
        italianName: 'Giro tranquillo',
        state: 'easy',
        skipReason: null,
        easyReason: 'slept_poorly',
        easyMovedTo: DateTime(2026, 11, 26),
      );

      Intl.defaultLocale = 'en';
      final en = lookupAppLocalizations(const Locale('en'));
      expect(
        notificationText(en, note('training_easy', notice)),
        'Easy today: you slept poorly. The hard day moves to Thursday.',
      );
      expect(
        notificationText(en, note('training_today', notice)),
        'Today: Easy ride.',
      );
      expect(
        notificationTarget(note('training_easy', notice)),
        '/training/sessions/s-1',
      );
      expect(notificationTarget(note('training_today', notice)), '/training');

      Intl.defaultLocale = 'it';
      final it = lookupAppLocalizations(const Locale('it'));
      expect(
        notificationText(it, note('training_easy', notice)),
        'Oggi facile: hai dormito male. Il giorno duro si sposta a giovedì.',
      );
      expect(
        notificationText(it, note('training_today', notice)),
        'Oggi: Giro tranquillo.',
      );
      Intl.defaultLocale = null;
    },
  );

  testWidgets('TrainingScreen_ShouldNotOverflow_WhenTodayChangedAtWidth390', (
    tester,
  ) async {
    await openTraining(
      tester,
      width: 390,
      sessions: [
        trainingSessionJson(
          date: today,
          state: 'easy',
          recipe: 'R02',
          easyReason: 'slept_poorly',
          easyMovedTo: DateUtils.addDaysToDate(today, 2),
        ),
        trainingSessionJson(
          id: 'session-2',
          date: DateUtils.addDaysToDate(today, 2),
          canMakeEasy: false,
        ),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('training-today-reason')), findsOneWidget);
  });

  testWidgets(
    'TrainingScreen_ShouldNotOverflow_WhenTodayCanBeMadeEasyAtWidth1300',
    (tester) async {
      await openTraining(
        tester,
        width: 1300,
        sessions: [
          trainingSessionJson(date: today, canMakeEasy: true, move: moveDays()),
        ],
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('training-make-easy')), findsOneWidget);
    },
  );
}
