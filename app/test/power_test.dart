import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
  });

  Future<void> openPower(
    WidgetTester tester, {
    Size size = const Size(1000, 2400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/progress/power');
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('PowerScreen_ShouldKeepUseFtp_WhenEstimateDiffers', (
    tester,
  ) async {
    await openPower(tester);

    // The estimate is offered on the FTP card, which is the number it would change.
    expect(find.byKey(const Key('power-ftp-card')), findsOneWidget);
    expect(find.byKey(const Key('ftp-estimate-today')), findsOneWidget);
    expect(find.byKey(const Key('use-ftp')), findsOneWidget);
    await reveal(tester, find.byKey(const Key('power-curve-card')));
    expect(find.byKey(const Key('power-curve-card')), findsOneWidget);

    await tester.tap(find.byKey(const Key('use-ftp')));
    await tester.pumpAndSettle();

    expect(server.profiles['rider@example.com']?['ftpW'], 266);
  });

  testWidgets('PowerScreen_ShouldShowTheFtpReminder_WhenTheCheckHasAReason', (
    tester,
  ) async {
    server.ftpCheck['rider@example.com'] = {
      'reason': 'stale',
      'ftpW': 250,
      'ftpAgeDays': 49,
      'estimateW': 268,
      'estimateMethod': '20min',
    };
    await openPower(tester);

    final card = find.byKey(const Key('ftp-reminder'));
    await reveal(tester, card);
    expect(find.text('Your FTP is 7 weeks old'), findsOneWidget);
    expect(find.byKey(const Key('ftp-reminder-use')), findsOneWidget);

    await tester.tap(find.byKey(const Key('ftp-reminder-how')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ftp-reminder-how-body')), findsOneWidget);

    // The card is behind the sheet, so closing it is the way back to "Use ... W".
    Navigator.of(tester.element(find.byKey(const Key('ftp-reminder-how-body'))))
        .pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ftp-reminder-how-body')), findsNothing);

    await tester.tap(find.byKey(const Key('ftp-reminder-use')));
    await tester.pumpAndSettle();
    expect(server.profiles['rider@example.com']?['ftpW'], 268);
  });

  testWidgets('PowerScreen_ShouldHideTheReminder_WhenSnoozed', (tester) async {
    server.ftpCheck['rider@example.com'] = {
      'reason': 'missing',
      'ftpW': null,
      'estimateW': 268,
      'estimateMethod': '20min',
    };
    await openPower(tester);

    await reveal(tester, find.byKey(const Key('ftp-reminder')));
    expect(find.text('Set your FTP'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ftp-reminder-not-now')));
    await tester.pumpAndSettle();

    expect(server.snoozeRequests, 1);
    expect(find.byKey(const Key('ftp-reminder')), findsNothing);
  });

  testWidgets(
    'PowerScreen_ShouldShowTheSuggestionInsteadOfTheReminder_WhenARideSuggestsAnFtp',
    (tester) async {
      server.ftpSuggestions['rider@example.com'] = {
        'id': 'suggestion-1',
        'rideId': 'ride-1',
        'watts': 266,
        'method': '20min',
        'effortWatts': 280,
        'createdAt': '2026-11-10T09:00:00Z',
      };
      server.ftpCheck['rider@example.com'] = {
        'reason': 'stale',
        'ftpW': 250,
        'ftpAgeDays': 49,
        'estimateW': 268,
        'estimateMethod': '20min',
      };
      await openPower(tester);

      final card = find.byKey(const Key('ftp-suggestion'));
      await reveal(tester, card);
      expect(find.text('This ride suggests an FTP of 266 W'), findsOneWidget);
      // The reminder would ask about the number the suggestion is about to replace.
      expect(find.byKey(const Key('ftp-reminder')), findsNothing);

      await tester.tap(find.byKey(const Key('ftp-suggestion-use')));
      await tester.pumpAndSettle();

      expect(server.acceptedSuggestions, ['suggestion-1']);
      expect(find.byKey(const Key('ftp-suggestion')), findsNothing);
    },
  );

  testWidgets('PowerScreen_ShouldDropTheSuggestion_WhenTheMemberDismissesIt', (
    tester,
  ) async {
    server.ftpSuggestions['rider@example.com'] = {
      'id': 'suggestion-2',
      'rideId': 'ride-1',
      'watts': 272,
      'method': '30min',
      'effortWatts': 280,
      'createdAt': '2026-11-10T09:00:00Z',
    };
    await openPower(tester);

    await reveal(tester, find.byKey(const Key('ftp-suggestion')));
    expect(find.text('97 % of your best 30 minutes (280 W)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ftp-suggestion-dismiss')));
    await tester.pumpAndSettle();

    expect(server.dismissedSuggestions, ['suggestion-2']);
    expect(find.byKey(const Key('ftp-suggestion')), findsNothing);
  });

  for (final width in [390.0, 600.0, 820.0, 1300.0]) {
    testWidgets('PowerScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}', (
      tester,
    ) async {
      await openPower(tester, size: Size(width, 2400));

      await reveal(tester, find.byKey(const Key('power-curve-card')));
      expect(find.byKey(const Key('power-curve-card')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('PowerScreen_ShouldNotOverflow_WhenTextIsTwiceItsSize', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openPower(tester, size: const Size(390, 2600));

    expect(tester.takeException(), isNull);
  });

  testWidgets('PowerScreen_ShouldShowTheCardsAboveTheCurve_WhenOpened', (
    tester,
  ) async {
    await openPower(tester);

    // FTP, critical power and VO2max above the curve and the best efforts.
    expect(find.byKey(const Key('power-ftp-card')), findsOneWidget);
    expect(find.byKey(const Key('critical-power-card')), findsOneWidget);
    expect(find.byKey(const Key('vo2max-card')), findsOneWidget);
    expect(find.byKey(const Key('power-curve-card')), findsOneWidget);
    expect(find.byKey(const Key('best-efforts-card')), findsOneWidget);
    expect(find.byKey(const Key('critical-power-row')), findsOneWidget);
    expect(find.text('Best efforts'), findsOneWidget);
  });
}
