import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velomine_api/api.dart';

import 'package:velomine/core/widgets/avatar.dart';
import 'package:velomine/core/widgets/bottom_action_bar.dart';
import 'package:velomine/core/widgets/page_scaffold.dart';
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
    // The club's name names the page and heads its hero card; a rider sees no roster, only the owner and
    // coaches do.
    expect(find.text('Test Club'), findsNWidgets(2));
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

    // A new join code is the owner's rare action: in the menu, never a button, and never Leave club.
    expect(find.byKey(const Key('leave-club')), findsNothing);
    await tester.tap(find.byKey(const Key('club-actions')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('new-join-code')), findsOneWidget);
    expect(find.textContaining('cannot leave'), findsOneWidget);
  });

  testWidgets('ClubHeroCard_ShouldShowTheRoleAsABadge_WhenBuilt', (
    tester,
  ) async {
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
    // The club's name heads the card, and the club's state sits under it.
    expect(find.text('Hero Club'), findsOneWidget);
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

  testWidgets(
    'ClubMembersCard_ShouldShowInitialsAndRoleBadges_WhenACoachOpensIt',
    (tester) async {
      final coach = server.add(
        'coach@example.com',
        name: 'Coach Marco',
        clubRole: 'coach',
      );
      for (final name in [
        'Rider Luca',
        'Giulia Ferri',
        'Anna Greco',
        'Luca Conti',
        'Sara Bianchi',
      ]) {
        server.add(
          '${name.split(' ').last.toLowerCase()}@example.com',
          name: name,
        );
      }
      server.signInBrowser(coach);
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));
      await goTo(tester, '/club');

      // Each row leads with the member's initial in a circle, and the role is a badge beside the name.
      expect(find.byType(Avatar), findsNWidgets(4));
      final row = find.byKey(Key('member-${coach.id}'));
      expect(
        find.descendant(of: row, matching: find.byType(Avatar)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('Coach')),
        findsOneWidget,
      );

      // Six in the club, four drawn: the rest open from the card's own button.
      await tester.ensureVisible(find.byKey(const Key('show-all-members')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('show-all-members')));
      await tester.pumpAndSettle();

      expect(find.byType(Avatar), findsNWidgets(6));
      expect(find.byKey(const Key('show-all-members')), findsNothing);
    },
  );

  testWidgets(
    'ClubScreen_ShouldLeadAnUpcomingRideWithItsDay_WhenTheClubHasRides',
    (tester) async {
      final rider = server.add('rider@example.com');
      server.clubRides.add({
        'id': 'plan-1',
        'title': 'Saturday hills',
        'startsAt': DateTime.now()
            .add(const Duration(days: 3))
            .toUtc()
            .toIso8601String(),
        'utcOffsetMinutes': 60,
        'meetingName': 'Piazza Duomo',
        'latitude': 46.0,
        'longitude': 11.0,
        'routeId': null,
        'pace': 'steady',
        'noDrop': true,
        'notes': null,
        'maxRiders': 12,
        'createdByName': 'Test Rider',
        'cancelledAt': null,
      });
      server.signInBrowser(rider);
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));
      await goTo(tester, '/club');

      final row = find.byKey(const Key('club-ride-plan-1'));
      expect(row, findsOneWidget);
      // A date block leads the row, not an icon and a date string.
      final date = DateFormat('d')
          .format(DateTime.now().add(const Duration(days: 3)));
      expect(
        find.descendant(of: row, matching: find.text(date)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.byIcon(Icons.event)),
        findsNothing,
      );
      // The pace, the meeting point and the room left are on the row.
      expect(
        find.descendant(of: row, matching: find.textContaining('Steady')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.textContaining('Piazza Duomo')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('12 of 12 places left')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ClubLocationCard_ShouldDrawTheMapAboveTheSwitchAndButton_WhenSet',
    (tester) async {
      final owner = server.add('owner@example.com', clubRole: 'owner');
      server.clubLatitude = 45.4642;
      server.clubLongitude = 9.19;
      server.signInBrowser(owner);
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));
      await goTo(tester, '/club');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('club-location-map')), findsOneWidget);
      // The switch comes before the button, under the map.
      final switchY = tester
          .getTopLeft(find.byKey(const Key('club-discoverable')))
          .dy;
      final buttonY = tester
          .getTopLeft(find.byKey(const Key('set-club-location')))
          .dy;
      expect(switchY, lessThan(buttonY));
      expect(
        tester.getTopLeft(find.byKey(const Key('club-location-map'))).dy,
        lessThan(switchY),
      );
    },
  );

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

  /// Turns one sharing switch on or off, as a rider would.
  Future<void> toggle(WidgetTester tester, String key) async {
    await tester.scrollUntilVisible(
      find.byKey(Key(key)),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('ClubSharingCard_ShouldAskFirst_WhenRidesAreSharedWithCoaches', (
    tester,
  ) async {
    await openClub(tester);
    await toggle(tester, 'share-rides');

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

      await toggle(tester, 'share-rides');
      await tester.tap(find.byKey(const Key('share-rides-confirm')));
      await tester.pumpAndSettle();
      expect(server.sharingChoices['analytics'], 'coaches');

      await toggle(tester, 'share-rides');
      expect(server.sharingChoices['rides'], 'none');
      expect(server.sharingChoices['analytics'], 'none');
    },
  );

  testWidgets(
    'ClubSharingCard_ShouldAskForConsent_WhenWellbeingIsSharedWithCoaches',
    (tester) async {
      await openClub(tester);
      await toggle(tester, 'share-wellbeing');

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
      await toggle(tester, 'share-wellbeing');

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
    await toggle(tester, 'share-wellbeing');

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(server.sharingChoices['wellbeing'], 'none');
  });

  testWidgets('ClubSharingCard_ShouldNotAsk_WhenSharingStops', (tester) async {
    server.sharingChoices['rides'] = 'coaches';
    await openClub(tester);

    await toggle(tester, 'share-rides');

    // Turning sharing off never asks: it takes nothing away.
    expect(find.text('Share with your coaches?'), findsNothing);
    expect(server.sharingChoices['rides'], 'none');
  });

  testWidgets('ClubSharingCard_ShouldNotAsk_WhenRoutesAreShared', (
    tester,
  ) async {
    server.sharingChoices['rides'] = 'coaches';
    await openClub(tester);

    await toggle(tester, 'share-routes');

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

  testWidgets(
    'NoClubPage_ShouldShowEachWayAsItsOwnCard_WhenTheRiderHasNoClub',
    (tester) async {
      server.adminSettings['clubCreationEnabled'] = true;
      final rider = server.add('rider@example.com', clubRole: null);
      server.signInBrowser(rider);
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));
      await goTo(tester, '/club');

      // Three ways forward, each its own card with a button of the same style: they are peers.
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
      for (final key in ['go-nearby-clubs', 'go-join-club', 'go-start-club']) {
        expect(tester.widget(find.byKey(Key(key))), isA<OutlinedButton>());
      }
      expect(find.text('Your club'), findsNothing);
      expect(
        tester.widget<PageScaffold>(find.byType(PageScaffold).first).title,
        'Club',
      );
    },
  );

  testWidgets('ClubScreen_ShouldNameAPlanLook_WhenACoachOpenedThePlan', (
    tester,
  ) async {
    final rider = server.add('rider@example.com');
    server.shareViews.add({
      'viewerName': 'Marco',
      'what': 'plan',
      'at': '2026-11-24T14:10:00Z',
    });
    server.signInBrowser(rider);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/club');

    // The rider's "who looked" log says what was read, in their own words: a plan look reads "Plan".
    final look = find.widgetWithText(ListTile, 'Marco');
    expect(look, findsOneWidget);
    expect(
      find.descendant(of: look, matching: find.text('Plan')),
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

    testWidgets('StartClubPage_ShouldNotOverflow_WhenWidthIs${width.toInt()}', (
      tester,
    ) async {
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
    });

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
