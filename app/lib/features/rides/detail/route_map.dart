import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/theme.dart';
import 'geo.dart';
import 'lap_range.dart';
import 'ride_series.dart';

/// The route on a map. With a tile address (an admin turns it on) the map has a background of map tiles; without one
/// the route is drawn alone and nothing is requested from any outside server. A marker follows the selected moment.
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
                              width: tileSize,
                              height: tileSize,
                              child: Image.network(
                                tile.url,
                                key: Key('tile-${tile.url}'),
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
                            painter: _RoutePainter(
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
                      ],
                    ),
                  );
                },
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
}

Series? _heartRateOf(RideSeries data) {
  for (final series in data.series) {
    if (series.id == 'heartrate') return series;
  }
  return null;
}

/// Low heart rate in the route colour, high heart rate in the chart's heart-rate colour.
Color heartRateColor(
  double bpm,
  double min,
  double max,
  VelomineColors colors,
) {
  final high = colors.series['heartrate'] ?? colors.finish;
  final t = max > min ? ((bpm - min) / (max - min)).clamp(0.0, 1.0) : 1.0;
  return Color.lerp(colors.route, high, t)!;
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

class _RoutePainter extends CustomPainter {
  _RoutePainter({
    required this.view,
    required this.data,
    required this.selected,
    required this.selectedLap,
    required this.colors,
    required this.heartRate,
    required this.showHeartRate,
  }) : super(repaint: Listenable.merge([selected, selectedLap]));

  final VelomineColors colors;

  final MapView view;
  final RideSeries data;
  final ValueNotifier<int?> selected;
  final ValueNotifier<LapRange?> selectedLap;
  final Series? heartRate;
  final bool showHeartRate;

  @override
  void paint(Canvas canvas, Size size) {
    final points = [for (final point in data.route) view.project(point)];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    // A pale edge under the line keeps it readable over any tile colour.
    canvas.drawPath(
      path,
      Paint()
        ..color = colors.halo.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    if (showHeartRate && heartRate != null) {
      final values = heartRate!.values;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      for (var i = 1; i < points.length; i++) {
        final value = values[data.routeIndex[i]];
        paint.color = value == null
            ? colors.route
            : heartRateColor(value, heartRate!.min, heartRate!.max, colors);
        canvas.drawLine(points[i - 1], points[i], paint);
      }
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..color = colors.route
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    _dot(canvas, points.first, colors.route, 7); // start
    _dot(canvas, points.last, colors.finish, 7); // finish

    // The selected lap, drawn over the route.
    final lap = selectedLap.value;
    if (lap != null) {
      final highlight = Path();
      var open = false;
      for (var i = 0; i < data.route.length; i++) {
        final t = data.time[data.routeIndex[i]];
        if (t < lap.startS || t > lap.endS) {
          open = false;
          continue;
        }
        final p = points[i];
        if (!open) {
          highlight.moveTo(p.dx, p.dy);
          open = true;
        } else {
          highlight.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        highlight,
        Paint()
          ..color = colors.finish
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    final index = selected.value;
    if (index != null) {
      final at = data.routePointAt(index);
      if (at != null) {
        final p = view.project(at);
        canvas.drawCircle(p, 11, Paint()..color = colors.halo);
        canvas.drawCircle(p, 8, Paint()..color = colors.finish);
        canvas.drawCircle(p, 3, Paint()..color = colors.halo);
      }
    }
  }

  void _dot(Canvas canvas, Offset at, Color color, double radius) {
    canvas.drawCircle(at, radius + 2, Paint()..color = colors.halo);
    canvas.drawCircle(at, radius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.view != view ||
      old.data != data ||
      old.colors != colors ||
      old.selectedLap != selectedLap ||
      old.heartRate != heartRate ||
      old.showHeartRate != showHeartRate;
}
