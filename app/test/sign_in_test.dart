import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;
  setUp(() => server = FakeServer());

  Future<void> signIn(
    WidgetTester tester,
    String email,
    String password,
  ) async {
    await tester.enterText(find.byKey(const Key('email')), email);
    await tester.enterText(find.byKey(const Key('password')), password);
    await tester.tap(find.byKey(const Key('sign-in')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a signed-out visitor sees the sign-in form, without a single sign-on button when it is off',
    (tester) async {
      await startApp(tester, server.session(useCookies: false));

      expect(find.byKey(const Key('sign-in')), findsOneWidget);
      expect(find.byKey(const Key('sso')), findsNothing);
    },
  );

  testWidgets(
    'shows the single sign-on button when the server offers it, and starts it',
    (tester) async {
      server.ssoEnabled = true;
      var started = false;
      await startApp(
        tester,
        server.session(useCookies: false),
        startSso: () async => started = true,
      );

      expect(find.text('Continue with Test IdP'), findsOneWidget);
      await tester.tap(find.byKey(const Key('sso')));
      expect(started, isTrue);
    },
  );

  testWidgets('phone builds do not offer single sign-on yet', (tester) async {
    server.ssoEnabled = true;
    await startApp(tester, server.session(useCookies: false));

    expect(find.byKey(const Key('sso')), findsNothing);
  });

  testWidgets('explains why single sign-on sent the visitor back', (
    tester,
  ) async {
    await startApp(
      tester,
      server.session(useCookies: false, ssoError: 'not_approved'),
    );

    expect(find.textContaining('waiting for an admin'), findsOneWidget);
  });

  testWidgets('a wrong password is explained', (tester) async {
    server.add('rider@example.com');
    await startApp(tester, server.session(useCookies: false));

    await signIn(tester, 'rider@example.com', 'Not-the-password-1');

    expect(find.textContaining('not right'), findsOneWidget);
    expect(find.byKey(const Key('upload')), findsNothing);
  });

  testWidgets('an account that is not approved yet is told to wait', (
    tester,
  ) async {
    server.add('rider@example.com', approved: false);
    await startApp(tester, server.session(useCookies: false));

    await signIn(tester, 'rider@example.com', 'Rider-pass-123');

    expect(find.textContaining('waiting for an admin'), findsOneWidget);
  });

  testWidgets(
    'signing in with a bearer token opens the rides, and the token is sent with later calls',
    (tester) async {
      server.add('rider@example.com', name: 'Alex Rider');
      server.rides.add(
        rideJson(
          'r1',
          'ready',
          distanceM: 42300,
          movingS: 5400,
          avgPowerW: 190,
        ),
      );
      await startApp(tester, server.session(useCookies: false));

      await signIn(tester, 'rider@example.com', 'Rider-pass-123');

      expect(find.byKey(const Key('upload')), findsOneWidget);
      expect(find.text('Alex Rider'), findsOneWidget);
      expect(find.text('42.3 km'), findsOneWidget);
      expect(
        server.requests,
        containsAllInOrder([
          'POST /api/v1/accounts/login',
          'GET /api/v1/accounts/me',
          'GET /api/v1/rides',
        ]),
      );
    },
  );

  testWidgets(
    'a browser that already has a session cookie goes straight to the rides',
    (tester) async {
      server.signInBrowser(server.add('rider@example.com'));
      await startApp(tester, server.session(useCookies: true));

      expect(find.byKey(const Key('upload')), findsOneWidget);
      expect(find.byKey(const Key('sign-in')), findsNothing);
    },
  );

  testWidgets('signing out returns to the sign-in form', (tester) async {
    server.signInBrowser(server.add('rider@example.com'));
    await startApp(tester, server.session(useCookies: true));

    await tester.tap(find.byKey(const Key('sign-out')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign-in')), findsOneWidget);
    expect(server.requests, contains('POST /api/v1/accounts/logout'));
  });
}
