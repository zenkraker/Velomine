import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;
  setUp(() => server = FakeServer());

  testWidgets('an admin sees the accounts waiting and approves one', (
    tester,
  ) async {
    server.signInBrowser(
      server.add(
        'admin@example.com',
        roles: ['admin', 'member'],
        name: 'Admin',
      ),
    );
    final waiting = server.add(
      'new@example.com',
      approved: false,
      name: 'Newcomer',
    );
    await startApp(tester, server.session(useCookies: true));

    await tester.tap(find.text('Accounts'));
    await tester.pumpAndSettle();
    expect(find.text('Newcomer'), findsOneWidget);

    await tester.tap(find.byKey(Key('approve-${waiting.id}')));
    await tester.pumpAndSettle();

    expect(waiting.approved, isTrue);
    expect(find.text('Newcomer'), findsNothing);
    expect(find.byKey(const Key('none-pending')), findsOneWidget);
  });

  testWidgets('a member has no accounts screen', (tester) async {
    server.signInBrowser(server.add('rider@example.com'));
    await startApp(tester, server.session(useCookies: true));

    expect(find.text('Accounts'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
