import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:velomine/core/app_sso.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;
  late FakeAccount rider;

  setUp(() {
    server = FakeServer()..ssoEnabled = true;
    rider = server.add('rider@sso.test', name: 'SSO Rider');
  });

  testWidgets('SsoApp_ShouldOfferSingleSignOn_WhenSignInScreenIsShown', (
    tester,
  ) async {
    await startApp(tester, server.session(useCookies: false));
    expect(find.byKey(const Key('sso')), findsOneWidget);
  });

  testWidgets('SsoApp_ShouldHideSingleSignOn_WhenTheAppClientIsNotConfigured', (
    tester,
  ) async {
    server.appSsoEnabled = false;
    await startApp(tester, server.session(useCookies: false));
    expect(find.byKey(const Key('sso')), findsNothing);
  });

  testWidgets('SsoApp_ShouldSignMemberIn_WhenTheProviderReturnsAToken', (
    tester,
  ) async {
    final appSso = FakeAppSso(
      const AppSsoResult.success(
        idToken: 'id-token',
        accessToken: 'access-token',
      ),
    );
    server.ssoTokens['id-token'] = rider;
    final session = server.session(useCookies: false, appSso: appSso);
    await startApp(tester, session, startSso: session.signInWithSso);

    await tester.tap(find.byKey(const Key('sso')));
    await tester.pumpAndSettle();

    expect(appSso.calls, 1);
    expect(appSso.lastConfig?.authority, 'http://idp.test');
    expect(appSso.lastConfig?.clientId, 'velomine-app');
    expect(appSso.lastConfig?.redirectUri, 'com.velomine.app:/sso-callback');
    expect(appSso.lastConfig?.scopes, ['openid', 'profile', 'email']);
    expect(session.me?.email, 'rider@sso.test');
    expect(server.requests, contains('POST /api/v1/accounts/sso/token'));
    expect(find.byKey(const Key('account-menu')), findsOneWidget);
  });

  testWidgets('SsoApp_ShouldShowTheReason_WhenTheExchangeFails', (
    tester,
  ) async {
    final appSso = FakeAppSso(const AppSsoResult.success(idToken: 'bad-token'));
    server.ssoTokenResponses['bad-token'] = http.Response(
      '{"error":"not_approved"}',
      403,
      headers: {'content-type': 'application/json'},
    );
    final session = server.session(useCookies: false, appSso: appSso);
    await startApp(tester, session, startSso: session.signInWithSso);

    await tester.tap(find.byKey(const Key('sso')));
    await tester.pumpAndSettle();

    expect(session.me, isNull);
    expect(find.byKey(const Key('sso')), findsOneWidget);
    expect(
      find.text('Your account is waiting for an admin to approve it.'),
      findsOneWidget,
    );
  });

  testWidgets('SsoApp_ShouldStayOnSignIn_WhenTheProviderIsCancelled', (
    tester,
  ) async {
    final appSso = FakeAppSso(const AppSsoResult.cancelled());
    final session = server.session(useCookies: false, appSso: appSso);
    await startApp(tester, session, startSso: session.signInWithSso);

    await tester.tap(find.byKey(const Key('sso')));
    await tester.pumpAndSettle();

    expect(session.me, isNull);
    expect(session.ssoError, isNull);
    expect(server.requests, isNot(contains('POST /api/v1/accounts/sso/token')));
  });

  testWidgets('SsoApp_ShouldShowTheWebReason_WhenTheBrowserReturnsOne', (
    tester,
  ) async {
    await startApp(
      tester,
      server.session(useCookies: false, ssoError: 'not_approved'),
    );
    expect(
      find.text('Your account is waiting for an admin to approve it.'),
      findsOneWidget,
    );
  });
}
