import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/placeholder_block.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
  });

  testWidgets('RidesScreen_ShouldShowPlaceholderCards_WhenTheLoadIsRunning', (
    tester,
  ) async {
    final gate = server.delayNext('/api/v1/rides');

    await startApp(tester, server.session(useCookies: true));

    expect(find.byKey(const Key('rides-loading')), findsOneWidget);
    expect(find.byType(PlaceholderBlock), findsNWidgets(5));

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rides-loading')), findsNothing);
  });

  testWidgets(
    'RideDetailScreen_ShouldShowPlaceholderStats_WhenTheLoadIsRunning',
    (tester) async {
      server.rides.add(rideJson('ride-1', 'ready', distanceM: 24500));
      await startApp(tester, server.session(useCookies: true));

      final gate = server.delayNext('/api/v1/rides/ride-1');
      await tester.tap(find.byKey(const Key('ride-ride-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ride-loading')), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ride-loading')), findsNothing);
    },
  );

  testWidgets(
    'ProgressScreen_ShouldShowPlaceholderCharts_WhenTheLoadIsRunning',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));

      final gate = server.delayNext('/api/v1/analytics/totals');
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('totals-loading')), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('totals-loading')), findsNothing);
    },
  );
}
