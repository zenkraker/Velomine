import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/providers.dart';
import 'package:velomine/features/profile/two_factor_screen.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';

import 'fake_server.dart';

import 'package:velomine/core/l10n.dart';

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
    // The button follows the fields, so on a short window it is below the fold.
    await tester.ensureVisible(find.byKey(const Key('sign-in')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sign-in')));
    await tester.pumpAndSettle();
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    required FakeServer server,
    Size size = const Size(1000, 1600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = server.session(useCookies: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith((ref) => session)],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: screen),
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
      await tester.ensureVisible(find.byKey(const Key('two-factor-verify')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('two-factor-verify')));
      await tester.pumpAndSettle();
      expect(find.textContaining('did not work'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('two-factor-code')),
        server.twoFactorCode,
      );
      await tester.ensureVisible(find.byKey(const Key('two-factor-verify')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('two-factor-verify')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('upload')), findsOneWidget);
    },
  );

  testWidgets('SignInScreen_ShouldGoBackToThePassword_WhenTheMemberAsks', (
    tester,
  ) async {
    // A phone, the screen the signed-out pages are drawn for: the two-factor step must fit there
    // without a scroll, so its way back is reachable with one tap.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final account = server.add('rider@example.com');
    account.twoFactorEnabled = true;
    await startApp(tester, server.session(useCookies: false));
    await signIn(tester, 'rider@example.com', 'Rider-pass-123');

    await tester.tap(find.byKey(const Key('two-factor-back')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('email')), findsOneWidget);
  });

  /// Opens the profile page in the app, where the account rows live.
  Future<void> openProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await openAccount(tester, 'profile');
    await tester.pumpAndSettle();
  }

  testWidgets('ProfileScreen_ShouldSayTwoFactorIsOff_WhenTheAccountHasNone', (
    tester,
  ) async {
    server.signInBrowser(server.add('rider@example.com'));
    await openProfile(tester);

    expect(find.text('Two-factor sign-in is off.'), findsOneWidget);
  });

  testWidgets('ProfileScreen_ShouldSayTwoFactorIsOn_WhenItIsEnabled', (
    tester,
  ) async {
    final account = server.add('rider@example.com');
    account.twoFactorEnabled = true;
    server.signInBrowser(account);
    await openProfile(tester);

    expect(find.text('Two-factor sign-in is on.'), findsOneWidget);
  });

  testWidgets('TwoFactorScreen_ShouldShowTheKey_WhenTheMemberStartsSetup', (
    tester,
  ) async {
    server.signInBrowser(server.add('rider@example.com'));
    await pumpScreen(tester, const TwoFactorScreen(), server: server);

    // Off: the page explains itself and the card offers the setup.
    expect(find.text('Set up an authenticator'), findsOneWidget);
    await tester.tap(find.byKey(const Key('two-factor-start')));
    await tester.pumpAndSettle();

    expect(find.text('JBSWY3DPEHPK3PXP'), findsOneWidget);
    expect(find.byKey(const Key('two-factor-enable')), findsOneWidget);
    // The key has the copy the mock-up draws at its end, so it need not be selected by hand.
    final copied = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.tap(find.byKey(const Key('two-factor-key-copy')));
    await tester.pumpAndSettle();
    expect(copied, ['JBSWY3DPEHPK3PXP']);
    expect(find.text('Copied'), findsOneWidget);
  });

  testWidgets(
    'TwoFactorScreen_ShouldShowNoSetup_WhenTheAccountSignsInWithSingleSignOn',
    (tester) async {
      final account = server.add('rider@example.com');
      // No password: the account signs in with single sign-on, which is already a second step.
      account.password = '';
      server.signInBrowser(account);
      await pumpScreen(tester, const TwoFactorScreen(), server: server);

      expect(
        find.text(
          'This account signs in with single sign-on, so it already has a second step.',
        ),
        findsOneWidget,
      );
      expect(find.text('Set up an authenticator'), findsNothing);
      expect(find.byKey(const Key('two-factor-start')), findsNothing);
    },
  );

  testWidgets(
    'TwoFactorScreen_ShouldShowTheRecoveryCodesInTheirOwnCard_WhenTurnedOn',
    (tester) async {
      server.signInBrowser(server.add('rider@example.com'));
      await pumpScreen(tester, const TwoFactorScreen(), server: server);

      await tester.tap(find.byKey(const Key('two-factor-start')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('two-factor-password')),
        'Rider-pass-123',
      );
      await tester.enterText(
        find.byKey(const Key('two-factor-code')),
        '123456',
      );
      await tester.tap(find.byKey(const Key('two-factor-enable')));
      await tester.pumpAndSettle();

      // The codes are a card of their own, with their sentence, and the state stays on the setup card.
      expect(find.text('Recovery codes'), findsOneWidget);
      expect(find.text('AAAA-1111'), findsOneWidget);
      expect(find.text('Two-factor sign-in is on.'), findsOneWidget);
    },
  );

  for (final width in [390.0, 1300.0]) {
    testWidgets(
      'TwoFactorScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
        server.signInBrowser(server.add('rider@example.com'));
        await pumpScreen(
          tester,
          const TwoFactorScreen(),
          server: server,
          size: Size(width, 1600),
        );

        expect(find.byKey(const Key('two-factor-start')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
