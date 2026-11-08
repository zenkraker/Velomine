import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;
  setUp(() => server = FakeServer());

  Future<void> register(
    WidgetTester tester, {
    String email = 'new@example.com',
    String password = 'Rider-pass-123',
  }) async {
    await tester.tap(find.byKey(const Key('to-register')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('email')), email);
    await tester.enterText(find.byKey(const Key('name')), 'New Rider');
    await tester.enterText(find.byKey(const Key('password')), password);
    await tester.tap(find.byKey(const Key('register')));
    await tester.pumpAndSettle();
  }

  testWidgets('RegisterScreen_ShouldSayApprovalNeeded_WhenAccountIsNew', (
    tester,
  ) async {
    await startApp(tester, server.session(useCookies: false));

    await register(tester);

    expect(find.byKey(const Key('registered')), findsOneWidget);
    expect(find.textContaining('approve it'), findsOneWidget);
    expect(server.accounts['new@example.com']!.approved, isFalse);
  });

  testWidgets('RegisterScreen_ShouldExplainWeakPassword_WhenPasswordIsShort', (
    tester,
  ) async {
    await startApp(tester, server.session(useCookies: false));

    await register(tester, password: 'short');

    expect(find.byKey(const Key('register-error')), findsOneWidget);
    expect(find.textContaining('at least 10 characters'), findsWidgets);
    expect(find.byKey(const Key('registered')), findsNothing);
  });

  testWidgets('RegisterScreen_ShouldExplainEmailTaken_WhenEmailIsUsed', (
    tester,
  ) async {
    server.add('new@example.com');
    await startApp(tester, server.session(useCookies: false));

    await register(tester);

    expect(find.textContaining('already an account'), findsOneWidget);
  });
}
