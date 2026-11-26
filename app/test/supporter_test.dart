import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:velomine/core/widgets/page_scaffold.dart';
import 'package:velomine/core/widgets/bottom_action_bar.dart';
import 'package:velomine/features/supporter/supporter_badge.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';
import 'package:velomine/features/supporter/supporter_celebration_screen.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;
  // The app's router, so a test can open an address as a returning member would.
  GoRouter? router;

  setUp(() {
    router = null;
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com', name: 'Ada'));
  });

  Future<void> openProfile(
    WidgetTester tester, {
    Size size = const Size(1000, 2000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // No motion, so the celebration settles on its last frame instead of playing for 5 s.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final session = server.session(useCookies: true);
    await startApp(tester, session, onRouter: (created) => router = created);
    await openAccount(tester, 'profile');
    await tester.pumpAndSettle();
  }

  /// The strings the moment shows, for the language on screen. The
  /// celebration's own element carries them; the app above it does not.
  AppLocalizations strings(WidgetTester tester) => AppLocalizations.of(
    tester.element(find.byKey(const Key('supporter-headline'))),
  );

  void licence() => server.supporterLicences['rider@example.com'] = {
    'holder': 'Ada',
    'serial': 42,
    'hidden': false,
  };

  testWidgets('ProfileScreen_ShouldOfferSupporterEntry_WhenThereIsNoLicence', (
    tester,
  ) async {
    await openProfile(tester);
    expect(find.byKey(const Key('supporter-become')), findsOneWidget);
    expect(find.byKey(const Key('supporter-badge')), findsNothing);
  });

  testWidgets('ProfileScreen_ShouldShowTheBadge_WhenTheLicenceIsShown', (
    tester,
  ) async {
    licence();
    await openProfile(tester);
    expect(find.byKey(const Key('supporter-badge')), findsOneWidget);
    expect(find.byKey(const Key('supporter-become')), findsNothing);
  });

  testWidgets('ProfileScreen_ShouldNameTheLicenceInTheBadge_WhenItIsShown', (
    tester,
  ) async {
    licence();
    await openProfile(tester);

    // The badge carries the licence itself: its number and the day it was activated.
    final badge = tester.widget<SupporterBadge>(
      find.byKey(const Key('supporter-badge')),
    );
    expect(badge.label, contains('42'));
    expect(badge.label, contains('Supporter'));
  });

  testWidgets('ProfileScreen_ShouldReplayFromTheLink_WhenItIsTapped', (
    tester,
  ) async {
    licence();
    await openProfile(tester);

    final link = find.byKey(const Key('supporter-replay'));
    await tester.ensureVisible(link);
    await tester.pumpAndSettle();
    await tester.tap(link);
    await tester.pumpAndSettle();

    expect(find.byType(SupporterCelebrationScreen), findsOneWidget);
  });

  testWidgets('ProfileScreen_ShouldHideTheBadge_WhenTheSwitchIsOff', (
    tester,
  ) async {
    licence();
    await openProfile(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('supporter-hidden')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('supporter-hidden')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('supporter-badge')), findsNothing);
    expect(server.supporterLicences['rider@example.com']!['hidden'], isTrue);
  });

  testWidgets(
    'SupporterActivationScreen_ShouldKeepSubmitInTheBottomBar_WhenTheScreenOpens',
    (tester) async {
      await openProfile(tester);
      await tester.ensureVisible(find.byKey(const Key('supporter-become')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('supporter-become')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(BottomActionBar),
          matching: find.byKey(const Key('supporter-activate')),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('SupporterCelebration_ShouldBeAPageLikeAnyOther_WhenShown', (
    tester,
  ) async {
    licence();
    await openProfile(tester);
    final badge = find.byKey(const Key('supporter-badge'));
    await tester.ensureVisible(badge);
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(badge);
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.pumpAndSettle();

    // The one bespoke screen is a PageScaffold, and its own lights come from the theme: no eyebrow, no
    // "verified" chip and no second line under the badge, as the mock-up draws it.
    expect(
      find.descendant(
        of: find.byType(SupporterCelebrationScreen),
        matching: find.byType(PageScaffold),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('supporter-eyebrow')), findsNothing);
    expect(find.text('Licence verified'.toUpperCase()), findsNothing);
    expect(find.byKey(const Key('supporter-chip')), findsNothing);
    // The headline is the theme's page title, not a scaled one with a serif fallback.
    final headline = tester.widget<Text>(
      find.byKey(const Key('supporter-headline')),
    );
    final pageTitle = Theme.of(
      tester.element(find.byKey(const Key('supporter-headline'))),
    ).textTheme.headlineLarge;
    expect(headline.style?.fontFamily, pageTitle?.fontFamily);
    expect(headline.style?.fontSize, pageTitle?.fontSize);
    // The supporting text is the theme's muted ink, and the button the one accent.
    expect(find.byKey(const Key('supporter-body')), findsOneWidget);
    expect(find.byKey(const Key('supporter-continue')), findsOneWidget);
  });

  testWidgets('SupporterBadge_ShouldOpenTheCelebration_WhenTappedThreeTimes', (
    tester,
  ) async {
    licence();
    await openProfile(tester);
    final badge = find.byKey(const Key('supporter-badge'));
    expect(badge, findsOneWidget);
    await tester.ensureVisible(badge);
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(badge);
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.pumpAndSettle();

    expect(find.byType(SupporterCelebrationScreen), findsOneWidget);
    final l10n = strings(tester);
    expect(find.byKey(const Key('supporter-headline')), findsOneWidget);
    // The whole name, once: "Thank you, Ada.", not the placeholder's own full stop twice.
    expect(find.text(l10n.supporterThanksName('Ada')), findsOneWidget);
    expect(find.text(l10n.supporterContinue), findsOneWidget);
    // The licence's own badge pill is on the celebration too, the same widget as the profile's.
    expect(
      find.descendant(
        of: find.byType(SupporterCelebrationScreen),
        matching: find.byType(SupporterBadge),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('42'), findsOneWidget);
  });

  testWidgets('SupporterBadge_ShouldNotOpenTheCelebration_WhenTappedTwice', (
    tester,
  ) async {
    licence();
    await openProfile(tester);
    final badge = find.byKey(const Key('supporter-badge'));
    await tester.ensureVisible(badge);
    await tester.pumpAndSettle();
    await tester.tap(badge);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(badge);
    await tester.pumpAndSettle();
    expect(find.byType(SupporterCelebrationScreen), findsNothing);
  });

  testWidgets(
    'SupporterActivationScreen_ShouldShowTheCelebration_WhenTheKeyIsAccepted',
    (tester) async {
      await openProfile(tester);
      await tester.ensureVisible(find.byKey(const Key('supporter-become')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('supporter-become')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('supporter-key')),
        'SUPPORTER-1-ADA',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('supporter-activate')));
      await tester.pumpAndSettle();

      expect(find.byType(SupporterCelebrationScreen), findsOneWidget);
      expect(find.byKey(const Key('supporter-activate-error')), findsNothing);
    },
  );

  testWidgets(
    'SupporterActivationScreen_ShouldWordTheRefusal_WhenTheKeyIsWrong',
    (tester) async {
      await openProfile(tester);
      await tester.ensureVisible(find.byKey(const Key('supporter-become')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('supporter-become')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('supporter-key')), 'nope');
      await tester.pump();
      await tester.tap(find.byKey(const Key('supporter-activate')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('supporter-activate-error')), findsOneWidget);
      // The refusal reads as the app words it, not the server's English sentence.
      final l10n = AppLocalizations.of(
        tester.element(find.byKey(const Key('supporter-activate-error'))),
      );
      expect(find.textContaining(l10n.supporterKeyInvalid), findsOneWidget);
      expect(find.byType(SupporterCelebrationScreen), findsNothing);
      expect(server.supporterLicences, isEmpty);
    },
  );

  testWidgets(
    'SupporterActivationScreen_ShouldNameTheExistingLicence_WhenAlreadyActivated',
    (tester) async {
      licence();
      await openProfile(tester);
      // The activation is opened by its address, as a returning member would.
      router!.push('/profile/supporter');
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('supporter-key')),
        'SUPPORTER-1-ADA',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('supporter-activate')));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byKey(const Key('supporter-activate-error'))),
      );
      expect(
        find.textContaining(l10n.supporterAlreadyActivated),
        findsOneWidget,
      );
      expect(find.byType(SupporterCelebrationScreen), findsNothing);
    },
  );

  testWidgets(
    'SupporterActivationScreen_ShouldNameItselfAndExplainTheKey_WhenItOpens',
    (tester) async {
      await openProfile(tester);
      await tester.ensureVisible(find.byKey(const Key('supporter-become')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('supporter-become')));
      await tester.pumpAndSettle();

      // The page carries the title and the sentence; the card holds the key alone.
      expect(find.text('Become a supporter'), findsOneWidget);
      expect(
        find.textContaining('Paste the key you were sent'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('supporter-key')), findsOneWidget);
    },
  );

  for (final width in [390.0, 1300.0]) {
    testWidgets(
      'SupporterActivationScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
        await openProfile(tester, size: Size(width, 2000));
        await tester.ensureVisible(find.byKey(const Key('supporter-become')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('supporter-become')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('supporter-key')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final width in [390.0, 600.0, 820.0, 1300.0]) {
    testWidgets(
      'SupporterCelebrationScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
        licence();
        await openProfile(tester, size: Size(width, 2000));
        // The celebration opens from its own address, as the replay and a returning visitor do.
        router!.go('/profile/supporter/activated');
        await tester.pumpAndSettle();

        expect(find.byType(SupporterCelebrationScreen), findsOneWidget);
        expect(find.byKey(const Key('supporter-continue')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'SupporterCelebrationScreen_ShouldGoToTheProfile_WhenThereIsNoLicence',
    (tester) async {
      await openProfile(tester);
      // The celebration's address opened with nothing to celebrate: a stale link, from before the licence.
      router!.go('/profile/supporter/activated');
      await tester.pumpAndSettle();

      expect(find.byType(SupporterCelebrationScreen), findsNothing);
      expect(find.byKey(const Key('supporter-become')), findsOneWidget);
    },
  );
}
