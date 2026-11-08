import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() => server = FakeServer());

  testWidgets('a clubless rider joins with the code and sees the roster', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));

    // No club, so the app goes straight to the join page.
    expect(find.text('Join a club'), findsOneWidget);
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

    await tester.tap(find.byKey(const Key('leave-club')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-leave-club')));
    await tester.pumpAndSettle();

    // Back to the join page, with no membership left.
    expect(find.text('Join a club'), findsOneWidget);
    expect(server.clubRoles.containsKey(rider.email), isFalse);
  });

  testWidgets('the owner sees the code and can make a member a coach', (
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

    await tester.tap(find.byKey(Key('member-menu-${rider.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make coach'));
    await tester.pumpAndSettle();

    expect(server.clubRoles[rider.email], 'coach');
    expect(find.text('Coach'), findsWidgets);
  });

  testWidgets('an admin creates a club from the admin pages', (tester) async {
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

    await tester.tap(find.text('Admin'));
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
}
