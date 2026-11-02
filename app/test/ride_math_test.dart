import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/features/rides/detail/geo.dart';
import 'package:velomine/features/rides/detail/ride_series.dart';
import 'package:velomine/features/rides/detail/scale.dart';
import 'package:velomine_api/api.dart';

void main() {
  group('map projection', () {
    test(
      'London is in tile 10/511/340, the address OpenStreetMap documents',
      () {
        expect((worldX(-0.12, 10) / tileSize).floor(), 511);
        expect((worldY(51.5, 10) / tileSize).floor(), 340);
      },
    );

    test('the world is one tile at zoom 0 and the equator is its middle', () {
      expect(worldX(-180, 0), 0);
      expect(worldX(180, 0), closeTo(256, 1e-9));
      expect(worldY(0, 0), closeTo(128, 1e-9));
    });

    test('a short route gets a more detailed zoom than a long one, and always fits', () {
      const size = Size(800, 450);
      final short = <LatLon>[
        (lat: 46.07, lon: 11.12),
        (lat: 46.08, lon: 11.14),
      ];
      final long = <LatLon>[(lat: 46.0, lon: 11.0), (lat: 47.0, lon: 12.5)];

      final shortView = MapView.fit(short, size);
      final longView = MapView.fit(long, size);

      expect(shortView.zoom, greaterThan(longView.zoom));
      for (final view in [shortView, longView]) {
        final pts = (view == shortView ? short : long).map(view.project);
        for (final o in pts) {
          expect(o.dx, inInclusiveRange(0, size.width));
          expect(o.dy, inInclusiveRange(0, size.height));
        }
      }
    });

    test('tiles cover the whole view, are addressed from the template and sit where the route is drawn', () {
      const size = Size(600, 400);
      final view = MapView.fit(const [
        (lat: 46.07, lon: 11.12),
        (lat: 46.08, lon: 11.14),
      ], size);

      final tiles = view.tiles('https://t.example/{z}/{x}/{y}.png');

      expect(tiles.first.url, startsWith('https://t.example/${view.zoom}/'));
      expect(tiles.map((t) => t.left).reduce(math.min), lessThanOrEqualTo(0));
      expect(
        tiles.map((t) => t.left + tileSize).reduce(math.max),
        greaterThanOrEqualTo(size.width),
      );
      expect(tiles.map((t) => t.top).reduce(math.min), lessThanOrEqualTo(0));
      expect(
        tiles.map((t) => t.top + tileSize).reduce(math.max),
        greaterThanOrEqualTo(size.height),
      );
      // The tile that holds the route's start is placed so its corner plus the start's offset inside it lands on the projection.
      final start = view.project((lat: 46.07, lon: 11.12));
      final x = (worldX(11.12, view.zoom) / tileSize).floor(),
          y = (worldY(46.07, view.zoom) / tileSize).floor();
      final tile = tiles.firstWhere((t) => t.url.endsWith('/$x/$y.png'));
      expect(
        tile.left + (worldX(11.12, view.zoom) - x * tileSize),
        closeTo(start.dx, 1e-6),
      );
      expect(
        tile.top + (worldY(46.07, view.zoom) - y * tileSize),
        closeTo(start.dy, 1e-6),
      );
    });

    test('a single point still gets a map', () {
      expect(
        MapView.fit(const [(lat: 46.0, lon: 11.0)], const Size(400, 300)).zoom,
        17,
      );
    });
  });

  group('chart scales', () {
    test('use round steps', () {
      final s = niceScale(0, 97);
      expect((s.min, s.max, s.step), (0, 100, 25));
      expect(s.ticks, [0, 25, 50, 75, 100]);
      expect(niceScale(131, 162).ticks, [130, 140, 150, 160, 170]);
      expect(niceScale(0.2, 0.9).step, 0.2);
    });

    test('draw a flat line in the middle', () {
      final s = niceScale(200, 200);
      expect(s.min, lessThan(200));
      expect(s.max, greaterThan(200));
    });

    test('time marks are round and few', () {
      expect(timeTicks(720), [0, 120, 240, 360, 480, 600, 720]);
      expect(timeTicks(7800).length, lessThanOrEqualTo(7));
      expect(timeLabel(330), '5:30');
      expect(timeLabel(4500, hours: true), '1:15');
      expect(
        timeLabel(3600, hours: true),
        '1:00',
      ); // on a long ride every mark is hours and minutes
      expect(timeLabel(900, hours: true), '0:15');
      expect(clock(330), '5:30');
      expect(clock(4530), '1:15:30');
    });

    test('find the nearest sample', () {
      const time = [0.0, 10.0, 20.0, 30.0];
      expect(nearestIndex(time, -5), 0);
      expect(nearestIndex(time, 14), 1);
      expect(nearestIndex(time, 16), 2);
      expect(nearestIndex(time, 99), 3);
    });
  });

  group('ride series', () {
    RideStreamsResponse streams({
      List<double?>? speed,
      List<int?>? power,
      List<int?>? cadence,
    }) {
      final n = 60;
      return RideStreamsResponse(
        time: [for (var i = 0; i < n; i++) i.toDouble()],
        latitude: [for (var i = 0; i < n; i++) 46 + i * 10 / 111195],
        longitude: List.filled(n, 11.0),
        altitude: [for (var i = 0; i < n; i++) 300 + i * 0.5],
        speed: speed ?? const [],
        distance: const [],
        heartRate: List<int?>.filled(n, 150),
        power: power ?? List<int?>.filled(n, 200),
        cadence: cadence ?? <int?>[],
        temperature: const [],
      );
    }

    test('only the signals the ride has become charts, in a fixed order', () {
      final series = RideSeries.from(streams());

      expect(series.series.map((s) => s.id), [
        'elevation',
        'speed',
        'power',
        'heartrate',
      ]); // speed is worked out from positions
    });

    test('speed from the file is converted to km/h, and used instead of working it out', () {
      final series = RideSeries.from(streams(speed: List.filled(60, 8.0)));

      expect(
        series.series.firstWhere((s) => s.id == 'speed').values.first,
        closeTo(28.8, 1e-9),
      );
    });

    test('speed worked out from positions matches the pace (10 m per second is 36 km/h)', () {
      final speed = RideSeries.from(streams()).series
          .firstWhere((s) => s.id == 'speed');

      expect(speed.average, closeTo(36, 0.2));
      expect(speed.max, closeTo(36, 0.5));
    });

    test('a signal that is all gaps is not a chart', () {
      final series = RideSeries.from(streams(cadence: List.filled(60, null)));

      expect(series.series.any((s) => s.id == 'cadence'), isFalse);
    });

    test('the route keeps which sample each point belongs to, and finds the nearest one', () {
      final lat = <double?>[46.0, null, 46.002, 46.003];
      final series = RideSeries.from(
        RideStreamsResponse(
          time: const [0, 1, 2, 3],
          latitude: lat,
          longitude: const [11.0, null, 11.0, 11.0],
          altitude: const [],
          speed: const [],
          distance: const [],
          heartRate: const [],
          power: const [],
          cadence: const [],
          temperature: const [],
        ),
      );

      expect(series.route.length, 3);
      expect(series.routeIndex, [0, 2, 3]);
      expect(
        series.routePointAt(1)!.lat,
        46.0,
      ); // sample 1 has no position; sample 0 is the nearest
    });

    test('statistics skip gaps', () {
      final s = Series(
        id: 'x',
        name: 'X',
        unit: 'u',
        values: const [10, null, 30],
        decimals: 1,
      );

      expect((s.min, s.max, s.average), (10, 30, 20));
      expect(s.format(null), '–');
      expect(s.format(12.345), '12.3 u');
    });
  });
}
