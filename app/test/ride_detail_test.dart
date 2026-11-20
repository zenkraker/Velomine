import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine/core/providers.dart';
import 'package:velomine/core/rider_mode.dart';
import 'package:velomine/core/session.dart';
import 'package:velomine/features/rides/detail/ride_detail_screen.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';

import 'fake_server.dart';

import 'package:velomine/core/l10n.dart';

Widget _detailApp(
  Session session,
  String id, {
  RiderModeLayout layout = RiderModeLayout.full,
}) => ProviderScope(
  overrides: [
    sessionProvider.overrideWith((ref) => session),
    ridePollIntervalProvider.overrideWithValue(
      const Duration(milliseconds: 10),
    ),
  ],
  child: MaterialApp(
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: RideDetailScreen(id: id, layout: layout, onDeleted: () {}),
    ),
  ),
);

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
    server.rideLaps['r1'] = [
      lapJson(1, startS: 0, endS: 2700, distanceM: 21000),
      lapJson(2, startS: 2700, endS: 5400, distanceM: 21300),
    ];
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
    'RideDetailScreen_ShouldShowNumbersRouteAndCharts_WhenRideIsOpened',
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

  testWidgets('RideDetailScreen_ShouldShowZonesAndLoad_WhenProfileHasThem', (
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
    'RideDetailScreen_ShouldShowTwoCards_WhenTheRideMovedBothHeartRateNumbers',
    (tester) async {
      // A ride raised both numbers: one card each, in the rider's language.
      server.rides.first['heartRateMaxNote'] = 'max_measured';
      server.rides.first['heartRateThresholdNote'] = 'threshold_measured';
      server.profiles['rider@example.com'] = {
        'displayName': 'Test Rider',
        'ftpW': null,
        'weightKg': null,
        'birthYear': null,
        'timeZone': 'Europe/Rome',
        'firstDayOfWeek': 'monday',
        'emailNotifications': true,
        'emailAccountNotifications': true,
        'emailTrainingNotifications': false,
        'hasPassword': true,
        'maxHeartRate': 192,
        'maxHeartRateSource': 'measured',
        'maxHeartRateRideId': 'r1',
        'thresholdHeartRate': 165,
        'thresholdHeartRateSource': 'measured',
        'thresholdHeartRateRideId': 'r1',
      };
      await open(tester);

      expect(find.byKey(const Key('heart-rate-note-max')), findsOneWidget);
      expect(
        find.byKey(const Key('heart-rate-note-threshold')),
        findsOneWidget,
      );
      expect(
        find.text('New maximum heart rate: 192 bpm. Your zones now use it.'),
        findsOneWidget,
      );
      expect(
        find.text('New threshold heart rate: 165 bpm. Your zones now use it.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'RideDetailScreen_ShouldHideTheMeasuredCard_WhenTheNumberCameFromAnotherRide',
    (tester) async {
      // The profile carries the ride that set the number: this ride moved the maximum, but a later ride now holds it,
      // so calling this ride's number "measured" here would name a number this ride no longer set.
      server.rides.first['heartRateMaxNote'] = 'max_measured';
      server.rides.first['heartRateThresholdNote'] = 'threshold_measured';
      server.profiles['rider@example.com'] = {
        'displayName': 'Test Rider',
        'ftpW': null,
        'weightKg': null,
        'birthYear': null,
        'timeZone': 'Europe/Rome',
        'firstDayOfWeek': 'monday',
        'emailNotifications': true,
        'emailAccountNotifications': true,
        'emailTrainingNotifications': false,
        'hasPassword': true,
        'maxHeartRate': 195,
        'maxHeartRateSource': 'measured',
        'maxHeartRateRideId': 'r2',
        'thresholdHeartRate': 165,
        'thresholdHeartRateSource': 'measured',
        'thresholdHeartRateRideId': 'r1',
      };
      await open(tester);

      expect(find.byKey(const Key('heart-rate-note-max')), findsNothing);
      expect(
        find.byKey(const Key('heart-rate-note-threshold')),
        findsOneWidget,
      );
    },
  );

  testWidgets('RideDetailScreen_ShouldShowMilesAndFeet_WhenUnitsAreImperial', (
    tester,
  ) async {
    server.accounts['rider@example.com']!.units = 'imperial';
    await open(tester);

    // Power, heart rate and cadence are not converted; distance, speed and climb are.
    for (final text in [
      '26.3 mi',
      '2009 ft',
      '17.4 mph',
      '190 W',
      '148 bpm',
      '87 rpm',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('42.3 km'), findsNothing);
    expect(find.text('28.1 km/h'), findsNothing);
  });

  testWidgets(
    'RideDetailScreen_ShouldShowMomentValuesOnEachChart_WhenAChartIsTouched',
    (tester) async {
      await open(tester);
      expect(find.byKey(const Key('readout-power')), findsOneWidget);
      expect(
        find.textContaining('avg'),
        findsWidgets,
      ); // before touching: the summary

      final chart = find.byKey(const Key('chart-power'));
      await tester.ensureVisible(chart);
      await tester.pumpAndSettle();
      final box = tester.getRect(chart);
      // About a third of the way along the plot area (which starts 46 px in and ends 10 px before the edge).
      await tester.tapAt(
        Offset(box.left + 46 + (box.width - 56) * 0.5, box.center.dy),
      );
      await tester.pumpAndSettle();

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

  testWidgets('RouteMap_ShouldShowHeartRateLegend_WhenTheRideHasHeartRate', (
    tester,
  ) async {
    await open(tester);

    expect(find.byKey(const Key('heart-rate-map-toggle')), findsOneWidget);
    expect(find.byKey(const Key('heart-rate-legend')), findsOneWidget);
    expect(find.text('140–149 bpm'), findsOneWidget);
  });

  testWidgets('RouteMap_ShouldHideHeartRateLegend_WhenTheToggleIsUnchecked', (
    tester,
  ) async {
    await open(tester);
    final toggle = find.byKey(const Key('heart-rate-map-toggle'));
    await tester.scrollUntilVisible(
      toggle,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(toggle);
    await tester.pump();

    expect(find.byKey(const Key('heart-rate-legend')), findsNothing);
    expect(tester.widget<CheckboxListTile>(toggle).value, isFalse);
  });

  testWidgets(
    'RouteMap_ShouldShowNoHeartRateToggle_WhenTheRideHasNoHeartRate',
    (tester) async {
      server.streams['r1'] = streamsJson(heartRate: false);
      await open(tester);

      expect(find.byKey(const Key('route-map')), findsOneWidget);
      expect(find.byKey(const Key('heart-rate-map-toggle')), findsNothing);
      expect(find.byKey(const Key('heart-rate-legend')), findsNothing);
    },
  );

  testWidgets('RideDetailScreen_ShouldShowChartsAndNoMap_WhenRideHasNoGps', (
    tester,
  ) async {
    server.streams['r1'] = streamsJson(position: false);
    await open(tester);

    expect(find.byKey(const Key('route-map')), findsNothing);
    expect(find.byKey(const Key('chart-power')), findsOneWidget);
  });

  testWidgets('RideDetailScreen_ShouldShowDerivedSpeed_WhenFileHasNoSpeed', (
    tester,
  ) async {
    server.streams['r1'] = streamsJson(speed: false);
    await open(tester);

    expect(find.byKey(const Key('chart-speed')), findsOneWidget);
  });

  testWidgets('RideDetailScreen_ShouldExplainAndHideCharts_WhenReadFailed', (
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

  testWidgets('RideDetailScreen_ShouldReportNotFound_WhenRideIsMissing', (
    tester,
  ) async {
    final session = server.session(useCookies: true);
    await tester.pumpWidget(_detailApp(session, 'nobody-has-this-ride'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('not-found')), findsOneWidget);
    expect(find.byKey(const Key('ride-actions')), findsNothing);
  });

  testWidgets('RideDetailScreen_ShouldFillInAfterProcessing_WhenRideIsRead', (
    tester,
  ) async {
    server.rides.add(rideJson('r3', 'processing', fileName: 'big.fit'));
    final session = server.session(useCookies: true);
    await tester.pumpWidget(_detailApp(session, 'r3'));
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

  testWidgets('RideDetailScreen_ShouldGoBack_WhenBackIsTapped', (tester) async {
    await open(tester);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('upload')), findsOneWidget);
    expect(find.byKey(const Key('ride-r1')), findsOneWidget);
  });

  testWidgets(
    'RideDetailScreen_ShouldShowDeleteLastInErrorColour_WhenMenuOpens',
    (tester) async {
      await open(tester);

      await tester.tap(find.byKey(const Key('ride-actions')));
      await tester.pumpAndSettle();

      final deleteY = tester.getTopLeft(find.byKey(const Key('delete'))).dy;
      expect(
        tester.getTopLeft(find.byKey(const Key('edit-ride-text'))).dy,
        lessThan(deleteY),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('edit-ride-type'))).dy,
        lessThan(deleteY),
      );
      final error = Theme.of(tester.element(find.byKey(const Key('delete'))))
          .colorScheme
          .error;
      final label = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('delete')),
          matching: find.text('Delete'),
        ),
      );
      final style = DefaultTextStyle.of(
        tester.element(
          find.descendant(
            of: find.byKey(const Key('delete')),
            matching: find.text('Delete'),
          ),
        ),
      ).style;
      expect(label.style?.color ?? style.color, error);
    },
  );

  testWidgets('RideDetailScreen_ShouldAskAndDelete_WhenTapped', (tester) async {
    await open(tester);

    await tester.tap(find.byKey(const Key('ride-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete')));
    await tester.pumpAndSettle();
    expect(find.text('Delete this ride?'), findsOneWidget);
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(server.requests, isNot(contains('DELETE /api/v1/rides/r1')));
    expect(find.byKey(const Key('ride-actions')), findsOneWidget);

    await tester.tap(find.byKey(const Key('ride-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();

    expect(server.requests, contains('DELETE /api/v1/rides/r1'));
    expect(find.byKey(const Key('ride-r1')), findsNothing);
    expect(find.byKey(const Key('no-rides')), findsOneWidget);
  });

  group('map tiles', () {
    testWidgets(
      'RouteMap_ShouldLayOutTilesAndShowCredit_WhenServerOffersAnAddress',
      (tester) async {
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
        final image = tester.widget<Image>(tiles.first).image as NetworkImage;
        expect(image.headers?['User-Agent'], contains('Velomine'));
      },
    );
  });

  testWidgets(
    'RouteMap_ShouldDrawTheLineWithoutTilesAndSayWhy_WhenTheRideIsVirtual',
    (tester) async {
      server.rides.add(
        rideJson('v1', 'ready', distanceM: 20000, environment: 'virtual'),
      );
      server.streams['v1'] = streamsJson();
      await open(tester, id: 'v1');

      expect(find.byKey(const Key('route-map')), findsOneWidget);
      expect(find.byKey(const Key('map-virtual-caption')), findsOneWidget);
      expect(find.byKey(const Key('map-attribution')), findsNothing);
      final tiles = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('tile-'),
      );
      expect(tiles, findsNothing);
    },
  );

  testWidgets('RouteMap_ShouldOpenFullScreenAndClose_WhenTheMapIsTapped', (
    tester,
  ) async {
    await open(tester);
    final map = find.byKey(const Key('route-map-open'));
    await tester.ensureVisible(map);
    await tester.pumpAndSettle();

    await tester.tap(map);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('full-route-map')), findsOneWidget);

    await tester.tap(find.byKey(const Key('full-map-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('full-route-map')), findsNothing);
  });

  testWidgets('RideDetailScreen_ShouldSaveRpeAndNote_WhenWellbeingIsSetUp', (
    tester,
  ) async {
    server.wellbeingConsent = true;
    await open(tester);

    await tester.scrollUntilVisible(
      find.byKey(const Key('ride-feel-card')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ride-feel-7')));
    await tester.enterText(
      find.byKey(const Key('ride-feel-notes')),
      'Felt strong',
    );
    await tester.tap(find.byKey(const Key('ride-feel-save')));
    await tester.pumpAndSettle();

    expect(server.rideFeels['r1']?['rpe'], 7);
    expect(server.rideFeels['r1']?['notes'], 'Felt strong');
    expect(find.byKey(const Key('ride-feel-saved')), findsOneWidget);
  });

  testWidgets(
    'RideDetailScreen_ShouldPromptForDetails_WhenTheRideHasNoDimensions',
    (tester) async {
      await open(tester);

      // Both edits live in the ride's one actions menu.
      await tester.tap(find.byKey(const Key('ride-actions')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-ride-type')), findsOneWidget);
      expect(find.byKey(const Key('edit-ride-text')), findsOneWidget);
      expect(find.text('Set ride details'), findsWidgets);
    },
  );

  testWidgets(
    'RideDetailScreen_ShouldSaveAndShowTheSurface_WhenTheSheetIsUsed',
    (tester) async {
      await open(tester);

      await tester.tap(find.byKey(const Key('ride-actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit-ride-type')));
      // The sheet opens from the menu's callback, after the menu has closed.
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ride-type-discipline')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gravel').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ride-type-save')));
      await tester.pumpAndSettle();

      expect(server.requests, contains('PUT /api/v1/rides/r1/type'));
      expect(
        find.byKey(const Key('ride-type-discipline-gravel')),
        findsOneWidget,
      );
    },
  );

  testWidgets('RideDetailScreen_ShouldShowLapsAndSelectOne_WhenItHasThem', (
    tester,
  ) async {
    await open(tester);

    expect(find.byKey(const Key('laps')), findsOneWidget);
    expect(find.byKey(const Key('lap-1')), findsOneWidget);
    expect(find.byKey(const Key('lap-2')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('lap-2')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('lap-2')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lap-2-selected')), findsOneWidget);
  });

  testWidgets(
    'RideDetailScreen_ShouldShowTheTitleAndDescription_WhenItHasThem',
    (tester) async {
      server.rides[0]['title'] = 'Dawn patrol';
      server.rides[0]['description'] = 'Cold start, warm finish.';
      await open(tester);

      expect(find.text('Dawn patrol'), findsOneWidget);
      expect(find.text('Cold start, warm finish.'), findsOneWidget);
    },
  );

  testWidgets('RideDetailScreen_ShouldSaveTheText_WhenTheSheetIsUsed', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.byKey(const Key('ride-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-ride-text')));
    // The sheet opens from the menu's callback, after the menu has closed.
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('ride-title-field')),
      'Dawn patrol',
    );
    await tester.enterText(
      find.byKey(const Key('ride-description-field')),
      'Cold start',
    );
    await tester.tap(find.byKey(const Key('ride-text-save')));
    await tester.pumpAndSettle();

    expect(server.requests, contains('PUT /api/v1/rides/r1/details'));
    expect(find.text('Dawn patrol'), findsOneWidget);
    expect(find.text('Cold start'), findsOneWidget);
  });

  testWidgets('RideDetailScreen_ShouldOfferTheRideMenu_WhenTheScreenIsAPhone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.byKey(const Key('ride-r1')));
    await tester.pumpAndSettle();

    // The page header shows on a phone too, so the menu is under it.
    await tester.tap(find.byKey(const Key('ride-actions')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit-ride-text')), findsOneWidget);
    expect(find.byKey(const Key('edit-ride-type')), findsOneWidget);
    expect(find.byKey(const Key('delete')), findsOneWidget);
  });

  testWidgets('RideDetailScreen_ShouldListWhoLooked_WhenACoachOpenedTheRide', (
    tester,
  ) async {
    server.shareViews.add({
      'viewerName': 'Marco',
      'what': 'ride',
      'at': '2026-11-03T14:10:00Z',
      'rideId': 'r1',
    });
    await open(tester);

    await tester.scrollUntilVisible(
      find.byKey(const Key('ride-views')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Seen by Marco'), findsOneWidget);
  });

  testWidgets('RideDetailScreen_ShouldSayNobodyLooked_WhenTheLogIsEmpty', (
    tester,
  ) async {
    await open(tester);

    await tester.scrollUntilVisible(
      find.byKey(const Key('ride-views')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('ride-views-empty')), findsOneWidget);
  });

  testWidgets(
    'RideDetailScreen_ShouldShowPowerRecordChips_WhenTheRideSetRecords',
    (tester) async {
      server.rides[0]['powerRecords'] = [
        powerRecordJson(300, 312, 'all_time'),
        powerRecordJson(1200, 268, '90_days'),
      ];
      await open(tester);

      expect(find.text('Best 5 min ever: 312 W'), findsOneWidget);
      expect(find.text('Best 20 min in 90 days: 268 W'), findsOneWidget);
    },
  );

  testWidgets(
    'RideDetailScreen_ShouldShowTheFtpSuggestionAtTheTop_WhenTheRideSuggestsOne',
    (tester) async {
      server.rides[0]['ftpSuggestionW'] = 266;
      server.rides[0]['ftpSuggestionMethod'] = '20min';
      server.rides[0]['ftpSuggestionId'] = 'suggestion-1';
      server.ftpSuggestions['rider@example.com'] = {
        'id': 'suggestion-1',
        'rideId': 'r1',
        'watts': 266,
        'method': '20min',
        'effortWatts': 280,
        'createdAt': '2026-11-01T09:00:00Z',
      };
      await open(tester);

      expect(find.text('This ride suggests an FTP of 266 W'), findsOneWidget);

      await tester.tap(find.byKey(const Key('ftp-suggestion-use')));
      await tester.pumpAndSettle();

      expect(server.acceptedSuggestions, ['suggestion-1']);
      // The accepted suggestion is gone from the server; the ride is read again and the card with it.
      server.rides[0]['ftpSuggestionW'] = null;
      server.rides[0]['ftpSuggestionMethod'] = null;
      server.rides[0]['ftpSuggestionId'] = null;
      await tester.pumpAndSettle();
    },
  );

  testWidgets('RideDetailScreen_ShouldHaveNoSuggestion_WhenTheRideHasNone', (
    tester,
  ) async {
    await open(tester);

    expect(find.byKey(const Key('ftp-suggestion')), findsNothing);
  });

  testWidgets(
    'RideDetailScreen_ShouldChartTheWPrimeBalanceInKj_WhenTheRideHasAFit',
    (tester) async {
      server.rides[0]['minWPrimeBalanceJ'] = 8137;
      server.rides[0]['wPrimeJ'] = 20037;
      server.streams['r1'] = streamsJson(
        wPrimeBalance: [for (var i = 0; i < 60; i++) 20000 - i * 100],
      );
      await open(tester);

      await tester.scrollUntilVisible(
        find.byKey(const Key('chart-wprime')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('chart-wprime')), findsOneWidget);
      expect(find.text('W′ balance'), findsOneWidget);
      expect(find.text('Lowest W′ balance 8.1 kJ of 20.0 kJ'), findsOneWidget);
    },
  );

  testWidgets('RideDetailScreen_ShouldHideTheWPrimeBalance_WhenThereIsNoFit', (
    tester,
  ) async {
    await open(tester);

    expect(find.byKey(const Key('chart-wprime')), findsNothing);
    expect(find.byKey(const Key('wprime-lowest')), findsNothing);
  });
}
