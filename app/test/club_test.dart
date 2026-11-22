import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velomine_api/api.dart';

import 'package:velomine/core/widgets/bottom_action_bar.dart';
import 'package:velomine/features/club/widgets/club_hero_card.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() => server = FakeServer());

  testWidgets('JoinClubScreen_ShouldJoinAndOpenTheClub_WhenCodeIsValid', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));

    // No club: the app goes straight to the rides, so riding alone is the default.
    expect(find.text('Rides'), findsWidgets);

    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();
    expect(find.text('You are not in a club yet'), findsOneWidget);
    await tester.tap(find.byKey(const Key('go-join-club')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('join-code')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('join-code')), 'WRONG123');
    await tester.tap(find.byKey(const Key('join-club')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('join-error')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('join-code')), server.joinCode);
    await tester.tap(find.byKey(const Key('join-club')));
    await tester.pumpAndSettle();

    // Joined: the router moves to the club's screens.
    expect(find.text('Rides'), findsWidgets);
    expect(server.clubRoles[rider.email], 'member');

    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();
    // The club's name names the page; a rider sees no roster, only the owner and coaches do.
    expect(find.text('Test Club'), findsOneWidget);
    expect(find.byKey(const Key('club-members-card')), findsNothing);
    expect(find.byKey(const Key('join-code-value')), findsNothing);

    await tester.tap(find.byKey(const Key('club-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('leave-club')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-leave-club')));
    await tester.pumpAndSettle();

    // Back to the club tab's empty state, with no membership left.
    expect(find.text('You are not in a club yet'), findsOneWidget);
    expect(server.clubRoles.containsKey(rider.email), isFalse);
  });

  testWidgets('JoinClubScreen_ShouldReturnToRides_WhenSkipped', (tester) async {
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));

    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-join-club')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('skip-join')));
    await tester.pumpAndSettle();

    expect(find.text('Rides'), findsWidgets);
    expect(server.clubRoles.containsKey(rider.email), isFalse);
  });

  testWidgets('ClubScreen_ShouldShowCodeAndPromoteMember_WhenOwner', (
    tester,
  ) async {
    final owner = server.add(
      'owner@example.com',
      name: 'Owner Rina',
      clubRole: 'owner',
    );
    final rider = server.add('rider@example.com', name: 'Rider Luca');
    server.signInBrowser(owner);
    await startApp(tester, server.session(useCookies: true));

    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('join-code-value')), findsOneWidget);
    expect(find.text(server.joinCode), findsOneWidget);

    await tester.ensureVisible(find.byKey(Key('member-menu-${rider.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('member-menu-${rider.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make coach'));
    await tester.pumpAndSettle();

    expect(server.clubRoles[rider.email], 'coach');
    expect(find.text('Coach'), findsWidgets);
  });

  testWidgets('ClubScreen_ShouldKeepLeaveLastInTheMenu_WhenTheRiderIsAMember', (
    tester,
  ) async {
    final rider = server.add('rider@example.com');
    server.signInBrowser(rider);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('leave-club')), findsNothing);
    await tester.tap(find.byKey(const Key('club-actions')));
    await tester.pumpAndSettle();
    final leave = tester.widget<MenuItemButton>(
      find.byKey(const Key('leave-club')),
    );
    expect(
      leave.style?.foregroundColor?.resolve({}),
      Theme.of(tester.element(find.byKey(const Key('leave-club'))))
          .colorScheme
          .error,
    );
    expect(find.byType(MenuItemButton).last.evaluate().single.widget, leave);
  });

  testWidgets('ClubScreen_ShouldShowTheOwnerNote_WhenTheRiderOwns', (
    tester,
  ) async {
    final owner = server.add('owner@example.com', clubRole: 'owner');
    server.signInBrowser(owner);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('club-actions')), findsNothing);
    expect(find.byKey(const Key('leave-club')), findsNothing);
    expect(find.textContaining('cannot leave'), findsOneWidget);
  });

  testWidgets('ClubHeroCard_ShouldShowTheRoleAsABadge_WhenBuilt', (tester) async {
    final club = ClubResponse(
      id: 'c1',
      name: 'Hero Club',
      myRole: 'coach',
      joinCode: null,
      latitude: null,
      longitude: null,
      plan: null,
      isActive: true,
      isDiscoverable: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ClubHeroCard(club: club)),
      ),
    );
    // The club's name is the page's title now, so the card carries the club's state alone.
    expect(find.text('Hero Club'), findsNothing);
    expect(find.byKey(const Key('club-role')), findsOneWidget);
    expect(find.text('Coach'), findsOneWidget);
  });

  testWidgets('ClubScreen_ShouldHideTheMembersCard_WhenTheRiderIsAMember', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', name: 'Rider Luca');
    server.signInBrowser(rider);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/club');

    // The roster is the club's business: a rider never reads it.
    expect(find.byKey(const Key('club-members-card')), findsNothing);
    expect(find.byKey(Key('member-${rider.id}')), findsNothing);
  });

  testWidgets('ClubScreen_ShouldShowTheMembersCard_WhenTheRiderIsACoach', (
    tester,
  ) async {
    final coach = server.add(
      'coach@example.com',
      name: 'Coach Marco',
      clubRole: 'coach',
    );
    server.add('rider@example.com', name: 'Rider Luca');
    server.signInBrowser(coach);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/club');

    expect(find.byKey(const Key('club-members-card')), findsOneWidget);
    expect(find.text('Rider Luca'), findsOneWidget);
  });

  testWidgets('JoinClubScreen_ShouldPrefillCode_WhenInvited', (tester) async {
    final rider = server.add('rider@example.com', clubRole: null);
    final session = server.session(useCookies: true);
    session.pendingJoinCode = server.joinCode;
    server.signInBrowser(rider);
    await startApp(tester, session);

    expect(find.text('Join a club'), findsOneWidget);
    final field = tester.widget<TextField>(find.byKey(const Key('join-code')));
    expect(field.controller!.text, server.joinCode);
  });

  testWidgets('ClubsTab_ShouldMoveOwnership_WhenAdminChangesIt', (
    tester,
  ) async {
    final admin = server.add(
      'admin@example.com',
      roles: ['admin', 'member'],
      name: 'Boss',
      clubRole: null,
    );
    final owner = server.add(
      'owner@example.com',
      name: 'Owner Rina',
      clubRole: null,
    );
    final rider = server.add('rider@example.com', name: 'Rider Luca');
    server.signInBrowser(admin);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await startApp(tester, server.session(useCookies: true));
    await openAccount(tester, 'admin');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab-clubs')));
    await tester.pumpAndSettle();

    // Create the club, then hand ownership to the rider who is already in the fake club.
    await tester.tap(find.byKey(const Key('create-club')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('club-name')), 'Velocità');
    await tester.enterText(
      find.byKey(const Key('club-owner-email')),
      owner.email,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-club')));
    await tester.pumpAndSettle();
    expect(server.clubRoles[owner.email], 'owner');

    await tester.tap(find.byKey(const Key('club-menu-club-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('change-owner-club-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-owner')));
    await tester.pumpAndSettle();

    expect(server.clubRoles[rider.email], 'owner');
    expect(server.clubRoles[owner.email], 'member');
  });

  testWidgets('ClubsTab_ShouldShowValidationMessage_WhenOwnerUnknown', (
    tester,
  ) async {
    final admin = server.add(
      'admin@example.com',
      roles: ['admin', 'member'],
      name: 'Boss',
      clubRole: null,
    );
    server.signInBrowser(admin);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await startApp(tester, server.session(useCookies: true));
    await openAccount(tester, 'admin');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab-clubs')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create-club')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('club-name')), 'Velocità');
    await tester.enterText(
      find.byKey(const Key('club-owner-email')),
      'nobody@example.com',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-club')));
    await tester.pumpAndSettle();

    expect(
      find.text('There is no account with that email address.'),
      findsOneWidget,
    );
  });

  testWidgets('ClubsTab_ShouldCreateClub_WhenAdminSubmits', (tester) async {
    final admin = server.add(
      'admin@example.com',
      roles: ['admin', 'member'],
      name: 'Boss',
      clubRole: null,
    );
    final owner = server.add(
      'owner@example.com',
      name: 'Owner Rina',
      clubRole: null,
    );
    server.signInBrowser(admin);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await startApp(tester, server.session(useCookies: true));
    // An admin without a club still reaches the admin pages.
    expect(find.text('Rides'), findsWidgets);

    await openAccount(tester, 'admin');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab-clubs')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create-club')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('club-name')), 'Velocità');
    await tester.enterText(
      find.byKey(const Key('club-owner-email')),
      owner.email,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-club')));
    await tester.pumpAndSettle();

    expect(server.clubRoles[owner.email], 'owner');
    expect(find.text('Velocità'), findsWidgets);
  });

  /// Opens the club page of a rider who belongs to the fake club.
  Future<void> openClub(WidgetTester tester, {String? language}) async {
    server.signInBrowser(server.add('rider@example.com', language: language));
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/club');
    await tester.pumpAndSettle();
  }

  /// Picks an audience in one of the sharing choices, as a rider would.
  Future<void> choose(WidgetTester tester, String key, String audience) async {
    await tester.scrollUntilVisible(
      find.byKey(Key(key)),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(audience).last);
    await tester.pumpAndSettle();
  }

  testWidgets('ClubSharingCard_ShouldAskFirst_WhenRidesAreSharedWithCoaches', (
    tester,
  ) async {
    await openClub(tester);
    await choose(tester, 'share-rides', 'My coaches');

    // Nothing is shared until the rider agrees, and the prompt says what a coach then reads.
    expect(find.text('Share with your coaches?'), findsOneWidget);
    expect(server.sharingChoices['rides'], 'none');

    await tester.tap(find.byKey(const Key('share-rides-confirm')));
    await tester.pumpAndSettle();

    expect(server.sharingChoices['rides'], 'coaches');
  });

  testWidgets(
    'ClubSharingCard_ShouldShareTrainingWithTheRides_WhenRidesAreSharedOrStopped',
    (tester) async {
      await openClub(tester);

      // There is no separate training choice: it follows the rides.
      expect(find.byKey(const Key('share-analytics')), findsNothing);

      await choose(tester, 'share-rides', 'My coaches');
      await tester.tap(find.byKey(const Key('share-rides-confirm')));
      await tester.pumpAndSettle();
      expect(server.sharingChoices['analytics'], 'coaches');

      await choose(tester, 'share-rides', 'Nobody');
      expect(server.sharingChoices['rides'], 'none');
      expect(server.sharingChoices['analytics'], 'none');
    },
  );

  testWidgets(
    'ClubSharingCard_ShouldAskForConsent_WhenWellbeingIsSharedWithCoaches',
    (tester) async {
      await openClub(tester);
      await choose(tester, 'share-wellbeing', 'My coaches');

      // Wellbeing is health data, so the prompt asks for consent in its own words.
      expect(
        find.text('Share your wellbeing with your coaches?'),
        findsOneWidget,
      );
      expect(server.sharingChoices['wellbeing'], 'none');

      await tester.tap(find.byKey(const Key('share-wellbeing-confirm')));
      await tester.pumpAndSettle();

      expect(server.sharingChoices['wellbeing'], 'coaches');
    },
  );

  testWidgets(
    'ClubSharingCard_ShouldAskForConsentInItalian_WhenWellbeingIsSharedWithCoaches',
    (tester) async {
      await openClub(tester, language: 'it');
      await choose(tester, 'share-wellbeing', 'I miei allenatori');

      expect(
        find.text('Condividere il tuo benessere con i tuoi allenatori?'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('share-wellbeing-confirm')));
      await tester.pumpAndSettle();

      expect(server.sharingChoices['wellbeing'], 'coaches');
    },
  );

  testWidgets('ClubSharingCard_ShouldNotShare_WhenTheRiderCancels', (
    tester,
  ) async {
    await openClub(tester);
    await choose(tester, 'share-wellbeing', 'My coaches');

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(server.sharingChoices['wellbeing'], 'none');
  });

  testWidgets('ClubSharingCard_ShouldNotAsk_WhenSharingStops', (tester) async {
    server.sharingChoices['rides'] = 'coaches';
    await openClub(tester);

    await choose(tester, 'share-rides', 'Nobody');

    // Turning sharing off never asks: it takes nothing away.
    expect(find.text('Share with your coaches?'), findsNothing);
    expect(server.sharingChoices['rides'], 'none');
  });

  testWidgets('ClubSharingCard_ShouldNotAsk_WhenRoutesAreShared', (
    tester,
  ) async {
    server.sharingChoices['rides'] = 'coaches';
    await openClub(tester);

    await choose(tester, 'share-routes', 'My coaches');

    // Routes borrow the map to rides the rider already shares, and their own row says what it shows.
    expect(find.text('Share with your coaches?'), findsNothing);
    expect(server.sharingChoices['routes'], 'coaches');
  });

  testWidgets('StartClubScreen_ShouldPinSubmitInTheBottomBar_WhenOpened', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    server.adminSettings['clubCreationEnabled'] = true;
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));

    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-start-club')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(BottomActionBar),
        matching: find.byKey(const Key('start-club')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('ClubPages_ShouldNotShowAnotherClubsData_WhenTheClubDiffers', (
    tester,
  ) async {
    // A rider of no club opens Club: the server answers with no club, and the page shows no member of
    // any club at all — it never asks for one it does not belong to.
    final outsider = server.add(
      'outsider@example.com',
      name: 'Outsider Bea',
      clubRole: null,
    );
    server.signInBrowser(outsider);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/club');

    expect(find.byKey(const Key('go-nearby-clubs')), findsOneWidget);
    expect(find.text(server.clubName), findsNothing);
    expect(server.requests.where((r) => r.contains('/club/members/')), isEmpty);
  });

  for (final width in [390.0, 600.0, 820.0, 1300.0]) {
    testWidgets('ClubScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}', (
      tester,
    ) async {
      final owner = server.add(
        'owner@example.com',
        name: 'Owner Rina',
        clubRole: 'owner',
      );
      server.signInBrowser(owner);
      tester.view.physicalSize = Size(width, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));
      await goTo(tester, '/club');

      expect(find.byKey(const Key('join-code-value')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('NoClubPage_ShouldShowEachWayAsItsOwnCard_WhenTheRiderHasNoClub', (
    tester,
  ) async {
    server.adminSettings['clubCreationEnabled'] = true;
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/club');

    // Three ways forward, each its own card with its own button.
    expect(find.byKey(const Key('club-way-nearby')), findsOneWidget);
    expect(find.byKey(const Key('club-way-join')), findsOneWidget);
    expect(find.byKey(const Key('club-way-start')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('club-way-nearby')),
        matching: find.byKey(const Key('go-nearby-clubs')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('NoClubPage_ShouldShowOnlyTheWaitingRequest_WhenAskedToJoin', (
    tester,
  ) async {
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
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/club');

    expect(find.text('Waiting for ${server.clubName}'), findsOneWidget);
    expect(find.byKey(const Key('club-way-nearby')), findsNothing);
    expect(find.byKey(const Key('club-way-join')), findsNothing);
  });

  testWidgets(
    'CalendarFeedScreen_ShouldPutReplaceAheadOfStopInTheMenu_WhenAnAddressExists',
    (tester) async {
      final rider = server.add('rider@example.com');
      server.signInBrowser(rider);
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));
      await goTo(tester, '/club/calendar');

      // With no address there is only the action that makes one.
      expect(find.byKey(const Key('calendar-actions')), findsNothing);
      await tester.tap(find.byKey(const Key('create-calendar-address')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('calendar-address')), findsOneWidget);

      await tester.tap(find.byKey(const Key('calendar-actions')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('replace-calendar-address')), findsOneWidget);
      // Replace is a rare action in the menu, ahead of the destructive Stop.
      final entries = tester
          .widgetList<MenuItemButton>(find.byType(MenuItemButton))
          .toList();
      expect(entries.first.key, const Key('replace-calendar-address'));
      expect(entries.last.key, const Key('stop-calendar-address'));

      await tester.tap(find.byKey(const Key('replace-calendar-address')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('confirm-replace-calendar')), findsOneWidget);
    },
  );

  for (final width in [390.0, 1300.0]) {
    testWidgets('NoClubPage_ShouldNotOverflow_WhenWidthIs${width.toInt()}', (
      tester,
    ) async {
      server.adminSettings['clubCreationEnabled'] = true;
      final rider = server.add('rider@example.com', clubRole: null);
      server.signInBrowser(rider);
      tester.view.physicalSize = Size(width, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));
      await goTo(tester, '/club');

      expect(find.byKey(const Key('club-way-nearby')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('JoinClubPage_ShouldNotOverflow_WhenWidthIs${width.toInt()}', (
      tester,
    ) async {
      final rider = server.add('rider@example.com', clubRole: null);
      server.signInBrowser(rider);
      tester.view.physicalSize = Size(width, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));
      await goTo(tester, '/join');

      expect(find.byKey(const Key('join-club-form')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'StartClubPage_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
        server.adminSettings['clubCreationEnabled'] = true;
        final rider = server.add('rider@example.com', clubRole: null);
        server.signInBrowser(rider);
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await startApp(tester, server.session(useCookies: true));
        await goTo(tester, '/club/start');

        expect(find.byKey(const Key('start-club-name-card')), findsOneWidget);
        expect(find.byKey(const Key('start-club-location-card')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'CalendarFeedPage_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
        final rider = server.add('rider@example.com');
        server.signInBrowser(rider);
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await startApp(tester, server.session(useCookies: true));
        await goTo(tester, '/club/calendar');

        expect(find.byKey(const Key('calendar-address-card')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
