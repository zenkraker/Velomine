import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/geo.dart';
import 'package:velomine/core/theme.dart';
import 'package:velomine/core/units.dart';
import 'package:velomine/core/widgets/app_map.dart';
import 'package:velomine/features/rides/detail/ride_series.dart';
import 'package:velomine/features/rides/detail/route_lines.dart';
import 'package:velomine_api/api.dart';

/// A route going north, [n] samples long, with a rising heart rate.
RideSeries _ride(int n) => RideSeries.from(
  RideStreamsResponse(
    time: [for (var i = 0; i < n; i++) i.toDouble()],
    latitude: [for (var i = 0; i < n; i++) 46 + i * 0.001],
    longitude: List.filled(n, 11.0),
    altitude: const [],
    speed: const [],
    distance: const [],
    heartRate: [for (var i = 0; i < n; i++) 100 + i],
    power: const [],
    cadence: const [],
    temperature: const [],
  ),
  Units.metric,
);

Widget _host(Widget map) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 400, height: 300, child: map)),
);

void main() {
  group('route lines', () {
    test(
      'RouteLines_ShouldDrawOneLineOverTheGlowAndHalo_WhenNoHeartRateIsShown',
      () {
        final lines = routeLines(
          _ride(30),
          VelomineColors.day,
          heartRate: null,
          showHeartRate: false,
        );

        expect(lines, hasLength(3));
        expect(lines.last.color, VelomineColors.day.route);
        expect(lines.last.points, hasLength(30));
      },
    );

    test(
      'RouteLines_ShouldCutTheRouteInFewColourRuns_WhenHeartRateIsShown',
      () {
        final ride = _ride(60);
        final lines = routeLines(
          ride,
          VelomineColors.day,
          heartRate: ride.series.firstWhere((s) => s.id == 'heartrate'),
          showHeartRate: true,
        );

        final coloured = lines.skip(2).toList();
        expect(coloured.length, greaterThan(1));
        expect(coloured.length, lessThanOrEqualTo(17));
        // Runs join end to end, so the line has no gap between two colours.
        for (var i = 1; i < coloured.length; i++) {
          expect(coloured[i].points.first, coloured[i - 1].points.last);
        }
        expect(
          coloured.fold<int>(0, (sum, l) => sum + l.points.length - 1),
          59,
        );
      },
    );

    test('SelectedDot_ShouldBeEmpty_WhenNothingIsSelected', () {
      expect(selectedDot(_ride(5), VelomineColors.day, null), isEmpty);
      expect(selectedDot(_ride(5), VelomineColors.day, 2), hasLength(1));
    });
  });

  group('AppMap', () {
    testWidgets('AppMap_ShouldDrawNoTiles_WhenThereIsNoTileAddress', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const AppMap(attribution: 'Maps', center: (lat: 46, lon: 11))),
      );

      expect(find.byType(TileLayer), findsNothing);
      expect(find.byKey(const Key('map-attribution')), findsNothing);
    });

    testWidgets('AppMap_ShouldShowTheCredit_WhenTilesAreDrawn', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppMap(
            tileUrl: 'https://t.example/{z}/{x}/{y}.png',
            attribution: 'Maps',
            center: (lat: 46, lon: 11),
          ),
        ),
      );

      expect(find.byType(TileLayer), findsOneWidget);
      expect(find.text('Maps'), findsOneWidget);
    });

    testWidgets('AppMap_ShouldFitTheRoute_WhenGivenPointsToFit', (
      tester,
    ) async {
      final ride = _ride(30);
      await tester.pumpWidget(_host(AppMap(fit: ride.route)));
      await tester.pump();

      final camera = MapCamera.of(tester.element(find.byType(PolylineLayer)));
      expect(camera.center.latitude, closeTo(46.0145, 0.002));
      expect(camera.zoom, inInclusiveRange(AppMap.minZoom, 17));
    });

    testWidgets('AppMap_ShouldMoveTheMap_WhenTheCentreChanges', (tester) async {
      Widget map(double lat) => _host(
        AppMap(center: (lat: lat, lon: 11), zoom: 12, interactive: true),
      );
      await tester.pumpWidget(map(46));
      await tester.pump();

      await tester.pumpWidget(map(47));
      await tester.pump();
      await tester.pump();

      final camera = MapCamera.of(tester.element(find.byType(PolylineLayer)));
      expect(camera.center.latitude, closeTo(47, 1e-6));
    });

    testWidgets('AppMap_ShouldTellWhereItWasDragged_WhenInteractive', (
      tester,
    ) async {
      LatLon? moved;
      await tester.pumpWidget(
        _host(
          AppMap(
            center: (lat: 46, lon: 11),
            zoom: 12,
            interactive: true,
            onMoved: (center, zoom) => moved = center,
          ),
        ),
      );
      await tester.pump();

      await tester.drag(find.byType(AppMap), const Offset(100, 0));
      await tester.pump();

      expect(moved, isNotNull);
      expect(moved!.lon, lessThan(11));
    });

    testWidgets('AppMap_ShouldStayStill_WhenNotInteractive', (tester) async {
      var moves = 0;
      await tester.pumpWidget(
        _host(
          AppMap(
            center: (lat: 46, lon: 11),
            zoom: 12,
            onMoved: (center, zoom) => moves++,
          ),
        ),
      );
      await tester.pump();

      await tester.drag(
        find.byType(AppMap),
        const Offset(100, 0),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(moves, 0);
    });
  });
}
