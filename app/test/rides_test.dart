import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velomine/features/rides/rides_screen.dart';
import 'package:velomine/features/rides/rides_view_model.dart';

import 'package:flutter_riverpod/misc.dart';
import 'package:velomine/features/recording/recording_providers.dart';
import 'package:velomine/features/recording/recording_screen.dart';

import 'fake_server.dart';
import 'recording_test.dart' show FakeRecorder, MemoryRecorderSettings;

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

  testWidgets('RidesScreen_ShouldPutUploadInTheHeader_WhenThereIsNoRecorder', (
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
    expect(find.byKey(const Key('start-ride')), findsNothing);
  });

  testWidgets('RidesScreen_ShouldHaveNoFloatingButton_WhenAPhoneHasRides', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    server.rides.add(rideJson('r1', 'ready', distanceM: 1000, movingS: 600));
    await startApp(tester, server.session(useCookies: true));

    expect(find.byType(FloatingActionButton), findsNothing);
    // No row of buttons over the list: the imports wait in the menu.
    expect(find.byKey(const Key('import-strava')), findsNothing);
    expect(find.byKey(const Key('rides-actions')), findsOneWidget);
  });

  testWidgets('RidesScreen_ShouldOfferEveryImport_WhenAPhoneHasNoRides', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));

    final empty = find.byKey(const Key('no-rides'));
    expect(empty, findsOneWidget);
    for (final key in ['empty-upload', 'empty-import-strava']) {
      expect(
        find.descendant(of: empty, matching: find.byKey(Key(key))),
        findsOneWidget,
        reason: key,
      );
    }
  });

  testWidgets('RidesScreen_ShouldPutTheImportsInAMenu_WhenAPhoneHasRides', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    server.rides.add(rideJson('r1', 'ready', distanceM: 1000, movingS: 600));
    await startApp(tester, server.session(useCookies: true));

    await tester.tap(find.byKey(const Key('rides-actions')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('import-strava')), findsOneWidget);
    expect(find.byKey(const Key('rides-filter')), findsOneWidget);
    // Without a recorder Upload is the header's button, so the menu does not repeat it.
    expect(find.byKey(const Key('upload')), findsOneWidget);
  });

  testWidgets(
    'RidesScreen_ShouldShowAFilterBadgeOnTheMenu_WhenAFilterIsActive',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      server.rides.add(
        rideJson('r1', 'ready', discipline: 'road', title: 'Road loop'),
      );
      await startApp(tester, server.session(useCookies: true));

      Finder badge() => find.descendant(
        of: find.byKey(const Key('rides-actions')),
        matching: find.byType(Badge),
      );
      expect(tester.widget<Badge>(badge()).isLabelVisible, isFalse);

      await tester.tap(find.byKey(const Key('rides-actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rides-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter-gravel')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(tester.widget<Badge>(badge()).isLabelVisible, isTrue);
    },
  );

  testWidgets(
    'RidesScreen_ShouldFilterFromOneSheet_WhenTheFilterButtonIsPressed',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      server.rides.add(
        rideJson('r1', 'ready', discipline: 'road', title: 'Road loop'),
      );
      await startApp(tester, server.session(useCookies: true));

      // The chips and the search are not on the list itself.
      expect(find.byKey(const Key('filter-gravel')), findsNothing);
      expect(find.byKey(const Key('ride-search')), findsNothing);

      await tester.tap(find.byKey(const Key('rides-actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rides-filter')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byKey(const Key('ride-search')), findsOneWidget);
      expect(find.byKey(const Key('ride-dates')), findsOneWidget);
      await tester.tap(find.byKey(const Key('filter-gravel')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(server.analyticsFilters, isEmpty);
      expect(find.byKey(const Key('ride-r1')), findsNothing);
    },
  );

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
      '612 m',
      '28.1 km/h',
      '190 W (NP 205)',
      '148 bpm',
      '87 rpm',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('RidesScreen_ShouldShowMiles_WhenUnitsAreImperial', (
    tester,
  ) async {
    server.accounts['rider@example.com']!.units = 'imperial';
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

    for (final text in ['26.3 mi', '2009 ft', '17.4 mph', '190 W (NP 205)']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('42.3 km'), findsNothing);
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
    expect(find.byKey(const Key('ride-r2')), findsOneWidget);
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
      server.rides.add(rideJson('r1', 'ready', discipline: 'road'));
      server.rides.add(rideJson('r2', 'ready', discipline: 'gravel'));
      await startApp(tester, server.session(useCookies: true));
      expect(find.byKey(const Key('ride-r1')), findsOneWidget);
      expect(find.byKey(const Key('ride-r2')), findsOneWidget);

      await tester.tap(find.byKey(const Key('filter-gravel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ride-r2')), findsOneWidget);
      expect(find.byKey(const Key('ride-r1')), findsNothing);
    },
  );

  testWidgets(
    'RidesScreen_ShouldShowOnlyTheChosenDiscipline_WhenTheFilterChangesDuringALoad',
    (tester) async {
      server.rides.add(rideJson('r1', 'ready', discipline: 'road'));
      server.rides.add(rideJson('r2', 'ready', discipline: 'gravel'));
      await startApp(tester, server.session(useCookies: true));

      final gate = server.delayNext('/api/v1/rides');
      await tester.tap(find.byKey(const Key('filter-gravel')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('filter-road')));
      await tester.pumpAndSettle();

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ride-r1')), findsOneWidget);
      expect(find.byKey(const Key('ride-r2')), findsNothing);
    },
  );

  testWidgets('RidesScreen_ShouldShowTheTitleAsTheMainLine_WhenTheRideHasOne', (
    tester,
  ) async {
    server.rides.add(
      rideJson(
        'r1',
        'ready',
        fileName: 'sunday.gpx',
        title: 'Gravel with Marco',
      ),
    );
    await startApp(tester, server.session(useCookies: true));

    expect(find.text('Gravel with Marco'), findsOneWidget);
  });

  testWidgets('RidesScreen_ShouldMakeUpATitle_WhenTheRideHasNone', (
    tester,
  ) async {
    server.rides.add(
      rideJson('r1', 'ready', discipline: 'gravel', utcOffsetMinutes: 0),
    );
    await startApp(tester, server.session(useCookies: true));

    expect(find.text('Morning gravel ride'), findsOneWidget);
  });

  testWidgets('RidesScreen_ShouldFindRidesByAWord_WhenTheMemberSearches', (
    tester,
  ) async {
    server.rides.add(
      rideJson('r1', 'ready', fileName: 'a.fit', title: 'Gravel with Marco'),
    );
    server.rides.add(
      rideJson(
        'r2',
        'ready',
        fileName: 'b.fit',
        title: 'Road loop',
        description: 'Rain all day',
      ),
    );
    await startApp(tester, server.session(useCookies: true));

    await tester.enterText(find.byKey(const Key('ride-search')), 'marco');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Gravel with Marco'), findsOneWidget);
    expect(find.text('Road loop'), findsNothing);
  });

  testWidgets('RidesScreen_ShouldExplainAndClear_WhenNothingMatchesTheSearch', (
    tester,
  ) async {
    server.rides.add(
      rideJson('r1', 'ready', fileName: 'a.fit', title: 'Gravel with Marco'),
    );
    await startApp(tester, server.session(useCookies: true));

    await tester.enterText(find.byKey(const Key('ride-search')), 'nothing');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('no-rides-match')), findsOneWidget);
    expect(find.text('No rides match.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('clear-filters')));
    await tester.pumpAndSettle();

    expect(find.text('Gravel with Marco'), findsOneWidget);
    expect(find.byKey(const Key('no-rides-match')), findsNothing);
  });

  testWidgets('RidesScreen_ShouldNarrowToTheChosenDays_WhenADateRangeIsSet', (
    tester,
  ) async {
    server.rides.add(
      rideJson(
        'r1',
        'ready',
        fileName: 'a.fit',
        startTime: '2026-11-01T07:30:00Z',
      ),
    );
    server.rides.add(
      rideJson(
        'r2',
        'ready',
        fileName: 'b.fit',
        startTime: '2026-11-05T07:30:00Z',
      ),
    );
    await startApp(tester, server.session(useCookies: true));

    await containerOf(tester)
        .read(ridesViewModelProvider.notifier)
        .setDateRange((from: DateTime(2026, 11, 1), to: DateTime(2026, 11, 1)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ride-r1')), findsOneWidget);
    expect(find.byKey(const Key('ride-r2')), findsNothing);
    expect(find.byKey(const Key('ride-dates-chip')), findsOneWidget);

    await tester.tap(find.byTooltip('Remove the date filter'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ride-r1')), findsOneWidget);
    expect(find.byKey(const Key('ride-r2')), findsOneWidget);
    expect(find.byKey(const Key('ride-dates-chip')), findsNothing);
  });

  testWidgets('RidesScreen_ShouldOpenTheDayPicker_WhenDatesArePressed', (
    tester,
  ) async {
    await startApp(tester, server.session(useCookies: true));

    await tester.tap(find.byKey(const Key('ride-dates')));
    await tester.pumpAndSettle();

    expect(find.byType(DateRangePickerDialog), findsOneWidget);
  });

  List<Override> recorderOverrides(FakeRecorder? recorder) => [
    recorderProvider.overrideWithValue(recorder),
    recorderSettingsStoreProvider.overrideWithValue(MemoryRecorderSettings()),
    uploadQueueProvider.overrideWithValue(null),
  ];

  testWidgets(
    'RidesScreen_ShouldOpenTheRecorderWithoutStarting_WhenStartRideIsTapped',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final recorder = FakeRecorder();
      await startApp(
        tester,
        server.session(useCookies: true),
        overrides: recorderOverrides(recorder),
      );

      await tester.tap(find.byKey(const Key('start-ride')));
      await tester.pumpAndSettle();

      expect(find.byType(RecordingScreen), findsOneWidget);
      expect(recorder.starts, 0);
      // A pushed screen: the way back returns to Rides.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(RecordingScreen), findsNothing);
      expect(find.byKey(const Key('start-ride')), findsOneWidget);
    },
  );

  testWidgets(
    'RidesScreen_ShouldPutUploadInTheMenu_WhenStartRideIsTheHeaderButton',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      server.rides.add(rideJson('r1', 'ready', distanceM: 1000, movingS: 600));
      await startApp(
        tester,
        server.session(useCookies: true),
        overrides: recorderOverrides(FakeRecorder()),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('start-ride')), findsOneWidget);
      expect(find.byKey(const Key('upload')), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);

      await tester.tap(find.byKey(const Key('rides-actions')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('upload')), findsOneWidget);
    },
  );

  testWidgets('RidesScreen_ShouldNotOfferStartRide_WhenThereIsNoRecorder', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(
      tester,
      server.session(useCookies: true),
      overrides: recorderOverrides(null),
    );

    expect(find.byKey(const Key('start-ride')), findsNothing);
  });

  testWidgets('HomeShell_ShouldOpenTheRecorder_WhenTheLiveRideBannerIsTapped', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final recorder = FakeRecorder();
    await startApp(
      tester,
      server.session(useCookies: true),
      overrides: recorderOverrides(recorder),
    );
    await recorder.start();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('live-ride-banner')), findsOneWidget);
    await tester.tap(find.byKey(const Key('live-ride-banner')));
    await tester.pumpAndSettle();

    // The test font is wider than the real one, so the recorder's live card overflows at phone width;
    // that layout is the recorder's own and not under test here.
    tester.takeException();
    expect(find.byType(RecordingScreen), findsOneWidget);
    expect(find.byKey(const Key('live-ride-banner')), findsNothing);
  });
}
