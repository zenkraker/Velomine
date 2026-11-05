import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:velomine/core/pkce.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer()..ssoEnabled = true;
    server.add('rider@sso.test', name: 'SSO Rider');
  });

  /// The phone ends up on this link when the browser hands the sign-in back.
  void openLink(WidgetTester tester, String link) =>
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go(link);

  test('a PKCE pair follows RFC 7636 (its appendix B example)', () {
    final pkce = Pkce.fromVerifier(
      'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk',
    );
    expect(pkce.challenge, 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM');
  });

  test('a fresh pair is 43 URL-safe characters and never repeats', () {
    final a = Pkce.generate();
    final b = Pkce.generate();
    expect(a.verifier, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    expect(a.challenge, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    expect(a.verifier, isNot(b.verifier));
  });

  testWidgets('a phone offers single sign-on, and the web app does too', (
    tester,
  ) async {
    await startApp(tester, server.session(useCookies: false));
    expect(find.byKey(const Key('sso')), findsOneWidget);
  });

  testWidgets('the browser address carries the challenge, never the secret', (
    tester,
  ) async {
    final session = server.session(useCookies: false);
    final url = session.appSsoUrl('https://velo.example');

    expect(url.path, '/api/v1/accounts/sso/login');
    expect(url.host, 'velo.example');
    expect(url.queryParameters.keys, ['codeChallenge']);
    expect(
      url.queryParameters['codeChallenge'],
      matches(RegExp(r'^[A-Za-z0-9_-]{43}$')),
    );
  });

  testWidgets('the link the browser hands back signs the member in', (
    tester,
  ) async {
    final session = server.session(useCookies: false);
    server.ssoChallenge = session
        .appSsoUrl('http://server')
        .queryParameters['codeChallenge'];
    server.ssoCodes['good-code'] = server.accounts['rider@sso.test']!;
    await startApp(tester, session);

    openLink(tester, '/sso-callback?code=good-code');
    await tester.pumpAndSettle();

    expect(session.me?.email, 'rider@sso.test');
    expect(find.text('SSO Rider'), findsWidgets); // the signed-in title bar
    expect(find.byKey(const Key('sign-out')), findsOneWidget);
    expect(server.requests, contains('POST /api/v1/accounts/sso/token'));
  });

  testWidgets('a wrong or used code returns to sign-in with the reason', (
    tester,
  ) async {
    final session = server.session(useCookies: false);
    server.ssoChallenge = session
        .appSsoUrl('http://server')
        .queryParameters['codeChallenge'];
    await startApp(tester, session);

    openLink(tester, '/sso-callback?code=stolen-or-old');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sso')), findsOneWidget); // back on sign-in
    expect(
      find.text('Single sign-on did not work. Try again.'),
      findsOneWidget,
    );
    expect(session.me, isNull);
  });

  testWidgets('a link with no sign-in started on this phone does not sign in', (
    tester,
  ) async {
    final session = server.session(useCookies: false);
    server.ssoCodes['good-code'] = server.accounts['rider@sso.test']!;
    await startApp(
      tester,
      session,
    ); // appSsoUrl was never called: no secret to prove the code with

    openLink(tester, '/sso-callback?code=good-code');
    await tester.pumpAndSettle();

    expect(session.me, isNull);
    expect(find.byKey(const Key('sso')), findsOneWidget);
    expect(server.requests, isNot(contains('POST /api/v1/accounts/sso/token')));
  });

  testWidgets(
    'the reason from the server is shown, such as waiting for approval',
    (tester) async {
      await startApp(tester, server.session(useCookies: false));

      openLink(tester, '/sso-callback?sso_error=not_approved');
      await tester.pumpAndSettle();

      expect(
        find.text('Your account is waiting for an admin to approve it.'),
        findsOneWidget,
      );
    },
  );
}
