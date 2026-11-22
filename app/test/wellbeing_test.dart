import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
  });

  Future<void> openWellbeing(
    WidgetTester tester, {
    Size size = const Size(1000, 2400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/progress/wellbeing');
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  const consented = {
    'date': '2026-11-08',
    'fatigue': 3,
    'soreness': 2,
    'mood': 4,
    'stress': 2,
    'motivation': 5,
  };

  testWidgets(
    'WellbeingScreen_ShouldGateOnConsentCheckInAndWithdraw_WhenConfirmed',
    (tester) async {
      await openWellbeing(tester);

      // Before the first check-in the consent card is the whole page: no check-in action.
      expect(find.byKey(const Key('wellbeing-consent-card')), findsOneWidget);
      expect(find.byKey(const Key('wellbeing-check-in')), findsNothing);
      await tester.tap(find.byKey(const Key('wellbeing-consent')));
      await tester.pumpAndSettle();
      expect(server.wellbeingConsent, isTrue);

      // Checking in opens a sheet, and the page's own action is the way in.
      await tester.tap(find.byKey(const Key('wellbeing-check-in')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      await tester.tap(find.byKey(const Key('wellbeing-save')));
      await tester.pumpAndSettle();

      expect(server.wellbeingToday?['fatigue'], 3);
      expect(server.wellbeingToday?['motivation'], 3);
      expect(find.byKey(const Key('wellbeing-card')), findsOneWidget);

      // Withdrawing lives in the page menu, last, red, and asks first.
      await tester.tap(find.byKey(const Key('wellbeing-actions')));
      await tester.pumpAndSettle();
      final entry = tester.widget<MenuItemButton>(
        find.byKey(const Key('wellbeing-withdraw')),
      );
      final scheme = Theme.of(
        tester.element(find.byKey(const Key('wellbeing-withdraw'))),
      ).colorScheme;
      expect(entry.style?.foregroundColor?.resolve({}), scheme.error);

      await tester.tap(find.byKey(const Key('wellbeing-withdraw')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('wellbeing-withdraw-confirm')));
      await tester.pumpAndSettle();

      expect(server.wellbeingConsent, isFalse);
      expect(server.sharingChoices['wellbeing'], 'none');
      expect(find.byKey(const Key('wellbeing-consent-card')), findsOneWidget);
    },
  );

  testWidgets('WellbeingScreen_ShouldKeepConsent_WhenWithdrawIsCancelled', (
    tester,
  ) async {
    server.wellbeingConsent = true;
    server.wellbeingToday = consented;
    await openWellbeing(tester);

    await tester.tap(find.byKey(const Key('wellbeing-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wellbeing-withdraw')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(server.wellbeingConsent, isTrue);
    expect(find.byKey(const Key('wellbeing-card')), findsOneWidget);
  });

  testWidgets('WellbeingScreen_ShouldShowReadinessAndFactors_WhenConsented', (
    tester,
  ) async {
    server.wellbeingConsent = true;
    server.wellbeingToday = consented;
    await openWellbeing(tester);

    await reveal(tester, find.byKey(const Key('readiness-card')));
    expect(find.byKey(const Key('readiness-card')), findsOneWidget);
    expect(find.byKey(const Key('readiness-score')), findsOneWidget);
    expect(find.byKey(const Key('readiness-band')), findsOneWidget);
    // Why the score is what it is sits on its own card, beside the score.
    expect(find.byKey(const Key('readiness-why')), findsOneWidget);
    expect(find.text('How you feel'), findsWidgets);
    expect(
      find.text('A training guide, not a medical measure.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'WellbeingScreen_ShouldListTwoWeeksOfCheckIns_WhenHistoryIsLong',
    (tester) async {
      server.wellbeingConsent = true;
      server.wellbeingToday = consented;
      server.checkIns.addAll([
        for (var i = 0; i < 20; i++)
          {
            'date': '2026-10-${(1 + i).toString().padLeft(2, '0')}',
            'fatigue': 2,
            'soreness': 2,
            'mood': 4,
            'stress': 2,
            'motivation': 4,
          },
      ]);
      await openWellbeing(tester);

      await reveal(tester, find.byKey(const Key('wellbeing-card')));
      // One line over the last two weeks, and fourteen rows under it, and no more.
      expect(find.byKey(const Key('wellbeing-history-chart')), findsOneWidget);
      final rows = find.textContaining('Fat 2');
      expect(rows, findsNWidgets(14));
    },
  );

  testWidgets('WellbeingCard_ShouldSaveSleep_WhenTheRiderPicksAScore', (
    tester,
  ) async {
    server.wellbeingConsent = true;
    await openWellbeing(tester);

    await tester.tap(find.byKey(const Key('wellbeing-check-in')));
    await tester.pumpAndSettle();
    // Sleep is the first question, and starts at 3 like the others.
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('wellbeing-sleep')),
        matching: find.text('2'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wellbeing-save')));
    await tester.pumpAndSettle();

    expect(server.wellbeingToday?['sleep'], 2);
    expect(find.text('Sleep 2'), findsOneWidget);
  });

  testWidgets('WellbeingCard_ShouldShowNoSleep_WhenTheCheckInHasNone', (
    tester,
  ) async {
    server.wellbeingConsent = true;
    // A check-in saved before sleep was asked carries no sleep at all.
    server.wellbeingToday = consented;
    await openWellbeing(tester);

    await reveal(tester, find.byKey(const Key('wellbeing-card')));
    expect(find.text('Sleep 0'), findsNothing);
    expect(find.textContaining('Sleep'), findsNothing);
    expect(find.text('Motivation 5'), findsOneWidget);
  });

  for (final width in [390.0, 600.0, 820.0, 1300.0]) {
    testWidgets(
      'WellbeingScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
        server.wellbeingConsent = true;
        server.wellbeingToday = consented;
        await openWellbeing(tester, size: Size(width, 2400));

        expect(find.byKey(const Key('wellbeing-card')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('WellbeingScreen_ShouldNotOverflow_WhenTextIsTwiceItsSize', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    server.wellbeingConsent = true;
    server.wellbeingToday = consented;
    await openWellbeing(tester, size: const Size(390, 2800));

    expect(tester.takeException(), isNull);
  });
}
