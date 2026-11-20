import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/features/rides/detail/ride_detail_screen.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    // The card is part of the analysis, so the simple rider modes fold it: these tests are a settled rider's.
    server.signInBrowser(
      server.add('rider@example.com', riderMode: 'training'),
    );
    server.totals['week'] = [
      totalsJson('2026-11-02', '2026-11-08', rides: 1, distanceM: 60000),
    ];
  });

  Future<void> openProgress(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
  }

  testWidgets('RiderCard_ShouldShowTheNumbers_WhenTheRiderHasThem', (
    tester,
  ) async {
    await openProgress(tester);

    expect(find.byKey(const Key('rider-card')), findsOneWidget);
    expect(find.byKey(const Key('rider-card-ftp')), findsOneWidget);
    expect(find.text('250 W'), findsOneWidget);
    expect(find.text('3.6'), findsOneWidget);
    expect(find.text('165 bpm'), findsOneWidget);
    expect(find.text('42'), findsWidgets);
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
    await openProgress(tester);

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

  testWidgets('RiderCard_ShouldSayWhereEachNumberCameFrom_WhenMoreIsTapped', (
    tester,
  ) async {
    await openProgress(tester);

    await tester.tap(find.byKey(const Key('rider-card-more')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('rider-card-row-ftp')), findsOneWidget);
    // The FTP and the threshold were both typed on the same day.
    expect(find.text('Set by you on Nov 1, 2026'), findsNWidgets(2));
    expect(
      find.text('Estimated from your age (208 − 0.7 × age)'),
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
    await openProgress(tester);

    await tester.tap(find.byKey(const Key('rider-card-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rider-card-best-300')));
    await tester.pumpAndSettle();

    expect(find.byType(RideDetailScreen), findsOneWidget);
  });
}
