import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/features/rides/detail/ride_detail_screen.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
    server.totals['week'] = [
      totalsJson('2026-11-02', '2026-11-08', rides: 1, distanceM: 60000),
    ];
  });

  /// Progress → Power, where the rider's own numbers lead the page.
  Future<void> openPower(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/progress/power');
  }

  testWidgets('PowerScreen_ShouldShowYourNumbers_WhenTheRiderCardLoads', (
    tester,
  ) async {
    await openPower(tester);

    final card = find.byKey(const Key('rider-card'));
    expect(card, findsOneWidget);
    expect(find.text('Your numbers'), findsOneWidget);
    // The four numbers no other card on the page shows, each with where it came from.
    for (final key in [
      'rider-card-max-hr',
      'rider-card-threshold-hr',
      'rider-card-wkg',
      'rider-card-peak',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    expect(
      find.descendant(of: card, matching: find.text('187 bpm')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('3.6 W/kg')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('250 W at 70 kg')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('Best 5 s, last 90 days')),
      findsOneWidget,
    );
  });

  testWidgets('PowerScreen_ShouldOpenTheWholeRiderCard_WhenTheLinkIsTapped', (
    tester,
  ) async {
    await openPower(tester);

    await tester.tap(find.byKey(const Key('rider-card-more')));
    await tester.pumpAndSettle();

    // The sheet: every number, each saying where it came from.
    expect(find.byKey(const Key('rider-card-row-ftp')), findsOneWidget);
    // The FTP and the threshold were both typed on the same day; the page's FTP card says it too.
    expect(
      find.descendant(
        of: find.byKey(const Key('rider-card-row-ftp')),
        matching: find.text('Set by you on Nov 1, 2026'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('rider-card-row-threshold-hr')),
        matching: find.text('Set by you on Nov 1, 2026'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('rider-card-row-max-hr')),
        matching: find.text('Estimated from your age (208 − 0.7 × age)'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('rider-card-row-power')), findsOneWidget);
    expect(
      find.text('Critical power 250 W · W′ 20.0 kJ · Peak 900 W'),
      findsOneWidget,
    );
    expect(find.text('5s 900 W'), findsOneWidget);
    expect(find.text('From your effort score.'), findsOneWidget);
  });

  testWidgets('RiderCard_ShouldShowDashes_WhenTheRiderHasNoNumbers', (
    tester,
  ) async {
    server.riderCard = {
      ...riderCardJson(
        ftpW: null,
        weightKg: null,
        wattsPerKg: null,
        maxHeartRate: null,
        thresholdHeartRate: null,
        fitness: null,
      ),
      'bests': [
        for (final seconds in [5, 60, 300, 1200])
          {'seconds': seconds, 'watts': null, 'rideId': null, 'date': null},
      ],
    };
    await openPower(tester);

    await tester.tap(find.byKey(const Key('rider-card-more')));
    await tester.pumpAndSettle();

    // Every row says a dash rather than a zero the rider never earned.
    expect(find.text('–'), findsWidgets);
    for (final best in [5, 60, 300, 1200]) {
      final button = tester.widget<TextButton>(
        find.byKey(Key('rider-card-best-$best')),
      );
      expect(button.onPressed, isNull);
    }
  });

  testWidgets('RiderCard_ShouldOpenTheRide_WhenABestIsTapped', (tester) async {
    server.riderCard = {
      ...riderCardJson(
        bests: [
          {'seconds': 300, 'watts': 317, 'rideId': 'r1', 'date': '2026-11-03'},
        ],
      ),
    };
    server.rides.add(
      rideJson(
        'r1',
        'ready',
        distanceM: 42300,
        movingS: 5400,
        title: 'Hill reps',
      ),
    );
    await openPower(tester);

    await tester.tap(find.byKey(const Key('rider-card-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rider-card-best-300')));
    await tester.pumpAndSettle();

    expect(find.byType(RideDetailScreen), findsOneWidget);
  });
}
