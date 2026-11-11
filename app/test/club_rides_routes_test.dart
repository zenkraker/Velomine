import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

Map<String, Object?> routeSeed({
  required String id,
  required String name,
  required String ownerId,
  required String ownerName,
  bool shared = true,
  String surface = 'road',
}) => {
  'id': id,
  'name': name,
  'description': 'Rolling, one climb',
  'surface': surface,
  'distanceM': 48200.0,
  'climbingM': 620.0,
  'ownerId': ownerId,
  'ownerName': ownerName,
  'createdAt': '2026-11-01T09:00:00Z',
  'shared': shared,
  'latitude': [46.0, 46.01, 46.02],
  'longitude': [11.0, 11.01, 11.02],
  'elevation': [300.0, 350.0, 400.0],
};

Map<String, Object?> rideSeed({
  required String id,
  required String title,
  DateTime? startsAt,
  int? maxRiders,
  String? routeId,
  String createdByName = 'Test Rider',
}) => {
  'id': id,
  'title': title,
  'startsAt': (startsAt ?? DateTime.now().add(const Duration(days: 3)))
      .toUtc()
      .toIso8601String(),
  'utcOffsetMinutes': 60,
  'meetingName': 'Fountain, Piazza Garibaldi',
  'latitude': 46.0,
  'longitude': 11.0,
  'routeId': routeId,
  'pace': 'steady',
  'noDrop': true,
  'notes': 'Coffee at the lake',
  'maxRiders': maxRiders,
  'createdByName': createdByName,
  'cancelledAt': null,
};

