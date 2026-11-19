import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
  });

  /// An event that is a whole number of weeks away, so the card reads the same on any day the test runs.
  Map<String, Object?> eventJson({
    String id = 'event-1',
    String name = 'Gran Fondo',
    int daysFromToday = 10,
    String kind = 'sportive',
    double? distanceM = 120000,
    String? rideId,
  }) {
    final date = DateUtils.dateOnly(DateTime.now())
        .add(Duration(days: daysFromToday));
    final day =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return {
      'id': id,
      'name': name,
      'date': day,
      'kind': kind,
      'distanceM': distanceM,
      'elevationGainM': null,
      'notes': null,
      'rideId': rideId,
      'createdAt': '2026-11-10T09:00:00Z',
    };
  }

  Future<void> openProgress(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
  }

  /// The events page, by its address.
  Future<void> openEvents(WidgetTester tester) async {
    await goTo(tester, '/progress/events');
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('NextEventCard_ShouldSayHowFarAwayItIs_WhenThereIsANextEvent', (
    tester,
  ) async {
    server.events.add(eventJson());

    await openProgress(tester);
    await reveal(tester, find.byKey(const Key('next-event')));

    expect(find.textContaining('Gran Fondo'), findsWidgets);
    expect(find.textContaining('in 1 week'), findsWidgets);
  });

  testWidgets('NextEventCard_ShouldSayToday_WhenTheEventIsToday', (
    tester,
  ) async {
    server.events.add(eventJson(daysFromToday: 0));

    await openProgress(tester);
    await reveal(tester, find.byKey(const Key('next-event')));

    expect(find.textContaining('today'), findsWidgets);
  });

  testWidgets('ProgressScreen_ShouldNotShowAnEventCard_WhenThereIsNoEvent', (
    tester,
  ) async {
    await openProgress(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('next-event')), findsNothing);
  });

  testWidgets('AllEvents_ShouldOpen_WhenTheCardIsTapped', (tester) async {
    server.events.add(eventJson());

    await openProgress(tester);
    await reveal(tester, find.byKey(const Key('all-events')));
    await tester.tap(find.byKey(const Key('all-events')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-event')), findsOneWidget);
    expect(find.text('Gran Fondo'), findsOneWidget);
  });

  testWidgets('EventsScreen_ShouldAddAnEvent_WhenTheFormIsSaved', (
    tester,
  ) async {
    await openProgress(tester);
    await openEvents(tester);

    await tester.tap(find.byKey(const Key('add-event')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('event-name')),
      'Tour of the Lakes',
    );
    await tester.tap(find.byKey(const Key('event-save')));
    await tester.pumpAndSettle();

    expect(server.eventWrites.single, 'add event-1');
    expect(find.text('Tour of the Lakes'), findsOneWidget);
  });

  testWidgets(
    'EventsScreen_ShouldRefuseAnEventWithoutAName_WhenTheFormIsSaved',
    (tester) async {
      await openProgress(tester);
      await openEvents(tester);

      await tester.tap(find.byKey(const Key('add-event')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('event-save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event-save')), findsOneWidget);
      expect(server.eventWrites, isEmpty);
    },
  );

  testWidgets('EventsScreen_ShouldAskBeforeDeleting_WhenTheMenuSaysDelete', (
    tester,
  ) async {
    server.events.add(eventJson());

    await openProgress(tester);
    await openEvents(tester);

    await tester.tap(find.byKey(const Key('event-actions-event-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('event-delete-event-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('confirm-delete-event')), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-delete-event')));
    await tester.pumpAndSettle();

    expect(server.eventWrites.single, 'delete event-1');
    expect(find.byKey(const Key('event-event-1')), findsNothing);
  });

  testWidgets('EventsScreen_ShouldLinkTheRide_WhenOneIsPicked', (tester) async {
    final event = eventJson();
    server.events.add(event);
    server.rides.add(
      rideJson(
        'ride-1',
        'ready',
        startTime: '${event['date']}T09:00:00Z',
        utcOffsetMinutes: 0,
        distanceM: 30000,
        movingS: 3600,
      ),
    );
    await openProgress(tester);
    await openEvents(tester);

    await tester.tap(find.byKey(const Key('event-actions-event-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('event-link-event-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pick-ride-ride-1')));
    await tester.pumpAndSettle();

    expect(server.eventWrites, contains('ride event-1'));
    expect(server.events.single['rideId'], 'ride-1');
  });

  testWidgets(
    'EventsScreen_ShouldOfferTheLastPageRide_WhenTheDayHasMoreRidesThanOnePage',
    (tester) async {
      final event = eventJson();
      server.events.add(event);
      // More than the first page of the day's rides: the 51st is only on the second one.
      for (var i = 1; i <= 51; i++) {
        server.rides.add(
          rideJson(
            'ride-$i',
            'ready',
            startTime: '${event['date']}T09:00:00Z',
            utcOffsetMinutes: 0,
          ),
        );
      }
      await openProgress(tester);
      await openEvents(tester);

      await tester.tap(find.byKey(const Key('event-actions-event-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('event-link-event-1')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('pick-ride-ride-51')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pick-ride-ride-51')));
      await tester.pumpAndSettle();

      expect(server.events.single['rideId'], 'ride-51');
    },
  );

  testWidgets(
    "EventsScreen_ShouldNotOpenThePicker_WhenTheDay'sRidesCannotBeRead",
    (tester) async {
      server.events.add(eventJson());
      await openProgress(tester);
      await openEvents(tester);

      server.broken.add('/api/v1/rides');
      addTearDown(() => server.broken.clear());
      await tester.tap(find.byKey(const Key('event-actions-event-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('event-link-event-1')));
      await tester.pumpAndSettle();

      // The failure is said, and the picker never opens claiming the day has no rides.
      expect(find.byKey(const Key('no-rides-that-day')), findsNothing);
      expect(
        find.text('Could not load your rides (500). Try again.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('EventsScreen_ShouldUnlinkTheRide_WhenTheMenuSaysUnlink', (
    tester,
  ) async {
    server.events.add(eventJson(rideId: 'ride-1'));
    await openProgress(tester);
    await openEvents(tester);

    await tester.tap(find.byKey(const Key('event-actions-event-1')));
    await tester.pumpAndSettle();
    // Unlinking is not destructive: it says what it does and does it.
    await tester.tap(find.byKey(const Key('event-unlink-event-1')));
    await tester.pumpAndSettle();

    expect(server.eventWrites, contains('ride event-1'));
    expect(server.events.single['rideId'], isNull);
  });

  testWidgets('EventsScreen_ShouldPickTheRide_WhenTheLanguageIsItalian', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = [const Locale('it')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final event = eventJson();
    server.events.add(event);
    server.rides.add(
      rideJson(
        'ride-1',
        'ready',
        startTime: '${event['date']}T09:00:00Z',
        utcOffsetMinutes: 0,
      ),
    );
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await openEvents(tester);

    await tester.tap(find.byKey(const Key('event-actions-event-1')));
    await tester.pumpAndSettle();
    expect(find.text("Collega un'uscita"), findsOneWidget);
    await tester.tap(find.byKey(const Key('event-link-event-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pick-ride-ride-1')));
    await tester.pumpAndSettle();

    expect(server.events.single['rideId'], 'ride-1');
  });

  testWidgets('RideDetailScreen_ShouldNameTheEvent_WhenTheRideWasOne', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    server.rides.add(rideJson('ride-1', 'ready', fileName: 'lake.gpx'));
    server.events.add({
      'id': 'event-1',
      'name': 'Gran Fondo',
      'date': '2026-05-10',
      'kind': 'sportive',
      'distanceM': 120000.0,
      'elevationGainM': null,
      'notes': null,
      'rideId': 'ride-1',
      'createdAt': '2026-11-10T09:00:00Z',
    });
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/rides/ride-1');

    expect(find.textContaining('Gran Fondo'), findsWidgets);
    expect(find.byKey(const Key('ride-event')), findsOneWidget);
  });
}
