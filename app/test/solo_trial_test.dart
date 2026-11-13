import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velomine/features/profile/solo_trial_badge.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() => server = FakeServer());

  Future<void> openProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await openAccount(tester, 'profile');
    await tester.pumpAndSettle();
  }

  testWidgets('ProfileScreen_ShouldShowTheSoloTrial_WhenTheAccountHasOne', (
    tester,
  ) async {
    final end = DateTime.now().toUtc().add(const Duration(days: 30));
    server.signInBrowser(
      server.add(
        'rider@example.com',
        name: 'Ada',
        soloTrialEndsAt: end.toIso8601String().substring(0, 10),
      ),
    );

    await openProfile(tester);

    expect(find.byKey(const Key('solo-trial')), findsOneWidget);
    expect(find.textContaining('Solo trial'), findsOneWidget);
  });

  testWidgets('ProfileScreen_ShouldShowNoTrial_WhenTheAccountHasNone', (
    tester,
  ) async {
    server.signInBrowser(server.add('rider@example.com', name: 'Ada'));

    await openProfile(tester);

    expect(find.byKey(const Key('solo-trial')), findsNothing);
  });

  testWidgets('SoloTrialBadge_ShouldSayItHasEnded_WhenTheDateIsPast', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: const [Locale('en'), Locale('it')],
          home: Scaffold(
            body: SoloTrialBadge(
              endsAt: DateTime.utc(2026, 11, 1),
              today: DateTime.utc(2026, 11, 13),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Solo trial · ended'), findsOneWidget);
  });
}
