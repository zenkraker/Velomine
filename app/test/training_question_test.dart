import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

/// The card on a ride's page that asks whether the ride was the session planned for the day before or after.
void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
    server.trainingPlan = {'on': true, 'goal': 'fitter', 'hoursPerWeek': 6};
  });

  Future<void> openRide(
    WidgetTester tester, {
    Map<String, Object?>? training,
  }) async {
    server.rides.add(
      rideJson(
        'r1',
        'ready',
        startTime: '2026-11-04T07:30:00Z',
        distanceM: 42300,
        movingS: 3600,
        avgPowerW: 200,
        training: training,
      ),
    );
    tester.view.physicalSize = const Size(1000, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.byKey(const Key('ride-r1')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'RideDetail_ShouldAskWhetherItWasTheSession_WhenOneWasPlannedForYesterday',
    (tester) async {
      await openRide(
        tester,
        training: trainingRideMatchJson('s1', localDate: '2026-11-03'),
      );

      expect(find.byKey(const Key('training-question')), findsOneWidget);
      expect(
        find.text('Was this your Tuesday strong and steady?'),
        findsOneWidget,
      );
      expect(
        find.text('This ride looks like the session planned for yesterday.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'RideDetail_ShouldSayTomorrow_WhenTheSessionIsPlannedForTheDayAfter',
    (tester) async {
      await openRide(
        tester,
        training: trainingRideMatchJson('s1', localDate: '2026-11-05'),
      );

      expect(
        find.text('This ride looks like the session planned for tomorrow.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('RideDetail_ShouldTickTheSession_WhenTheRiderSaysYes', (
    tester,
  ) async {
    await openRide(
      tester,
      training: trainingRideMatchJson('s1', localDate: '2026-11-03'),
    );

    await tester.tap(find.byKey(const Key('training-question-yes')));
    await tester.pumpAndSettle();

    expect(server.sessionAnswers, [
      {'sessionId': 's1', 'rideId': 'r1', 'answer': 'yes'},
    ]);
  });

  testWidgets('RideDetail_ShouldDeclineTheSession_WhenTheRiderSaysNo', (
    tester,
  ) async {
    await openRide(
      tester,
      training: trainingRideMatchJson('s1', localDate: '2026-11-03'),
    );

    await tester.tap(find.byKey(const Key('training-question-no')));
    await tester.pumpAndSettle();

    expect(server.sessionAnswers, [
      {'sessionId': 's1', 'rideId': 'r1', 'answer': 'no'},
    ]);
  });

  testWidgets(
    'RideDetail_ShouldNameTheSessionItWasAndOfferTheWayBack_WhenTheSessionIsDone',
    (tester) async {
      await openRide(
        tester,
        training: trainingRideMatchJson(
          's1',
          localDate: '2026-11-04',
          state: 'done',
        ),
      );

      expect(
        find.text('This was your Wednesday strong and steady.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('training-question-yes')), findsNothing);

      await tester.tap(find.byKey(const Key('training-not-this-session')));
      await tester.pumpAndSettle();

      expect(server.sessionAnswers.single['answer'], 'no');
    },
  );

  testWidgets('RideDetail_ShouldShowNoCard_WhenTheRideIsNoSession', (
    tester,
  ) async {
    await openRide(tester);

    expect(find.byKey(const Key('training-question')), findsNothing);
  });

  testWidgets(
    'NotificationsScreen_ShouldAskInTheInbox_WhenARideMightBeASession',
    (tester) async {
      server.rides.add(rideJson('r1', 'ready', movingS: 3600));
      server.notifications.add(
        notificationJson(
          'n1',
          'training_session_question',
          'Strong and steady',
          rideId: 'r1',
          training: trainingRideMatchJson('s1', localDate: '2026-11-03'),
        ),
      );

      await startApp(tester, server.session(useCookies: true));
      await goTo(tester, '/notifications');
      await tester.pumpAndSettle();

      expect(
        find.text('Was this your Tuesday strong and steady?'),
        findsOneWidget,
      );
    },
  );
}
