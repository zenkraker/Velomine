import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/theme.dart';
import 'package:velomine/features/rides/detail/ride_series.dart';
import 'package:velomine/features/rides/detail/route_lines.dart';
import 'package:velomine/features/rides/detail/scale.dart';
import 'package:velomine_api/api.dart';
import 'package:velomine/core/units.dart';

void main() {
  group('chart scales', () {
    test('NiceScale_ShouldUseRoundStepsAndTicks_WhenScalingValues', () {
      final s = niceScale(0, 97);
      expect((s.min, s.max, s.step), (0, 100, 25));
      expect(s.ticks, [0, 25, 50, 75, 100]);
      expect(niceScale(131, 162).ticks, [130, 140, 150, 160, 170]);
      expect(niceScale(0.2, 0.9).step, 0.2);
    });

    test('NiceScale_ShouldCenterAFlatLine_WhenAllValuesAreEqual', () {
      final s = niceScale(200, 200);
      expect(s.min, lessThan(200));
      expect(s.max, greaterThan(200));
    });

    test('TimeAxis_ShouldUseRoundAndFewMarks_WhenLabellingRideTime', () {
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

    test('NearestIndex_ShouldFindTheClosestSample_WhenBetweenSamples', () {
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
      List<int>? wPrimeBalance,
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
        wPrimeBalanceJ: Optional.present(wPrimeBalance),
      );
    }

    test('RideSeries_ShouldChartOnlyPresentSignals_WhenBuiltFromStreams', () {
      final series = RideSeries.from(streams(), Units.metric);

      expect(series.series.map((s) => s.id), [
        'elevation',
        'speed',
        'heartrate',
        'power',
      ]); // speed is worked out from positions
    });

    test('RideSeries_ShouldUseFileSpeedInKmh_WhenSpeedIsPresent', () {
      final series = RideSeries.from(
        streams(speed: List.filled(60, 8.0)),
        Units.metric,
      );

      expect(
        series.series.firstWhere((s) => s.id == 'speed').values.first,
        closeTo(28.8, 1e-9),
      );
    });

    test('RideSeries_ShouldDeriveSpeedFromPositionsAtTenMetresPerSecond_WhenNoSpeed', () {
      final speed = RideSeries.from(
        streams(),
        Units.metric,
      ).series.firstWhere((s) => s.id == 'speed');

      expect(speed.average, closeTo(36, 0.2));
      expect(speed.max, closeTo(36, 0.5));
    });

    test('RideSeries_ShouldReadTheWPrimeBalanceInKj_WhenTheStreamsHaveOne', () {
      final balance = RideSeries.from(
        streams(wPrimeBalance: [for (var i = 0; i < 60; i++) 20000 - i * 100]),
        Units.metric,
      ).series.firstWhere((s) => s.id == 'wprime');

      expect(balance.values.first, closeTo(20, 1e-9));
      expect(balance.values.last, closeTo(14.1, 1e-9));
      expect(balance.format(balance.values.first), '20.0 kJ');
      expect(balance.baseline, isTrue);
    });

    test('RideSeries_ShouldOmitAllGapSignals_WhenEveryValueIsNull', () {
      final series = RideSeries.from(
        streams(cadence: List.filled(60, null)),
        Units.metric,
      );

      expect(series.series.any((s) => s.id == 'cadence'), isFalse);
    });

    test('RideSeries_ShouldMapRoutePointsToSamplesAndFindNearest_WhenPositionsHaveGaps', () {
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
        Units.metric,
      );

      expect(series.route.length, 3);
      expect(series.routeIndex, [0, 2, 3]);
      expect(
        series.routePointAt(1)!.lat,
        46.0,
      ); // sample 1 has no position; sample 0 is the nearest
    });

    test(
      'RideSeries_ShouldOmitSpeed_WhenNoTwoNeighbouringSamplesHaveAPosition',
      () {
        final series = RideSeries.from(
          RideStreamsResponse(
            time: const [0, 1, 2, 3],
            latitude: const [46.0, null, null, 46.001],
            longitude: const [11.0, null, null, 11.001],
            altitude: const [],
            speed: const [],
            distance: const [],
            heartRate: const [],
            power: const [],
            cadence: const [],
            temperature: const [],
          ),
          Units.metric,
        );

        expect(series.series.any((s) => s.id == 'speed'), isFalse);
      },
    );

    test('Series_ShouldSkipGapsInStatistics_WhenValuesContainNulls', () {
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

  group('route gaps', () {
    test(
      'RideSeries_ShouldBreakTheLine_WhenHiddenSamplesSitBetweenVisibleOnes',
      () {
        final series = RideSeries.from(
          RideStreamsResponse(
            time: const [0, 1, 2, 3, 4],
            latitude: const [46.0, 46.00001, null, null, 46.00005],
            longitude: const [11.0, 11.0, null, null, 11.0],
          ),
          Units.metric,
        );

        expect(series.route, hasLength(3));
        expect(series.routeBreaks, {2});
        expect(series.startHidden, isFalse);
        expect(series.endHidden, isFalse);
      },
    );

    test(
      'RideSeries_ShouldHideTheStartDot_WhenTheFirstSampleHasNoPosition',
      () {
        final series = RideSeries.from(
          RideStreamsResponse(
            time: const [0, 1, 2],
            latitude: const [null, 46.0, 46.00001],
            longitude: const [null, 11.0, 11.0],
          ),
          Units.metric,
        );

        expect(series.route, hasLength(2));
        expect(series.routeBreaks, isEmpty);
        expect(series.startHidden, isTrue);
        expect(series.endHidden, isFalse);
      },
    );
  });

  group('heart rate colour', () {
    test('HeartRateColor_ShouldUseTheRouteColour_WhenTheRateIsAtItsLowest', () {
      expect(
        heartRateColor(90, 90, 180, VelomineColors.day),
        VelomineColors.day.route,
      );
    });

    test(
      'HeartRateColor_ShouldUseTheHeartRateColour_WhenTheRateIsAtItsHighest',
      () {
        expect(
          heartRateColor(180, 90, 180, VelomineColors.day),
          VelomineColors.day.series['heartrate'],
        );
      },
    );
  });
}
