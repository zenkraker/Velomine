import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/widgets/app_card.dart';
import 'package:velomine/core/widgets/bottom_action_bar.dart';
import 'package:velomine/core/widgets/section_card.dart';
import 'package:velomine/features/calendar/club_ride_widgets.dart';

import 'package:velomine/features/routes/route_widgets.dart';

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

  testWidgets(
    'RouteDetailScreen_ShouldOfferRemovalToTheClubOwner_WhenTheRouteIsSomeoneElses',
    (tester) async {
      wide(tester);
      final rider = server.add('rider@example.com');
      final owner = server.add('owner@example.com', clubRole: 'owner');
      server.routeLibrary.add(
        routeSeed(
          id: 'route-1',
          name: 'Lake loop',
          ownerId: rider.id,
          ownerName: rider.name,
        ),
      );
      server.signInBrowser(owner);
      await startApp(tester, server.session(useCookies: true));

      await openClub(tester);
      await tapVisible(tester, const Key('open-club-routes'));
      await tapVisible(tester, const Key('route-route-1'));

      expect(find.byKey(const Key('edit-route')), findsNothing);
      await tapVisible(tester, const Key('route-actions'));
      expect(find.byKey(const Key('remove-route-as-owner')), findsOneWidget);
      await tapVisible(tester, const Key('remove-route-as-owner'));
      await tester.tap(find.byKey(const Key('confirm-withdraw-route')));
      await tester.pumpAndSettle();

      expect(server.routeLibrary.single['shared'], isFalse);
    },
  );

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
      await tapVisible(tester, const Key('route-actions'));
      expect(find.byKey(const Key('withdraw-route')), findsOneWidget);
      await tapVisible(tester, const Key('withdraw-route'));
      await tester.tap(find.byKey(const Key('confirm-withdraw-route')));
      await tester.pumpAndSettle();

      expect(server.routeLibrary.single['shared'], isFalse);
      expect(find.byKey(const Key('route-not-shared')), findsOneWidget);

      // Share again is the menu entry once the route is out of the library.
      await tapVisible(tester, const Key('route-actions'));
      expect(find.byKey(const Key('share-route')), findsOneWidget);
    },
  );

  testWidgets('RoutesScreen_ShouldDrawTheLineOnTheCard_WhenTheRouteHasOne', (
    tester,
  ) async {
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

    // The card draws the line the list carries, on the dimmed map.
    expect(find.byKey(const Key('route-line-route-1')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('route-route-1')),
        matching: find.byType(RoutePreview),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'RoutesScreen_ShouldSortFromASegmentedControl_WhenLongestIsChosen',
    (tester) async {
      wide(tester);
      final rider = server.add('rider@example.com');
      server.signInBrowser(rider);
      await startApp(tester, server.session(useCookies: true));

      await openClub(tester);
      await tapVisible(tester, const Key('open-club-routes'));
      await tester.tap(find.text('Longest'));
      await tester.pumpAndSettle();

      final control = tester.widget<SegmentedButton<String>>(
        find.byKey(const Key('routes-sort')),
      );
      expect(control.selected, {'longest'});
    },
  );

  testWidgets('RoutesScreen_ShouldNotShowAFloatingButton_WhenOnAPhone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final rider = server.add('rider@example.com');
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));

    await openClub(tester);
    await tapVisible(tester, const Key('open-club-routes'));

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byKey(const Key('add-route')), findsOneWidget);
  });

  testWidgets(
    'RouteDetailScreen_ShouldListDeleteLastAndRedAndAskFirst_WhenTheOwnerOpensTheMenu',
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
      expect(find.byKey(const Key('delete-route')), findsNothing);
      await tapVisible(tester, const Key('route-actions'));

      final delete = find.byKey(const Key('delete-route'));
      expect(
        tester.getTopLeft(delete).dy,
        greaterThan(
          tester.getTopLeft(find.byKey(const Key('withdraw-route'))).dy,
        ),
      );
      final button = tester.widget<MenuItemButton>(delete);
      final error = Theme.of(tester.element(delete)).colorScheme.error;
      expect(button.style?.foregroundColor?.resolve({}), error);

      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('confirm-delete-route')), findsOneWidget);
      expect(server.routeLibrary, hasLength(1));
      await tester.tap(find.byKey(const Key('confirm-delete-route')));
      await tester.pumpAndSettle();
      expect(server.routeLibrary, isEmpty);
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
    expect(
      find.descendant(
        of: find.byType(BottomActionBar),
        matching: find.byKey(const Key('save-route')),
      ),
      findsOneWidget,
    );
    await tapVisible(tester, const Key('save-route'));

    expect(server.routeLibrary, hasLength(1));
    expect(server.routeLibrary.single['name'], 'Lake loop');
    expect(server.routeLibrary.single['ownerId'], rider.id);
  });

  testWidgets('AddRouteScreen_ShouldLeaveOutVirtualRides_WhenRidesAreListed', (
    tester,
  ) async {
    wide(tester);
    final rider = server.add('rider@example.com');
    server.rides.add(rideJson('ride-1', 'ready', distanceM: 48000));
    server.rides.add(
      rideJson('zwift-1', 'ready', distanceM: 30000, environment: 'virtual'),
    );
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));

    await openClub(tester);
    await tapVisible(tester, const Key('add-route-from-club'));

    expect(find.byKey(const Key('route-ride-ride-1')), findsOneWidget);
    expect(find.byKey(const Key('route-ride-zwift-1')), findsNothing);
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
    await tapVisible(tester, const Key('club-rides-actions'));
    await tapVisible(tester, const Key('open-calendar-feed'));
    expect(find.byKey(const Key('calendar-status')), findsOneWidget);

    await tapVisible(tester, const Key('create-calendar-address'));
    expect(find.byKey(const Key('calendar-address')), findsOneWidget);
    expect(find.text('http://server/api/v1/calendar/fake.ics'), findsOneWidget);

    // Replace and Stop are the menu's entries: never a button on the page.
    expect(find.byKey(const Key('replace-calendar-address')), findsNothing);
    await tapVisible(tester, const Key('calendar-actions'));
    expect(find.byKey(const Key('replace-calendar-address')), findsOneWidget);
    expect(find.byKey(const Key('stop-calendar-address')), findsOneWidget);
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
    expect(
      find.descendant(
        of: find.byType(BottomActionBar),
        matching: find.byKey(const Key('save-ride')),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'ClubRidesScreen_ShouldHavePlanRideInTheHeader_WhenACoachOpensIt',
    (tester) async {
      wide(tester);
      final coach = server.add('coach@example.com', clubRole: 'coach');
      server.signInBrowser(coach);
      await startApp(tester, server.session(useCookies: true));

      await openClub(tester);
      await tapVisible(tester, const Key('open-club-rides'));

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byKey(const Key('plan-ride')), findsWidgets);
    },
  );

  testWidgets(
    'ClubRideDetailScreen_ShouldPutEditAheadOfTheRedCancelInTheMenu_WhenACoachOpensIt',
    (tester) async {
      wide(tester);
      final coach = server.add('coach@example.com', clubRole: 'coach');
      server.signInBrowser(coach);
      server.clubRides.add(rideSeed(id: 'plan-1', title: 'Sunday ride'));
      await startApp(tester, server.session(useCookies: true));

      await openClub(tester);
      await tapVisible(tester, const Key('open-club-rides'));
      await tapVisible(tester, const Key('club-ride-plan-1'));

      // The design keeps both the planner's actions in the menu, not in the header.
      expect(find.byKey(const Key('edit-ride')), findsNothing);
      expect(find.byKey(const Key('cancel-ride')), findsNothing);
      await tapVisible(tester, const Key('club-ride-actions'));
      final edit = find.byKey(const Key('edit-ride'));
      final cancel = find.byKey(const Key('cancel-ride'));
      expect(edit, findsOneWidget);
      expect(
        tester.getTopLeft(edit).dy,
        lessThan(tester.getTopLeft(cancel).dy),
      );
      final button = tester.widget<MenuItemButton>(cancel);
      final scheme = Theme.of(tester.element(cancel)).colorScheme;
      expect(button.style?.foregroundColor?.resolve({}), scheme.error);
      expect(tester.widget(find.byType(MenuItemButton).last), same(button));

      await tester.tap(cancel);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-cancel-ride')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ride-cancelled-reason')), findsOneWidget);
    },
  );

  testWidgets(
    'ClubRideDetailScreen_ShouldMakeJoinTheHeaderAction_WhenAMemberOpensIt',
    (tester) async {
      wide(tester);
      final rider = server.add('rider@example.com');
      server.clubRides.add(rideSeed(id: 'plan-1', title: 'Sunday ride'));
      server.signInBrowser(rider);
      await startApp(tester, server.session(useCookies: true));

      await openClub(tester);
      await tapVisible(tester, const Key('open-club-rides'));
      await tapVisible(tester, const Key('club-ride-plan-1'));

      final join = find.byKey(const Key('join-ride'));
      expect(join, findsOneWidget);
      expect(
        find.ancestor(of: join, matching: find.byType(SliverPersistentHeader)),
        findsOneWidget,
      );
      // Nothing else is a header action, and a member has no menu at all.
      expect(find.byKey(const Key('club-ride-actions')), findsNothing);
    },
  );

  testWidgets(
    'ClubRideDetailScreen_ShouldStateTheStartAndPlannerOnce_WhenACoachOpensIt',
    (tester) async {
      wide(tester);
      final coach = server.add('coach@example.com', clubRole: 'coach');
      final startsAt = DateTime.utc(2027, 3, 20, 8, 0);
      server.clubRides.add(
        rideSeed(
          id: 'plan-1',
          title: 'Sunday ride',
          startsAt: startsAt,
          createdByName: 'Marco',
        ),
      );
      server.signInBrowser(coach);
      await startApp(tester, server.session(useCookies: true));

      await openClub(tester);
      await tapVisible(tester, const Key('open-club-rides'));
      await tapVisible(tester, const Key('club-ride-plan-1'));

      final start = rideStartText(
        tester.element(find.byKey(const Key('club-ride-title'))),
        startsAt,
        60,
      );
      expect(find.text('$start · Planned by Marco'), findsOneWidget);
      expect(find.text(start), findsNothing);
    },
  );

  testWidgets(
    'ClubRidesScreen_ShouldLeadEachRowWithItsDate_WhenTheRidesAreListed',
    (tester) async {
      wide(tester);
      final rider = server.add('rider@example.com');
      server.clubRides.add(
        rideSeed(
          id: 'plan-1',
          title: 'Sunday ride',
          startsAt: DateTime.utc(2027, 3, 20, 8, 0),
        ),
      );
      server.signInBrowser(rider);
      await startApp(tester, server.session(useCookies: true));

      await openClub(tester);
      await tapVisible(tester, const Key('open-club-rides'));

      final block = find.byKey(const Key('club-ride-date-plan-1'));
      expect(block, findsOneWidget);
      expect(
        find.descendant(of: block, matching: find.text('20')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: block, matching: find.text('Mar')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ClubRidesScreen_ShouldPutTheRowsOfEachListInOneCard_WhenRidesAreUpcomingAndPast',
    (tester) async {
      wide(tester);
      final rider = server.add('rider@example.com');
      server.clubRides.add(rideSeed(id: 'plan-2', title: 'Sunday ride'));
      server.clubRides.add(
        rideSeed(
          id: 'plan-1',
          title: 'Old ride',
          startsAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      );
      server.signInBrowser(rider);
      await startApp(tester, server.session(useCookies: true));

      await openClub(tester);
      await tapVisible(tester, const Key('open-club-rides'));

      // One card per list, and the rides are rows inside it.
      expect(find.byType(AppCard), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byKey(const Key('club-rides-upcoming')),
          matching: find.byKey(const Key('club-ride-plan-2')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('club-rides-past')),
          matching: find.byKey(const Key('club-ride-plan-1')),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'PlanRideScreen_ShouldOfferPaceAsASegmentedControl_WhenTheFormOpens',
    (tester) async {
      wide(tester);
      final coach = server.add('coach@example.com', clubRole: 'coach');
      server.signInBrowser(coach);
      await startApp(tester, server.session(useCookies: true));

      await goTo(tester, '/club/rides/new');

      final pace = find.byKey(const Key('ride-pace'));
      expect(tester.widget<SegmentedButton<String>>(pace).selected, {'steady'});
      await tester.tap(find.text('Fast'));
      await tester.pumpAndSettle();
      expect(tester.widget<SegmentedButton<String>>(pace).selected, {'fast'});
    },
  );

  testWidgets('PlanRideScreen_ShouldSplitTheFormIntoThreeCards_WhenItOpens', (
    tester,
  ) async {
    wide(tester);
    final coach = server.add('coach@example.com', clubRole: 'coach');
    server.signInBrowser(coach);
    await startApp(tester, server.session(useCookies: true));

    await goTo(tester, '/club/rides/new');

    expect(find.text('Details'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(const Key('ride-title')),
        matching: find.byType(SectionCard),
      ),
      findsNothing,
    );
    expect(
      find.ancestor(
        of: find.byKey(const Key('ride-meeting')),
        matching: find.widgetWithText(SectionCard, 'Meeting point'),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byKey(const Key('ride-pace')),
        matching: find.widgetWithText(SectionCard, 'Details'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'PlanRideScreen_ShouldShowTheChosenPointOnTheMap_WhenAMeetingPointIsPicked',
    (tester) async {
      wide(tester);
      final coach = server.add('coach@example.com', clubRole: 'coach');
      server.signInBrowser(coach);
      await startApp(
        tester,
        server.session(useCookies: true),
        locationService: FakeLocationService((
          latitude: 46.07,
          longitude: 11.12,
        )),
      );

      await goTo(tester, '/club/rides/new');
      expect(find.byKey(const Key('ride-meeting-map')), findsNothing);

      await tapVisible(tester, const Key('ride-meeting-point'));
      await tapVisible(tester, const Key('location-use'));

      expect(find.byKey(const Key('ride-meeting-map')), findsOneWidget);
    },
  );

  testWidgets(
    'RouteDetailScreen_ShouldMakeDownloadTheHeaderAction_WhenTheOwnerOpensIt',
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

      final download = find.byKey(const Key('download-route'));
      expect(download, findsOneWidget);
      expect(
        find.ancestor(
          of: download,
          matching: find.byType(SliverPersistentHeader),
        ),
        findsOneWidget,
      );
      // Edit is a menu entry, not a button on the page.
      expect(find.byKey(const Key('edit-route')), findsNothing);
      await tapVisible(tester, const Key('route-actions'));
      expect(find.byKey(const Key('edit-route')), findsOneWidget);
      expect(find.byKey(const Key('withdraw-route')), findsOneWidget);
    },
  );

  testWidgets(
    'RouteDetailScreen_ShouldShowTheFiguresInTheRouteCard_WhenItOpens',
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

      final card = find.widgetWithText(SectionCard, 'The route');
      expect(card, findsOneWidget);
      for (final figure in [
        'Distance',
        'Climbing',
        'Surface',
        '48.2 km',
        '620 m',
      ]) {
        expect(
          find.descendant(of: card, matching: find.text(figure)),
          findsOneWidget,
        );
      }
      expect(find.widgetWithText(SectionCard, 'Description'), findsOneWidget);
    },
  );

  testWidgets(
    'AddRouteScreen_ShouldOfferTheSourceAsASegmentedControl_WhenTheFormOpens',
    (tester) async {
      wide(tester);
      final rider = server.add('rider@example.com');
      server.signInBrowser(rider);
      await startApp(tester, server.session(useCookies: true));

      await goTo(tester, '/club/routes/new');

      final source = find.byKey(const Key('route-source'));
      expect(tester.widget<SegmentedButton<String>>(source).selected, {'ride'});
      await tester.tap(find.text('From a GPX file'));
      await tester.pumpAndSettle();
      expect(tester.widget<SegmentedButton<String>>(source).selected, {'file'});
      expect(find.byKey(const Key('pick-gpx-file')), findsOneWidget);
    },
  );

  testWidgets(
    'AddRouteScreen_ShouldOfferTheSurfaceAsASegmentedControl_WhenARideIsChosen',
    (tester) async {
      wide(tester);
      final rider = server.add('rider@example.com');
      server.rides.add(rideJson('ride-1', 'ready', distanceM: 48000));
      server.signInBrowser(rider);
      await startApp(tester, server.session(useCookies: true));

      await openClub(tester);
      await tapVisible(tester, const Key('add-route-from-club'));
      await tapVisible(tester, const Key('route-ride-ride-1'));

      final surface = find.byKey(const Key('route-surface'));
      expect(tester.widget<SegmentedButton<String>>(surface).selected, {
        'road',
      });
      await tester.ensureVisible(find.text('Gravel'));
      await tester.tap(find.text('Gravel'));
      await tester.pumpAndSettle();
      expect(tester.widget<SegmentedButton<String>>(surface).selected, {
        'gravel',
      });
    },
  );

  for (final width in [390.0, 1300.0]) {
    testWidgets(
      'ClubRidesScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
        final rider = server.add('rider@example.com');
        server.clubRides.add(rideSeed(id: 'plan-1', title: 'Sunday ride'));
        server.signInBrowser(rider);
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await startApp(tester, server.session(useCookies: true));

        await goTo(tester, '/club/rides');

        expect(find.byKey(const Key('club-ride-plan-1')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ClubRideDetailScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
        final rider = server.add('rider@example.com');
        server.clubRides.add(rideSeed(id: 'plan-1', title: 'Sunday ride'));
        server.signInBrowser(rider);
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await startApp(tester, server.session(useCookies: true));

        await goTo(tester, '/club/rides/plan-1');

        expect(find.byKey(const Key('club-ride-title')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'PlanRideScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
        final coach = server.add('coach@example.com', clubRole: 'coach');
        server.signInBrowser(coach);
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await startApp(tester, server.session(useCookies: true));

        await goTo(tester, '/club/rides/new');

        expect(find.byKey(const Key('save-ride')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'RouteDetailScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
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
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await startApp(tester, server.session(useCookies: true));

        await goTo(tester, '/club/routes/route-1');

        expect(find.byKey(const Key('route-title')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AddRouteScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
        final rider = server.add('rider@example.com');
        server.rides.add(rideJson('ride-1', 'ready', distanceM: 48000));
        server.signInBrowser(rider);
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await startApp(tester, server.session(useCookies: true));

        await goTo(tester, '/club/routes/new');

        expect(find.byKey(const Key('route-source')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
