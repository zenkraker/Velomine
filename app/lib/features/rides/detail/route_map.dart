import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/map_defaults.dart';
import '../../../core/theme.dart';
import 'full_route_map.dart';
import 'geo.dart';
import 'lap_range.dart';
import 'ride_series.dart';
import 'route_painter.dart';

/// The route on a map. With a tile address the map has a background of map tiles; without one the route is drawn
/// alone and nothing is requested from any outside server. A marker follows the selected moment.
/// When the ride has heart-rate samples, the route can be coloured by them.
class RouteMap extends StatefulWidget {
  const RouteMap({
    super.key,
    required this.data,
    required this.selected,
    required this.selectedLap,
    this.tileUrl,
    this.attribution,
  });

  final RideSeries data;
  final ValueNotifier<int?> selected;
  final ValueNotifier<LapRange?> selectedLap;
  final String? tileUrl;
  final String? attribution;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  bool _showHeartRate = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final colors = VelomineColors.of(context);
    final heartRate = _heartRateOf(widget.data);
    final showHeartRate = heartRate != null && _showHeartRate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (heartRate != null)
          CheckboxListTile(
            key: const Key('heart-rate-map-toggle'),
            value: _showHeartRate,
            onChanged: (value) =>
                setState(() => _showHeartRate = value ?? true),
            title: Text(l10n.heartRateOnMap),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        Semantics(
          label: showHeartRate
              ? l10n.mapHeartRateHint(
                  heartRate.min.round(),
                  heartRate.max.round(),
                )
              : l10n.mapOfRoute,
          child: GestureDetector(
            key: const Key('route-map-open'),
            onTap: () => _openFullMap(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final size = Size(box.maxWidth, box.maxHeight);
                    final view = MapView.fit(widget.data.route, size);
                    return ColoredBox(
                      color: scheme.surfaceContainerHighest,
                      child: Stack(
                        children: [
                          if (widget.tileUrl != null)
                            for (final tile in view.tiles(widget.tileUrl!))
                              Positioned(
                                left: tile.left,
                                top: tile.top,
                                width: view.tilePixels,
                                height: view.tilePixels,
                                child: Image.network(
                                  tile.url,
                                  key: Key('tile-${tile.url}'),
                                  headers: mapTileHeaders,
                                  fit: BoxFit.fill,
                                  webHtmlElementStrategy:
                                      WebHtmlElementStrategy.fallback,
                                  errorBuilder: (_, _, _) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                          Positioned.fill(
                            child: CustomPaint(
                              key: const Key('route-map'),
                              painter: RoutePainter(
                                view: view,
                                data: widget.data,
                                selected: widget.selected,
                                selectedLap: widget.selectedLap,
                                colors: colors,
                                heartRate: heartRate,
                                showHeartRate: showHeartRate,
                              ),
                            ),
                          ),
                          if (widget.tileUrl != null &&
                              widget.attribution != null &&
                              widget.attribution!.isNotEmpty)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                key: const Key('map-attribution'),
                                color: Colors.white.withValues(alpha: 0.75),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                child: Text(
                                  widget.attribution!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              key: const Key('open-full-map'),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.open_in_full,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (showHeartRate)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _HeartRateLegend(
              min: heartRate.min.round(),
              max: heartRate.max.round(),
              colors: colors,
            ),
          ),
      ],
    );
  }

  void _openFullMap(BuildContext context) {
    // The root navigator puts the map over the shell's bars too, as Strava does.
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => FullRouteMapScreen(
          data: widget.data,
          selected: widget.selected,
          selectedLap: widget.selectedLap,
          tileUrl: widget.tileUrl,
          attribution: widget.attribution,
        ),
      ),
    );
  }
}

Series? _heartRateOf(RideSeries data) {
  for (final series in data.series) {
    if (series.id == 'heartrate') return series;
  }
  return null;
}

class _HeartRateLegend extends StatelessWidget {
  const _HeartRateLegend({
    required this.min,
    required this.max,
    required this.colors,
  });

  final int min;
  final int max;
  final VelomineColors colors;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(context.l10n.seriesHeartRate, style: text.labelSmall),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            key: const Key('heart-rate-legend'),
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                colors: [
                  colors.route,
                  colors.series['heartrate'] ?? colors.finish,
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$min–$max bpm', style: text.labelSmall),
      ],
    );
  }
}
