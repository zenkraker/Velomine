import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
import '../../core/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import '../rides/detail/lap_range.dart';
import '../rides/detail/ride_series.dart';
import '../rides/detail/route_map.dart';
import '../rides/detail/series_chart.dart';

/// The name of a route's surface in the language on screen; an unknown surface is shown as sent.
String routeSurfaceName(AppLocalizations l10n, String surface) =>
    switch (surface) {
      'road' => l10n.routeSurfaceRoad,
      'gravel' => l10n.routeSurfaceGravel,
      'mountain' => l10n.routeSurfaceMountain,
      'mixed' => l10n.routeSurfaceMixed,
      _ => surface,
    };

String routeSortName(AppLocalizations l10n, String sort) => switch (sort) {
  'shortest' => l10n.routesSortShortest,
  'longest' => l10n.routesSortLongest,
  _ => l10n.routesSortNewest,
};

/// A route's line in the shape the ride map draws: one sample a second is enough, only the shape matters.
RideSeries? routeSeries(
  List<double> latitude,
  List<double> longitude,
  List<double>? elevation,
) {
  if (latitude.length < 2 || longitude.length != latitude.length) return null;
  return RideSeries.from(
    RideStreamsResponse(
      time: [for (var i = 0; i < latitude.length; i++) i.toDouble()],
      latitude: latitude,
      longitude: longitude,
      altitude: elevation,
    ),
  );
}

/// The route on the project's own map, with an elevation profile under it when the line has one.
class RoutePreview extends StatefulWidget {
  const RoutePreview({
    super.key,
    required this.latitude,
    required this.longitude,
    this.elevation,
    this.tileUrl,
    this.attribution,
    this.showElevation = true,
  });

  final List<double> latitude;
  final List<double> longitude;
  final List<double>? elevation;
  final String? tileUrl;
  final String? attribution;
  final bool showElevation;

  @override
  State<RoutePreview> createState() => _RoutePreviewState();
}

class _RoutePreviewState extends State<RoutePreview> {
  final _selected = ValueNotifier<int?>(null);
  final _selectedLap = ValueNotifier<LapRange?>(null);

  @override
  void dispose() {
    _selected.dispose();
    _selectedLap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final series = routeSeries(
      widget.latitude,
      widget.longitude,
      widget.elevation,
    );
    if (series == null) return const SizedBox.shrink();
    Series? elevation;
    for (final s in series.series) {
      if (s.id == 'elevation') {
        elevation = s;
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        RouteMap(
          data: series,
          selected: _selected,
          selectedLap: _selectedLap,
          tileUrl: widget.tileUrl,
          attribution: widget.attribution,
          elevationGainM: null,
        ),
        if (widget.showElevation && elevation != null)
          SeriesChart(
            series: elevation,
            time: series.time,
            selected: _selected,
            selectedLap: _selectedLap,
            color: Theme.of(context).colorScheme.primary,
          ),
      ],
    );
  }
}

/// "48.2 km · 620 m climbing", the line every route list shows.
String routeLineOf(double distanceM, double? climbingM) =>
    '${km(distanceM)} · ${climbingM == null ? '–' : '${climbingM.round()} m ↑'}';
