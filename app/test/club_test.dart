import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() => server = FakeServer());

  testWidgets('JoinClubScreen_ShouldJoinAndShowRoster_WhenCodeIsValid', (
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
    expect(find.text('Test Club'), findsOneWidget);
    expect(find.byKey(Key('member-${rider.id}')), findsOneWidget);
    expect(find.byKey(const Key('join-code-value')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('leave-club')));
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

  testWidgets('ClubScreen_ShouldSaveWellbeingSharing_WhenChosen', (
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
    await tester.scrollUntilVisible(
      find.byKey(const Key('share-wellbeing')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('share-wellbeing')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My coaches').last);
    await tester.pumpAndSettle();

    expect(server.sharingChoices['wellbeing'], 'coaches');
  });
}
