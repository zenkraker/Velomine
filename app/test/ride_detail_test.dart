import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/features/rides/detail/ride_detail_controller.dart';
import 'package:velomine/features/rides/detail/ride_detail_screen.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;
  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
    server.rides.add(
      rideJson(
        'r1',
        'ready',
        distanceM: 42300,
        movingS: 5400,
        elevationGainM: 612.4,
        avgSpeedMs: 7.8,
        avgPowerW: 190,
        normalizedPowerW: 205,
        avgHeartRate: 148,
        avgCadence: 87,
        fileName: 'sunday.gpx',
        intensityFactor: 0.82,
        tss: 62.4,
        trimp: 48.2,
        heartRateZones: [
          zoneJson(1, 74, 89, 600),
          zoneJson(2, 90, 103, 1200),
          zoneJson(3, 104, 118, 900),
          zoneJson(4, 119, 133, 300),
          zoneJson(5, 134, null, 60),
        ],
        powerZones: [
          zoneJson(1, 0, 137, 900),
          zoneJson(2, 138, 187, 1200),
          zoneJson(3, 188, 224, 600),
          zoneJson(4, 225, 262, 300),
          zoneJson(5, 263, 299, 120),
          zoneJson(6, 300, 374, 60),
          zoneJson(7, 375, null, 20),
        ],
      ),
    );
    server.streams['r1'] = streamsJson();
  });

  Future<void> open(WidgetTester tester, {String id = 'r1'}) async {
    tester.view.physicalSize = const Size(1000, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.byKey(Key('ride-$id')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'opening a ride shows its numbers, its route and a chart for each signal it has',
    (tester) async {
      await open(tester);

      expect(find.text('sunday.gpx'), findsOneWidget);
      for (final text in [
        '42.3 km',
        '1 h 30 min',
        '612 m',
        '28.1 km/h',
        '190 W',
        '205 W',
        '148 bpm',
        '87 rpm',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.byKey(const Key('route-map')), findsOneWidget);
      for (final chart in ['elevation', 'speed', 'power', 'heartrate']) {
        expect(find.byKey(Key('chart-$chart')), findsOneWidget, reason: chart);
      }
      expect(
        find.byKey(const Key('chart-cadence')),
        findsNothing,
      ); // this ride has no cadence samples
      expect(server.requests, contains('GET /api/v1/rides/r1/streams'));
    },
  );

  testWidgets('training load and zone times show when the profile has them', (
    tester,
  ) async {
    await open(tester);

    expect(find.byKey(const Key('heart-rate-zones')), findsOneWidget);
    expect(find.byKey(const Key('power-zones')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('stat-intensity')),
        matching: find.text('0.82'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('stat-tss')),
        matching: find.text('62'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('stat-trimp')),
        matching: find.text('48'),
      ),
      findsOneWidget,
    );
    expect(find.text('Heart rate zones'), findsOneWidget);
    expect(find.text('Power zones'), findsOneWidget);
    expect(find.textContaining('TSS uses your FTP'), findsOneWidget);
  });

  testWidgets(
    'touching a chart shows the values at that moment on every chart',
    (tester) async {
      await open(tester);
      expect(find.byKey(const Key('readout-power')), findsOneWidget);
      expect(
        find.textContaining('avg'),
        findsWidgets,
      ); // before touching: the summary

      final chart = find.byKey(const Key('chart-power'));
      final box = tester.getRect(chart);
      // About a third of the way along the plot area (which starts 46 px in and ends 10 px before the edge).
      await tester.tapAt(
        Offset(box.left + 46 + (box.width - 56) * 0.5, box.center.dy),
      );
      await tester.pump();

      expect(find.byKey(const Key('moment')), findsOneWidget);
      // The middle of a 59 second ride, at 10 m a second.
      expect(
        tester.widget<Text>(find.byKey(const Key('moment'))).data,
        matches(RegExp(r'^At 0:(29|30) · 0\.3 km$')),
      );
      final power = tester
          .widget<Text>(find.byKey(const Key('readout-power')))
          .data!;
      expect(
        power,
        anyOf('180 W', '220 W'),
      ); // the exact value of the sample, not the summary
      expect(
        tester.widget<Text>(find.byKey(const Key('readout-heartrate'))).data,
        endsWith('bpm'),
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('readout-heartrate'))).data,
        isNot(contains('avg')),
      );
    },
  );

  testWidgets('a ride without GPS (indoor) has charts and no map', (
    tester,
  ) async {
    server.streams['r1'] = streamsJson(position: false);
    await open(tester);

    expect(find.byKey(const Key('route-map')), findsNothing);
    expect(find.byKey(const Key('chart-power')), findsOneWidget);
  });

  testWidgets('speed is worked out from the positions when the file has none', (
    tester,
  ) async {
    server.streams['r1'] = streamsJson(speed: false);
    await open(tester);

    expect(find.byKey(const Key('chart-speed')), findsOneWidget);
  });

  testWidgets('a ride that could not be read says why, and has no charts', (
    tester,
  ) async {
    server.rides.add(
      rideJson('r2', 'failed', error: 'not_cycling', fileName: 'run.fit'),
    );
    await open(tester, id: 'r2');

    expect(find.text('This is not a cycling activity.'), findsOneWidget);
    expect(find.byKey(const Key('route-map')), findsNothing);
    expect(find.byKey(const Key('chart-power')), findsNothing);
    expect(server.requests, isNot(contains('GET /api/v1/rides/r2/streams')));
  });

  testWidgets('a ride that does not exist, or is not yours, says so', (
    tester,
  ) async {
    final session = server.session(useCookies: true);
    final controller = RideDetailController(
      api: session.rides,
      bikesApi: session.bikes,
      id: 'nobody-has-this-ride',
      onUnauthorized: () {},
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RideDetailScreen(
            controller: controller,
            onBack: () {},
            onDeleted: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('not-found')), findsOneWidget);
    expect(find.byKey(const Key('delete')), findsNothing);
    expect(controller.notFound, isTrue);
  });

  testWidgets('a ride still being read is shown as such, then fills in', (
    tester,
  ) async {
    server.rides.add(rideJson('r3', 'processing', fileName: 'big.fit'));
    final session = server.session(useCookies: true);
    final controller = RideDetailController(
      api: session.rides,
      bikesApi: session.bikes,
      id: 'r3',
      onUnauthorized: () {},
      pollInterval: const Duration(milliseconds: 10),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RideDetailScreen(
            controller: controller,
            onBack: () {},
            onDeleted: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 5));
    expect(find.byKey(const Key('processing')), findsOneWidget);

    server.rides[server.rides.indexWhere((r) => r['id'] == 'r3')] = rideJson(
      'r3',
      'ready',
      fileName: 'big.fit',
      distanceM: 1000,
      movingS: 120,
    );
    server.streams['r3'] = streamsJson();
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('processing')), findsNothing);
    expect(find.text('1.0 km'), findsOneWidget);
  });

  testWidgets('the back button returns to the list', (tester) async {
    await open(tester);

    await tester.tap(find.byKey(const Key('back')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('upload')), findsOneWidget);
    expect(find.byKey(const Key('ride-r1')), findsOneWidget);
  });

  testWidgets('deleting asks first, and then removes the ride', (tester) async {
    await open(tester);

    await tester.tap(find.byKey(const Key('delete')));
    await tester.pumpAndSettle();
    expect(find.text('Delete this ride?'), findsOneWidget);
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(server.requests, isNot(contains('DELETE /api/v1/rides/r1')));
    expect(find.byKey(const Key('delete')), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();

    expect(server.requests, contains('DELETE /api/v1/rides/r1'));
    expect(find.byKey(const Key('ride-r1')), findsNothing);
    expect(find.byKey(const Key('no-rides')), findsOneWidget);
  });

  group('map tiles', () {
    testWidgets('are not requested unless the server offers an address', (
      tester,
    ) async {
      await open(tester);

      expect(find.byKey(const Key('map-attribution')), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('tile-'),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'are laid out from the address, with the provider credit shown',
      (tester) async {
        server.tileUrl = 'https://tiles.example/{z}/{x}/{y}.png';
        await open(tester);

        expect(find.byKey(const Key('map-attribution')), findsOneWidget);
        expect(find.text('© Test Maps'), findsOneWidget);
        final tiles = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith(
                'tile-https://tiles.example/',
              ),
        );
        expect(tiles, findsWidgets);
        expect(
          tester.widgetList(tiles).length,
          lessThan(30),
        ); // a screenful, not the world
      },
    );
  });
}
