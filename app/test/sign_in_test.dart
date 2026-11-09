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
    'SignInScreen_ShouldShowFormWithoutSsoButton_WhenSingleSignOnIsOff',
    (tester) async {
      await startApp(tester, server.session(useCookies: false));

      expect(find.byKey(const Key('sign-in')), findsOneWidget);
      expect(find.byKey(const Key('sso')), findsNothing);
    },
  );

  testWidgets(
    'SignInScreen_ShouldShowSsoButtonAndStartIt_WhenServerOffersSso',
    (tester) async {
      server.ssoEnabled = true;
      var started = false;
      await startApp(
        tester,
        server.session(useCookies: true),
        startSso: () async => started = true,
      );

      expect(find.text('Continue with Test IdP'), findsOneWidget);
      await tester.tap(find.byKey(const Key('sso')));
      expect(started, isTrue);
    },
  );

  testWidgets('SignInScreen_ShouldExplainSsoError_WhenVisitorIsSentBack', (
    tester,
  ) async {
    await startApp(
      tester,
      server.session(useCookies: false, ssoError: 'not_approved'),
    );

    expect(find.textContaining('waiting for an admin'), findsOneWidget);
  });

  testWidgets('SignInScreen_ShouldShowServerAndAllowChange_WhenOnAPhone', (
    tester,
  ) async {
    var changed = false;
    await startApp(
      tester,
      server.session(useCookies: false),
      onChangeServer: () async => changed = true,
    );

    expect(find.byKey(const Key('server-address')), findsOneWidget);
    expect(find.text('Server: http://server'), findsOneWidget);

    await tester.tap(find.byKey(const Key('change-server')));
    expect(changed, isTrue);
  });

  testWidgets('SignInScreen_ShouldExplainWrongPassword_WhenPasswordIsWrong', (
    tester,
  ) async {
    server.add('rider@example.com');
    await startApp(tester, server.session(useCookies: false));

    await signIn(tester, 'rider@example.com', 'Not-the-password-1');

    expect(find.textContaining('not right'), findsOneWidget);
    expect(find.byKey(const Key('upload')), findsNothing);
  });

  testWidgets(
    'SignInScreen_ShouldIgnoreSpacesAroundCredentials_WhenSigningIn',
    (tester) async {
      server.add('rider@example.com');
      await startApp(tester, server.session(useCookies: false));

      await signIn(tester, '  rider@example.com  ', '  Rider-pass-123  ');

      expect(find.byKey(const Key('upload')), findsOneWidget);
      expect(find.byKey(const Key('sign-in-error')), findsNothing);
    },
  );

  testWidgets('SignInScreen_ShouldTellToWait_WhenAccountIsNotApproved', (
    tester,
  ) async {
    server.add('rider@example.com', approved: false);
    await startApp(tester, server.session(useCookies: false));

    await signIn(tester, 'rider@example.com', 'Rider-pass-123');

    expect(find.textContaining('waiting for an admin'), findsOneWidget);
  });

  testWidgets(
    'SignInScreen_ShouldOpenRidesAndSendToken_WhenSigningInWithToken',
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
    'SignInScreen_ShouldGoStraightToRides_WhenThereIsASessionCookie',
    (tester) async {
      server.signInBrowser(server.add('rider@example.com'));
      await startApp(tester, server.session(useCookies: true));

      expect(find.byKey(const Key('upload')), findsOneWidget);
      expect(find.byKey(const Key('sign-in')), findsNothing);
    },
  );

  testWidgets('SignInScreen_ShouldReturnToSignInForm_WhenSigningOut', (
    tester,
  ) async {
    server.signInBrowser(server.add('rider@example.com'));
    await startApp(tester, server.session(useCookies: true));

    await tester.tap(find.byKey(const Key('sign-out')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign-in')), findsOneWidget);
    expect(server.requests, contains('POST /api/v1/accounts/logout'));
  });
}
