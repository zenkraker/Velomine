import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import 'geo.dart';
import 'ride_series.dart';

/// The route on a map. With a tile address (an admin turns it on) the map has a background of map tiles; without one
/// the route is drawn alone and nothing is requested from any outside server. A marker follows the selected moment.
class RouteMap extends StatelessWidget {
  const RouteMap({
    super.key,
    required this.data,
    required this.selected,
    this.tileUrl,
    this.attribution,
  });

  final RideSeries data;
  final ValueNotifier<int?> selected;
  final String? tileUrl;
  final String? attribution;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Map of the route',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: LayoutBuilder(
            builder: (context, box) {
              final size = Size(box.maxWidth, box.maxHeight);
              final view = MapView.fit(data.route, size);
              return ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Stack(
                  children: [
                    if (tileUrl != null)
                      for (final tile in view.tiles(tileUrl!))
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
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                    Positioned.fill(
                      child: CustomPaint(
                        key: const Key('route-map'),
                        painter: _RoutePainter(
                          view: view,
                          data: data,
                          selected: selected,
                        ),
                      ),
                    ),
                    if (tileUrl != null &&
                        attribution != null &&
                        attribution!.isNotEmpty)
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
                            attribution!,
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
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({
    required this.view,
    required this.data,
    required this.selected,
  }) : super(repaint: selected);

  final MapView view;
  final RideSeries data;
  final ValueNotifier<int?> selected;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i < data.route.length; i++) {
      final p = view.project(data.route[i]);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    // A pale edge under the line keeps it readable over any tile colour.
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = deepTeal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    _dot(canvas, view.project(data.route.first), deepTeal, 7); // start
    _dot(canvas, view.project(data.route.last), ironOxide, 7); // finish

    final index = selected.value;
    if (index != null) {
      final at = data.routePointAt(index);
      if (at != null) {
        final p = view.project(at);
        canvas.drawCircle(p, 11, Paint()..color = Colors.white);
        canvas.drawCircle(p, 8, Paint()..color = ironOxide);
        canvas.drawCircle(p, 3, Paint()..color = Colors.white);
      }
    }
  }

  void _dot(Canvas canvas, Offset at, Color color, double radius) {
    canvas.drawCircle(at, radius + 2, Paint()..color = Colors.white);
    canvas.drawCircle(at, radius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.view != view || old.data != data;
}
