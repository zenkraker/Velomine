import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine_api/api.dart';

import 'package:velomine/core/result.dart';
import 'package:velomine/core/widgets/app_card.dart';
import 'package:velomine/features/rides/rides_data.dart';
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

  testWidgets(
    'RidesScreen_ShouldLeaveTheEmptyStateToThePage_WhenAPhoneHasNoRides',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));

      final empty = find.byKey(const Key('no-rides'));
      expect(empty, findsOneWidget);
      // No wall of import buttons inside the empty state: the ways in are the page's own.
      expect(find.byKey(const Key('empty-upload')), findsNothing);
      expect(find.byKey(const Key('empty-import-strava')), findsNothing);
      expect(find.byKey(const Key('empty-bulk-folder')), findsNothing);
      expect(find.byKey(const Key('upload')), findsOneWidget);

      await tester.tap(find.byKey(const Key('rides-actions')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('import-strava')), findsOneWidget);
    },
  );

  testWidgets('RidesScreen_ShouldPutTheDateBesideTheTitle_WhenTheRideHasOne', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    server.rides.add(
      rideJson(
        'r1',
        'ready',
        fileName: 'sunday.gpx',
        title: 'Sunday morning ride',
        distanceM: 42000,
        movingS: 5400,
      ),
    );
    await startApp(tester, server.session(useCookies: true));

    final card = find.byKey(const Key('ride-r1'));
    // The shared card, not a hand-built one.
    expect(tester.widget(card), isA<AppCard>());
    final title = find.descendant(
      of: card,
      matching: find.byKey(const Key('ride-title')),
    );
    // The moment is a caption on the title's own line, right of it, not a line under it.
    final date = find.descendant(
      of: card,
      matching: find.byKey(const Key('ride-date')),
    );
    expect(date, findsOneWidget);
    expect(
      tester.getTopLeft(date).dy,
      closeTo(tester.getTopLeft(title).dy, 2),
      reason: 'the date sits on the title line',
    );
    expect(
      tester.getTopLeft(date).dx,
      greaterThan(tester.getTopLeft(title).dx),
    );
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

      // Start ride is the first entry of the page's menu.
      await tester.tap(find.byKey(const Key('rides-actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start-ride')));
      await tester.pumpAndSettle();

      expect(find.byType(RecordingScreen), findsOneWidget);
      expect(recorder.starts, 0);
      // A pushed screen: the way back returns to Rides.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(RecordingScreen), findsNothing);
      expect(find.byKey(const Key('upload')), findsOneWidget);
    },
  );

  testWidgets('RidesScreen_ShouldPutStartRideInTheMenu_WhenThePhoneCanRecord', (
    tester,
  ) async {
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
    // Upload is the header's one action at every width; Start ride waits in the menu.
    expect(find.byKey(const Key('upload')), findsOneWidget);
    expect(find.byKey(const Key('start-ride')), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.tap(find.byKey(const Key('rides-actions')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('start-ride')), findsOneWidget);
  });

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

    expect(find.byType(RecordingScreen), findsOneWidget);
    expect(find.byKey(const Key('live-ride-banner')), findsNothing);
  });

  for (final width in [390.0, 600.0, 1300.0]) {
    testWidgets('RidesScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}', (
      tester,
    ) async {
      server.rides.add(
        rideJson(
          'r2',
          'ready',
          distanceM: 42000,
          movingS: 5400,
          elevationGainM: 300,
          avgSpeedMs: 7.8,
        ),
      );
      tester.view.physicalSize = Size(width, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));

      expect(find.byKey(const Key('ride-r2')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('RidesScreen_ShouldOfferOneMainAction_WhenTheWindowIsAPhone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));

    // One filled action in the header, and the imports behind the menu.
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byKey(const Key('upload')), findsOneWidget);
    // The imports and the filters sit behind the header's menu.
    expect(find.byKey(const Key('rides-actions')), findsOneWidget);
  });

  testWidgets('RidesScreen_ShouldNotOverflow_WhenTextIsTwiceItsSize', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    server.rides.add(
      rideJson(
        'r2',
        'ready',
        distanceM: 42000,
        movingS: 5400,
        elevationGainM: 300,
        avgSpeedMs: 7.8,
      ),
    );
    await startApp(tester, server.session(useCookies: true));

    expect(tester.takeException(), isNull);
  });

  test('RidesData_ShouldSendTheEnvironmentAndTheCommute_WhenThoseFiltersAreChosen', () async {
    late http.Request sent;
    final client = ApiClient(basePath: 'https://example.test')
      ..client = MockClient((request) async {
        sent = request;
        return http.Response('{"rides":[],"next":null}', 200);
      });

    await RidesData(RidesApi(client))
        .page(environment: 'indoor', commute: true);

    expect(sent.url.path, '/api/v1/rides');
    expect(sent.url.queryParameters, containsPair('environment', 'indoor'));
    expect(sent.url.queryParameters, containsPair('commute', 'true'));
    // Indoor is a place, never a discipline: the server would reject it there.
    expect(sent.url.queryParameters.containsKey('discipline'), isFalse);
  });

  testWidgets(
    'RidesScreen_ShouldAskForTheIndoorRides_WhenTheIndoorChipIsChosen',
    (tester) async {
      final data = _SpyRidesData();
      await startApp(
        tester,
        server.session(useCookies: true),
        overrides: [ridesDataProvider.overrideWithValue(data)],
      );

      await tester.tap(find.byKey(const Key('filter-indoor')));
      await tester.pumpAndSettle();

      expect(data.calls.last, (
        discipline: null,
        environment: 'indoor',
        commute: null,
      ));
    },
  );

  testWidgets(
    'RidesScreen_ShouldAskForTheCommutesOnly_WhenTheCommuteChipFollowsTheIndoorOne',
    (tester) async {
      final data = _SpyRidesData();
      await startApp(
        tester,
        server.session(useCookies: true),
        overrides: [ridesDataProvider.overrideWithValue(data)],
      );

      await tester.tap(find.byKey(const Key('filter-indoor')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter-commute')));
      await tester.pumpAndSettle();

      // The chips are one choice: the place the rider left is not asked for any more.
      expect(data.calls.last, (
        discipline: null,
        environment: null,
        commute: true,
      ));
      expect(
        tester
            .widget<FilterChip>(find.byKey(const Key('filter-indoor')))
            .selected,
        isFalse,
      );
      expect(
        tester
            .widget<FilterChip>(find.byKey(const Key('filter-commute')))
            .selected,
        isTrue,
      );
    },
  );
}

/// The ride list's data source, with the request the view model made written down instead of sent.
class _SpyRidesData extends RidesData {
  _SpyRidesData() : super(RidesApi());

  final calls = <({String? discipline, String? environment, bool? commute})>[];

  @override
  Future<Result<RidesPage>> page({
    String? cursor,
    String? discipline,
    String? environment,
    bool? commute,
    String? query,
    DateTime? from,
    DateTime? to,
  }) async {
    calls.add((
      discipline: discipline,
      environment: environment,
      commute: commute,
    ));
    return const Ok<RidesPage>((rides: <RideResponse>[], next: null));
  }
}
