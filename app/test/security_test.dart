import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/providers.dart';
import 'package:velomine/features/profile/sessions_screen.dart';
import 'package:velomine/features/profile/two_factor_screen.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';

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

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    required FakeServer server,
  }) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = server.session(useCookies: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith((ref) => session)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'SignInScreen_ShouldAskForTheCode_WhenTheAccountHasASecondFactor',
    (tester) async {
      final account = server.add('rider@example.com');
      account.twoFactorEnabled = true;
      await startApp(tester, server.session(useCookies: false));

      await signIn(tester, 'rider@example.com', 'Rider-pass-123');

      expect(find.byKey(const Key('two-factor-code')), findsOneWidget);
      expect(find.byKey(const Key('sign-in')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('two-factor-code')),
        '000000',
      );
      await tester.tap(find.byKey(const Key('two-factor-verify')));
      await tester.pumpAndSettle();
      expect(find.textContaining('did not work'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('two-factor-code')),
        server.twoFactorCode,
      );
      await tester.tap(find.byKey(const Key('two-factor-verify')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('upload')), findsOneWidget);
    },
  );

  testWidgets('SignInScreen_ShouldGoBackToThePassword_WhenTheMemberAsks', (
    tester,
  ) async {
    final account = server.add('rider@example.com');
    account.twoFactorEnabled = true;
    await startApp(tester, server.session(useCookies: false));
    await signIn(tester, 'rider@example.com', 'Rider-pass-123');

    await tester.tap(find.byKey(const Key('two-factor-back')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('email')), findsOneWidget);
  });

  testWidgets(
    'SessionsScreen_ShouldListDevicesAndSignOneOut_WhenTheMemberAsks',
    (tester) async {
      server.signInBrowser(server.add('rider@example.com'));
      server.sessions.add({
        'id': 's-other',
        'label': 'Web app',
        'createdAt': '2026-11-01T10:00:00Z',
        'lastUsedAt': '2026-11-09T10:00:00Z',
        'current': false,
      });
      await pumpScreen(tester, const SessionsScreen(), server: server);

      expect(find.text('Android app'), findsOneWidget);
      expect(find.text('Web app'), findsOneWidget);
      expect(find.text('This device'), findsOneWidget);

      await tester.tap(find.byKey(const Key('revoke-s-other')));
      await tester.pumpAndSettle();

      expect(find.text('Web app'), findsNothing);
      expect(find.text('That device is signed out.'), findsOneWidget);
    },
  );

  testWidgets('SessionsScreen_ShouldKeepOnlyTheCurrent_WhenLoggingOutOthers', (
    tester,
  ) async {
    server.signInBrowser(server.add('rider@example.com'));
    server.sessions.add({
      'id': 's-other',
      'label': 'Web app',
      'createdAt': '2026-11-01T10:00:00Z',
      'lastUsedAt': '2026-11-09T10:00:00Z',
      'current': false,
    });
    await pumpScreen(tester, const SessionsScreen(), server: server);

    await tester.tap(find.byKey(const Key('logout-others')));
    await tester.pumpAndSettle();

    expect(find.text('Web app'), findsNothing);
    expect(find.text('Android app'), findsOneWidget);
  });

  testWidgets('TwoFactorScreen_ShouldShowTheKey_WhenTheMemberStartsSetup', (
    tester,
  ) async {
    server.signInBrowser(server.add('rider@example.com'));
    await pumpScreen(tester, const TwoFactorScreen(), server: server);

    expect(find.text('Two-factor sign-in is off.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('two-factor-start')));
    await tester.pumpAndSettle();

    expect(find.text('JBSWY3DPEHPK3PXP'), findsOneWidget);
    expect(find.byKey(const Key('two-factor-enable')), findsOneWidget);
  });
}