Future<void> openClub(WidgetTester tester) async {
  await tester.tap(find.text('Club'));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void wide(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  late FakeServer server;

  setUp(() => server = FakeServer());

  testWidgets('ClubScreen_ShouldShowRidesAndRoutes_WhenTheClubHasThem', (
    tester,
  ) async {
    wide(tester);
    final rider = server.add('rider@example.com');
    server.clubRides.add(rideSeed(id: 'plan-1', title: 'Sunday ride'));
    server.routeLibrary.add(
      routeSeed(
        id: 'route-1',
        name: 'Lake loop',
        ownerId: rider.id,
        ownerName: rider.name,
      ),
    );
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));

    await openClub(tester);

    expect(find.text('Rides'), findsWidgets);
    expect(find.text('Routes'), findsWidgets);
    expect(find.byKey(const Key('club-ride-plan-1')), findsOneWidget);
    expect(find.byKey(const Key('club-route-route-1')), findsOneWidget);
    expect(find.byKey(const Key('open-club-rides')), findsOneWidget);
    expect(find.byKey(const Key('open-club-routes')), findsOneWidget);
  });

  testWidgets('RoutesScreen_ShouldExplainTheSectionAndOfferAdding_WhenEmpty', (
    tester,
  ) async {
    wide(tester);
    final rider = server.add('rider@example.com');
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));

    await openClub(tester);
    expect(find.byKey(const Key('club-routes-empty')), findsOneWidget);
    await tapVisible(tester, const Key('open-club-routes'));

    expect(find.byKey(const Key('no-routes')), findsOneWidget);
    expect(find.textContaining('No routes yet'), findsOneWidget);
    expect(find.byKey(const Key('add-route')), findsOneWidget);
  });

  testWidgets(
    'RouteDetailScreen_ShouldWithdrawAnOwnRoute_WhenTheOwnerConfirms',
    (tester) async {
      wide(tester);
      final rider = server.add('rider@example.com');
      server.routeLibrary.add(
        routeSeed(
          id: 'route-1',
          name: 'Lake loop',
          ownerId: rider.id,
          ownerName: rider.name,
        ),
      );
      server.signInBrowser(rider);
      await startApp(tester, server.session(useCookies: true));

      await openClub(tester);
      await tapVisible(tester, const Key('open-club-routes'));
      await tapVisible(tester, const Key('route-route-1'));

      expect(find.text('Lake loop'), findsWidgets);
      expect(find.byKey(const Key('withdraw-route')), findsOneWidget);
      await tapVisible(tester, const Key('withdraw-route'));
      await tester.tap(find.byKey(const Key('confirm-withdraw-route')));
      await tester.pumpAndSettle();

      expect(server.routeLibrary.single['shared'], isFalse);
      expect(find.byKey(const Key('route-not-shared')), findsOneWidget);
    },
  );

  testWidgets('AddRouteScreen_ShouldPreviewARidesLine_WhenARideIsChosen', (
    tester,
  ) async {
    wide(tester);
    final rider = server.add('rider@example.com');
    server.rides.add(rideJson('ride-1', 'ready', distanceM: 48000));
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));

    await openClub(tester);
    await tapVisible(tester, const Key('add-route-from-club'));

    await tapVisible(tester, const Key('route-ride-ride-1'));
    expect(find.text('This is the line the club will see'), findsOneWidget);
    // The ride's own name is the suggestion.
    expect(find.text('morning'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('route-name')), 'Lake loop');
    await tapVisible(tester, const Key('save-route'));

    expect(server.routeLibrary, hasLength(1));
    expect(server.routeLibrary.single['name'], 'Lake loop');
    expect(server.routeLibrary.single['ownerId'], rider.id);
  });

  testWidgets('ClubRidesScreen_ShouldLetAMemberJoin_WhenTheRideHasPlaces', (
    tester,
  ) async {
    wide(tester);
    final rider = server.add('rider@example.com');
    server.clubRides.add(rideSeed(id: 'plan-1', title: 'Sunday ride'));
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));

    await openClub(tester);
    await tapVisible(tester, const Key('open-club-rides'));
    expect(find.byKey(const Key('club-ride-plan-1')), findsOneWidget);

    await tapVisible(tester, const Key('club-ride-plan-1'));
    await tapVisible(tester, const Key('join-ride'));

    expect(find.byKey(const Key('leave-ride')), findsOneWidget);
    expect(server.rideSignUps['plan-1'], [rider.id]);
    expect(find.byKey(Key('participant-${rider.id}')), findsOneWidget);
  });

  testWidgets('ClubRideDetailScreen_ShouldSayWhy_WhenTheRideIsFull', (
    tester,
  ) async {
    wide(tester);
    final rider = server.add('rider@example.com');
    final other = server.add('other@example.com', name: 'Otto Other');
    server.clubRides.add(
      rideSeed(id: 'plan-1', title: 'Sunday ride', maxRiders: 1),
    );
    server.rideSignUps['plan-1'] = [other.id];
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));

    await openClub(tester);
    await tapVisible(tester, const Key('open-club-rides'));
    await tapVisible(tester, const Key('club-ride-plan-1'));

    expect(find.byKey(const Key('ride-full-reason')), findsOneWidget);
    final join = tester.widget<FilledButton>(
      find.byKey(const Key('join-ride')),
    );
    expect(join.onPressed, isNull);
  });

  testWidgets('ClubRideDetailScreen_ShouldSayCancelled_WhenTheRideIsOff', (
    tester,
  ) async {
    wide(tester);
    final rider = server.add('rider@example.com');
    server.clubRides.add(
      rideSeed(id: 'plan-1', title: 'Sunday ride')
        ..['cancelledAt'] = '2026-11-10T09:00:00Z',
    );
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));

    await openClub(tester);
    await tapVisible(tester, const Key('open-club-rides'));
    await tapVisible(tester, const Key('club-ride-plan-1'));

    expect(find.byKey(const Key('ride-cancelled-reason')), findsOneWidget);
    final join = tester.widget<FilledButton>(
      find.byKey(const Key('join-ride')),
    );
    expect(join.onPressed, isNull);
  });

  testWidgets('CalendarFeedScreen_ShouldShowTheAddressOnce_WhenCreated', (
    tester,
  ) async {
    wide(tester);
    final rider = server.add('rider@example.com');
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));

    await openClub(tester);
    await tapVisible(tester, const Key('open-club-rides'));
    await tapVisible(tester, const Key('open-calendar-feed'));
    expect(find.byKey(const Key('calendar-status')), findsOneWidget);

    await tapVisible(tester, const Key('create-calendar-address'));
    expect(find.byKey(const Key('calendar-address')), findsOneWidget);
    expect(find.text('http://server/api/v1/calendar/fake.ics'), findsOneWidget);
    expect(find.byKey(const Key('replace-calendar-address')), findsOneWidget);

    await tapVisible(tester, const Key('stop-calendar-address'));
    await tester.tap(find.byKey(const Key('confirm-stop-calendar')));
    await tester.pumpAndSettle();
    expect(server.calendarAddress, isNull);
    expect(find.byKey(const Key('calendar-status')), findsOneWidget);
  });

  testWidgets('PlanRideScreen_ShouldOpenTheForm_WhenACoachPlansARide', (
    tester,
  ) async {
    wide(tester);
    final coach = server.add('coach@example.com', clubRole: 'coach');
    server.signInBrowser(coach);
    await startApp(tester, server.session(useCookies: true));

    await openClub(tester);
    await tapVisible(tester, const Key('plan-ride-from-club'));

    expect(find.byKey(const Key('ride-title')), findsOneWidget);
    expect(find.byKey(const Key('ride-date')), findsOneWidget);
    expect(find.byKey(const Key('ride-meeting-point')), findsOneWidget);
    expect(find.byKey(const Key('save-ride')), findsOneWidget);
  });
}
