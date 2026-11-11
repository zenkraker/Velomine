import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velomine/features/rides/rides_screen.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;
  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
  });

  testWidgets(
    'RidesScreen_ShouldKeepItsScroll_WhenTheMemberComesBackToTheTab',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (var i = 0; i < 12; i++) {
        server.rides.add(
          rideJson('r$i', 'ready', distanceM: 1000, movingS: 600),
        );
      }
      await startApp(tester, server.session(useCookies: true));

      final list = find
          .descendant(
            of: find.byType(RidesScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.drag(
        find.byKey(const Key('ride-r0')),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();
      final offset = tester.state<ScrollableState>(list).position.pixels;
      expect(offset, greaterThan(0));

      await tester.tap(find.text('Progress').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rides').last);
      await tester.pumpAndSettle();

      expect(
        tester
            .state<ScrollableState>(
              find
                  .descendant(
                    of: find.byType(RidesScreen),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            )
            .position
            .pixels,
        closeTo(offset, 1),
      );
    },
  );

  testWidgets('RidesScreen_ShouldShowNoRides_WhenThereAreNone', (tester) async {
    await startApp(tester, server.session(useCookies: true));

    expect(find.byKey(const Key('no-rides')), findsOneWidget);
  });

  testWidgets('RidesScreen_ShouldPutUploadInTheList_WhenTheScreenIsWide', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('upload'))),
      isA<FilledButton>(),
    );
  });

  testWidgets('RidesScreen_ShouldShowRideNumbers_WhenReady', (tester) async {
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
      ),
    );
    await startApp(tester, server.session(useCookies: true));

    for (final text in [
      '42.3 km',
      '1 h 30 min',
      '612 m up',
      '28.1 km/h',
      '190 W (NP 205)',
      '148 bpm',
      '87 rpm',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('RidesScreen_ShouldSayNoData_WhenTheFileHasNoSamples', (
    tester,
  ) async {
    server.rides.add(rideJson('r3', 'ready', distanceM: 0, movingS: 0));
    await startApp(tester, server.session(useCookies: true));

    expect(find.byKey(const Key('ride-no-data')), findsOneWidget);
    expect(find.text('0.0 km'), findsNothing);
  });

  testWidgets('RidesScreen_ShouldExplainFailure_WhenReadFails', (tester) async {
    server.rides.add(
      rideJson('r2', 'failed', error: 'not_cycling', fileName: 'run.fit'),
    );
    await startApp(tester, server.session(useCookies: true));

    expect(find.text('This is not a cycling activity.'), findsOneWidget);
    expect(find.text('run.fit'), findsOneWidget);
  });

  testWidgets('RidesScreen_ShouldShowRideBecomingReady_WhenAFileIsUploaded', (
    tester,
  ) async {
    await startApp(
      tester,
      server.session(useCookies: true),
      pickFile: fakeRideFile,
    );

    await tester.tap(find.byKey(const Key('upload')));
    await tester.pump(); // the upload and the first refresh
    await tester.pump(const Duration(milliseconds: 1));
    expect(server.requests, contains('POST /api/v1/rides/uploads'));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    expect(find.text('24.5 km'), findsOneWidget);
    expect(find.text('205 W (NP 212)'), findsOneWidget);
    expect(find.byKey(const Key('processing')), findsNothing);
  });

  testWidgets('RidesScreen_ShouldUploadNothing_WhenCancelled', (tester) async {
    await startApp(tester, server.session(useCookies: true));

    await tester.tap(find.byKey(const Key('upload')));
    await tester.pumpAndSettle();

    expect(server.requests, isNot(contains('POST /api/v1/rides/uploads')));
  });

  testWidgets(
    'RidesScreen_ShouldShowTheRideTypeChips_WhenTheRideHasDimensions',
    (tester) async {
      server.rides.add(
        rideJson(
          'r3',
          'ready',
          discipline: 'gravel',
          assist: 'ebike',
          environment: 'indoor',
          commute: true,
        ),
      );
      await startApp(tester, server.session(useCookies: true));

      for (final key in [
        'discipline-gravel',
        'assist-ebike',
        'environment-indoor',
        'commute',
      ]) {
        expect(find.byKey(Key('ride-type-$key')), findsOneWidget, reason: key);
      }
    },
  );

  testWidgets(
    'RidesScreen_ShouldShowOnlyOneSurface_WhenTheGravelFilterIsChosen',
    (tester) async {
      server.rides.add(
        rideJson('r1', 'ready', fileName: 'road.fit', discipline: 'road'),
      );
      server.rides.add(
        rideJson('r2', 'ready', fileName: 'gravel.fit', discipline: 'gravel'),
      );
      await startApp(tester, server.session(useCookies: true));
      expect(find.text('road.fit'), findsOneWidget);
      expect(find.text('gravel.fit'), findsOneWidget);

      await tester.tap(find.byKey(const Key('filter-gravel')));
      await tester.pumpAndSettle();

      expect(find.text('gravel.fit'), findsOneWidget);
      expect(find.text('road.fit'), findsNothing);
    },
  );

  testWidgets(
    'RidesScreen_ShouldShowOnlyTheChosenDiscipline_WhenTheFilterChangesDuringALoad',
    (tester) async {
      server.rides.add(
        rideJson('r1', 'ready', fileName: 'road.fit', discipline: 'road'),
      );
      server.rides.add(
        rideJson('r2', 'ready', fileName: 'gravel.fit', discipline: 'gravel'),
      );
      await startApp(tester, server.session(useCookies: true));

      final gate = server.delayNext('/api/v1/rides');
      await tester.tap(find.byKey(const Key('filter-gravel')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('filter-road')));
      await tester.pumpAndSettle();

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('road.fit'), findsOneWidget);
      expect(find.text('gravel.fit'), findsNothing);
    },
  );
}
