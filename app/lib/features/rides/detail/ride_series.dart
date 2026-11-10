import 'dart:math' as math;

import 'package:velomine_api/api.dart';

import 'geo.dart';

/// One signal of a ride, ready to draw: a value per sample, null where the file had none.
class Series {
  const Series({
    required this.id,
    required this.name,
    required this.unit,
    required this.values,
    this.decimals = 0,
  });

  final String id;
  final String name;
  final String unit;
  final List<double?> values;
  final int decimals;

  Iterable<double> get present => values.whereType<double>();

  double get min => present.reduce(math.min);

  double get max => present.reduce(math.max);

  double get average => present.reduce((a, b) => a + b) / present.length;

  String format(double? v) =>
      v == null ? '–' : '${v.toStringAsFixed(decimals)} $unit';
}

/// A ride's samples in the shapes the screen draws: a route, and one [Series] per signal the ride has.
class RideSeries {
  RideSeries._(
    this.time,
    this.distance,
    this.route,
    this.routeIndex,
    this.routeBreaks,
    this.startHidden,
    this.endHidden,
    this.series,
  );

  factory RideSeries.from(RideStreamsResponse s) {
    final time = s.time;
    List<double?>? present(List<double?>? v) =>
        v == null || v.isEmpty || v.every((e) => e == null) ? null : v;

    final lat = present(s.latitude);
    final lon = present(s.longitude);
    final route = <LatLon>[];
    final routeIndex = <int>[]; // which sample each route point is
    final routeBreaks =
        <int>{}; // route points that start a new line, after hidden ones
    var gap = false;
    if (lat != null && lon != null) {
      for (var i = 0; i < time.length; i++) {
        final la = lat[i], lo = lon[i];
        if (la != null && lo != null) {
          if (gap && route.isNotEmpty) routeBreaks.add(route.length);
          route.add((lat: la, lon: lo));
          routeIndex.add(i);
          gap = false;
        } else {
          gap = true;
        }
      }
    }
    // A hidden first or last sample means the start or finish dot would sit at the edge of the hidden area.
    final startHidden =
        lat == null ||
        lon == null ||
        time.isEmpty ||
        lat[0] == null ||
        lon[0] == null;
    final endHidden =
        lat == null ||
        lon == null ||
        time.isEmpty ||
        lat[time.length - 1] == null ||
        lon[time.length - 1] == null;

    final speed =
        present(s.speed)?.map((v) => v == null ? null : v * 3.6).toList() ??
        present(deriveSpeedKmh(time, lat, lon));
    final altitude = present(s.altitude);
    final power = present(s.power?.map((v) => v?.toDouble()).toList());
    final heartRate = present(s.heartRate?.map((v) => v?.toDouble()).toList());
    final cadence = present(s.cadence?.map((v) => v?.toDouble()).toList());

    return RideSeries._(
      time,
      present(s.distance),
      route,
      routeIndex,
      routeBreaks,
      startHidden,
      endHidden,
      [
        if (altitude != null)
          Series(
            id: 'elevation',
            name: 'Elevation',
            unit: 'm',
            values: altitude,
          ),
        if (speed != null)
          Series(
            id: 'speed',
            name: 'Speed',
            unit: 'km/h',
            values: speed,
            decimals: 1,
          ),
        if (heartRate != null)
          Series(
            id: 'heartrate',
            name: 'Heart rate',
            unit: 'bpm',
            values: heartRate,
          ),
        if (power != null)
          Series(id: 'power', name: 'Power', unit: 'W', values: power),
        if (cadence != null)
          Series(id: 'cadence', name: 'Cadence', unit: 'rpm', values: cadence),
      ],
    );
  }

  final List<double> time;
  final List<double?>? distance;
  final List<LatLon> route;
  final List<int> routeIndex;

  /// Route points that begin a new line because the samples before them were hidden.
  final Set<int> routeBreaks;
  final bool startHidden;
  final bool endHidden;
  final List<Series> series;

  bool get hasRoute => route.length >= 2;

  /// The position on the route nearest to sample [index], for the marker on the map.
  LatLon? routePointAt(int index) {
    if (route.isEmpty) return null;
    var best = 0;
    for (var i = 0; i < routeIndex.length; i++) {
      if ((routeIndex[i] - index).abs() < (routeIndex[best] - index).abs()) {
        best = i;
      }
    }
    return route[best];
  }
}

/// Speed in km/h worked out from positions, for files that carry none (GPX without speed): the distance between
/// neighbouring samples over the time between them, smoothed over five samples so GPS jitter does not spike the chart.
List<double?>? deriveSpeedKmh(
  List<double> time,
  List<double?>? lat,
  List<double?>? lon,
) {
  if (lat == null || lon == null || time.length < 2) return null;
  final raw = List<double?>.filled(time.length, null);
  for (var i = 1; i < time.length; i++) {
    final dt = time[i] - time[i - 1];
    final a = (lat: lat[i - 1], lon: lon[i - 1]),
        b = (lat: lat[i], lon: lon[i]);
    if (dt > 0 &&
        a.lat != null &&
        a.lon != null &&
        b.lat != null &&
        b.lon != null) {
      raw[i] = haversineMetres(a.lat!, a.lon!, b.lat!, b.lon!) / dt * 3.6;
    }
  }
  raw[0] = raw[1];
  return [
    for (var i = 0; i < raw.length; i++)
      () {
        final window = raw
            .sublist(math.max(0, i - 2), math.min(raw.length, i + 3))
            .whereType<double>();
        return window.isEmpty
            ? null
            : window.reduce((x, y) => x + y) / window.length;
      }(),
  ];
}

double haversineMetres(double lat1, double lon1, double lat2, double lon2) {
  const radius = 6371000.0;
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(lat2 - lat1), dLon = rad(lon2 - lon1);
  final h =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return 2 * radius * math.asin(math.sqrt(h));
}
