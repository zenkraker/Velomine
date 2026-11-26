import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() => server = FakeServer());

  void widen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('NearbyClubsScreen_ShouldListTheClub_WhenItIsInReach', (
    tester,
  ) async {
    widen(tester);
    server.clubLatitude = 45.4642;
    server.clubLongitude = 9.19;
    server.clubDiscoverable = true;
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await startApp(
      tester,
      server.session(useCookies: true),
      locationService: FakeLocationService((
        latitude: 45.4642,
        longitude: 9.19,
      )),
    );

    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-nearby-clubs')));
    await tester.pumpAndSettle();

    expect(find.text('Test Club'), findsOneWidget);
    expect(find.byKey(const Key('nearby-club-club-1')), findsOneWidget);
    expect(find.textContaining('~0 km'), findsOneWidget);
  });

  testWidgets('NearbyClubsScreen_ShouldAskToJoin_WhenTheRiderSendsANote', (
    tester,
  ) async {
    widen(tester);
    server.clubLatitude = 45.4642;
    server.clubLongitude = 9.19;
    server.clubDiscoverable = true;
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await startApp(
      tester,
      server.session(useCookies: true),
      locationService: FakeLocationService((
        latitude: 45.4642,
        longitude: 9.19,
      )),
    );

    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-nearby-clubs')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ask-club-1')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('join-request-note')),
      'I ride on Sundays.',
    );
    await tester.tap(find.byKey(const Key('send-join-request')));
    await tester.pumpAndSettle();

    expect(server.joinRequests, hasLength(1));
    expect(server.joinRequests.single['note'], 'I ride on Sundays.');
    expect(find.byKey(const Key('requested-club-1')), findsOneWidget);
    expect(find.byKey(const Key('pending-join-request')), findsOneWidget);
  });

  testWidgets(
    'NearbyClubsScreen_ShouldUseTheSavedPoint_WhenTheDeviceSharesNothing',
    (tester) async {
      widen(tester);
      server.clubLatitude = 45.4642;
      server.clubLongitude = 9.19;
      server.clubDiscoverable = true;
      final rider = server.add('rider@example.com', clubRole: null);
      server.signInBrowser(rider);
      final homeStore = MemoryHomeLocationStore()
        ..value = (latitude: 45.4642, longitude: 9.19);
      await startApp(
        tester,
        server.session(useCookies: true),
        homeLocationStore: homeStore,
      );

      await tester.tap(find.text('Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('go-nearby-clubs')));
      await tester.pumpAndSettle();

      expect(find.text('Using your saved location.'), findsOneWidget);
      expect(find.byKey(const Key('nearby-club-club-1')), findsOneWidget);
    },
  );

  testWidgets('ClubScreen_ShouldShowThePendingAsk_WhenTheRiderAsked', (
    tester,
  ) async {
    widen(tester);
    final rider = server.add('rider@example.com', clubRole: null);
    server.joinRequests.add({
      'id': 'join-1',
      'clubId': 'club-1',
      'userId': rider.id,
      'displayName': rider.name,
      'note': 'May I join?',
      'createdAt': '2026-11-09T10:00:00Z',
    });
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));

    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();

    expect(find.text('Waiting for Test Club'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cancel-join-request')));
    await tester.pumpAndSettle();

    expect(server.joinRequests, isEmpty);
    expect(find.text('Waiting for Test Club'), findsNothing);
  });

  testWidgets('RidesScreen_ShouldShowTheSoloCard_WhenThereIsNoClub', (
    tester,
  ) async {
    widen(tester);
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));

    expect(find.byKey(const Key('solo-club-card')), findsOneWidget);
    expect(find.text('Ride at your own pace'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-nearby-from-rides')));
    await tester.pumpAndSettle();
    expect(find.text('Clubs near you'), findsWidgets);
  });

  testWidgets(
    'RidesScreen_ShouldRememberTheDismissal_WhenTheSoloCardIsClosed',
    (tester) async {
      widen(tester);
      final rider = server.add('rider@example.com', clubRole: null);
      server.signInBrowser(rider);
      final store = MemorySoloHintStore();
      await startApp(
        tester,
        server.session(useCookies: true),
        soloHintStore: store,
      );

      await tester.tap(find.byKey(const Key('dismiss-solo-card')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('solo-club-card')), findsNothing);
      expect(store.value, isTrue);
    },
  );

  testWidgets(
    'ClubScreen_ShouldSaveThePointAndDiscovery_WhenTheOwnerSetsThem',
    (tester) async {
      widen(tester);
      final owner = server.add('owner@example.com', clubRole: 'owner');
      server.signInBrowser(owner);
      await startApp(
        tester,
        server.session(useCookies: true),
        locationService: FakeLocationService((
          latitude: 45.4642,
          longitude: 9.19,
        )),
      );

      await tester.tap(find.text('Club'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('set-club-location')));
      await tester.tap(find.byKey(const Key('set-club-location')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('location-use')));
      await tester.pumpAndSettle();

      expect(server.clubLatitude, closeTo(45.4642, 0.00001));
      expect(server.clubLongitude, closeTo(9.19, 0.00001));

      // The map above it grew the card, so the switch needs the scroll to settle first.
      await tester.ensureVisible(find.byKey(const Key('club-discoverable')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('club-discoverable')));
      await tester.pumpAndSettle();

      expect(server.clubDiscoverable, isTrue);
    },
  );

  testWidgets('ClubScreen_ShouldApproveTheRequest_WhenTheOwnerConfirms', (
    tester,
  ) async {
    widen(tester);
    final owner = server.add('owner@example.com', clubRole: 'owner');
    final rider = server.add('rider@example.com', name: 'Rider Luca');
    server.joinRequests.add({
      'id': 'join-1',
      'clubId': 'club-1',
      'userId': rider.id,
      'displayName': rider.name,
      'note': 'May I join?',
      'createdAt': '2026-11-09T10:00:00Z',
    });
    server.signInBrowser(owner);
    await startApp(tester, server.session(useCookies: true));

    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('join-requests-card')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('approve-join-1')));
    await tester.tap(find.byKey(const Key('approve-join-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-approve-join-1')));
    await tester.pumpAndSettle();

    expect(server.clubRoles[rider.email], 'member');
    expect(server.joinRequests, isEmpty);
    expect(find.byKey(const Key('join-requests-empty')), findsOneWidget);
  });

  testWidgets(
    'NearbyClubsScreen_ShouldShowABackArrowAndNoAppBar_WhenOpenedOnAPhone',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final rider = server.add('rider@example.com', clubRole: null);
      server.signInBrowser(rider);
      await startApp(
        tester,
        server.session(useCookies: true),
        locationService: FakeLocationService((
          latitude: 45.4642,
          longitude: 9.19,
        )),
      );

      await tester.tap(find.text('Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('go-nearby-clubs')));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Clubs near you'), findsWidgets);
      expect(find.byType(BackButton), findsOneWidget);
    },
  );

  testWidgets('NearbyClubsScreen_ShouldOpenTheNoteInASheet_WhenAskingToJoin', (
    tester,
  ) async {
    widen(tester);
    server.clubLatitude = 45.4642;
    server.clubLongitude = 9.19;
    server.clubDiscoverable = true;
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await startApp(
      tester,
      server.session(useCookies: true),
      locationService: FakeLocationService((
        latitude: 45.4642,
        longitude: 9.19,
      )),
    );

    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-nearby-clubs')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ask-club-1')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byKey(const Key('join-request-note')), findsOneWidget);
  });

  testWidgets(
    'NearbyClubsScreen_ShouldPutTheClubsInOneCard_WhenTheyAreInReach',
    (tester) async {
      widen(tester);
      final rider = server.add('rider@example.com', clubRole: null);
      server.clubLatitude = 45.4642;
      server.clubLongitude = 9.19;
      server.clubDiscoverable = true;
      server.signInBrowser(rider);
      await startApp(
        tester,
        server.session(useCookies: true),
        locationService: FakeLocationService((
          latitude: 45.4642,
          longitude: 9.19,
        )),
      );
      await goTo(tester, '/clubs');

      // The clubs are the rows of one card, not a card each.
      expect(find.byKey(const Key('nearby-clubs-card')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('nearby-clubs-card')),
          matching: find.byKey(const Key('nearby-club-club-1')),
        ),
        findsOneWidget,
      );
    },
  );

  for (final width in [390.0, 1300.0]) {
    testWidgets(
      'NearbyClubsScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
        final rider = server.add('rider@example.com', clubRole: null);
        server.clubLatitude = 45.4642;
        server.clubLongitude = 9.19;
        server.clubDiscoverable = true;
        server.signInBrowser(rider);
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await startApp(
          tester,
          server.session(useCookies: true),
          locationService: FakeLocationService((
            latitude: 45.4642,
            longitude: 9.19,
          )),
        );
        await goTo(tester, '/clubs');

        expect(find.byKey(const Key('nearby-club-club-1')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
