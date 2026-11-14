import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/units.dart';
import '../../../core/l10n.dart';
import '../../../core/map_defaults.dart';
import '../../../core/widgets/chart_chrome.dart';
import '../../../core/theme.dart';
import 'geo.dart';
import 'lap_range.dart';
import 'ride_series.dart';
import 'route_painter.dart';

/// The ride's route on a map that fills the screen, so the member can pan and
/// zoom into it. Opened by tapping the small map.
class FullRouteMapScreen extends ConsumerStatefulWidget {
  const FullRouteMapScreen({
    super.key,
    required this.data,
    required this.selected,
    required this.selectedLap,
    this.tileUrl,
    this.attribution,
    this.elevationGainM,
  });

  final RideSeries data;
  final ValueNotifier<int?> selected;
  final ValueNotifier<LapRange?> selectedLap;
  final String? tileUrl;
  final String? attribution;

  /// The ride's climbing, when the screen knows it; the route summary reads it out.
  final double? elevationGainM;

  @override
  ConsumerState<FullRouteMapScreen> createState() => _FullRouteMapScreenState();
}

class _FullRouteMapScreenState extends ConsumerState<FullRouteMapScreen> {
  static const _minZoom = 3;
  static const _maxZoom = 18;

  LatLon? _center;
  double _zoom = 14;

  Offset? _focalStart;
  LatLon? _centerStart;
  double _zoomStart = 14;

  void _pan(ScaleUpdateDetails details) {
    final start = _focalStart;
    final centerStart = _centerStart;
    if (start == null || centerStart == null) return;

    final moved = pannedView(
      center: centerStart,
      zoom: _zoomStart,
      delta: details.localFocalPoint - start,
      scale: details.scale,
      minZoom: _minZoom,
      maxZoom: _maxZoom,
    );
    setState(() {
      _center = moved.center;
      _zoom = moved.zoom;
    });
  }

  void _zoomBy(int delta) => setState(
    () => _zoom = (_zoom + delta).clamp(_minZoom, _maxZoom).toDouble(),
  );

  @override
  Widget build(BuildContext context) {
    final colors = VelomineColors.of(context);
    final l10n = context.l10n;
    final units = ref.watch(unitsChoiceViewModelProvider);
    final distances =
        widget.data.distance?.whereType<double>() ?? const <double>[];
    final distanceM = distances.isEmpty ? null : distances.last;
    final summary = widget.elevationGainM == null
        ? l10n.routeMapDistanceSummary(km(units, distanceM))
        : l10n.routeMapSummary(
            km(units, distanceM),
            elevation(units, widget.elevationGainM),
          );
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            _zoomBy(event.scrollDelta.dy > 0 ? -1 : 1);
          }
        },
        child: GestureDetector(
          key: const Key('full-route-map'),
          onScaleStart: (details) {
            _focalStart = details.localFocalPoint;
            _centerStart = _center;
            _zoomStart = _zoom;
          },
          onScaleUpdate: _pan,
          child: LayoutBuilder(
            builder: (context, box) {
              final size = Size(box.maxWidth, box.maxHeight);
              final center = _center ?? _centerOfRoute(size);
              final view = MapView.centered(
                center: center,
                size: size,
                zoom: _zoom,
              );
              return Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                    ),
                  ),
                  if (widget.tileUrl != null)
                    for (final tile in view.tiles(widget.tileUrl!))
                      Positioned(
                        left: tile.left,
                        top: tile.top,
                        width: view.tilePixels,
                        height: view.tilePixels,
                        child: Image.network(
                          tile.url,
                          headers: mapTileHeaders,
                          fit: BoxFit.fill,
                          webHtmlElementStrategy:
                              WebHtmlElementStrategy.fallback,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                  Positioned.fill(
                    child: Semantics(
                      container: true,
                      label: summary,
                      child: ExcludeSemantics(
                        child: CustomPaint(
                          painter: RoutePainter(
                            view: view,
                            data: widget.data,
                            selected: widget.selected,
                            selectedLap: widget.selectedLap,
                            colors: colors,
                            heartRate: null,
                            showHeartRate: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: SafeArea(
                      child: Stack(
                        children: [
                          Positioned(
                            top: 8,
                            left: 8,
                            child: MapControl(
                              key: const Key('full-map-close'),
                              icon: Icons.close,
                              tooltip: l10n.close,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          if (widget.attribution != null &&
                              widget.attribution!.isNotEmpty)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: MapAttribution(text: widget.attribution!),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Fits the whole route once, the first time the map has a size.
  LatLon _centerOfRoute(Size size) {
    final bounds = boundsOf(widget.data.route);
    final center = (
      lat: (bounds.north + bounds.south) / 2,
      lon: (bounds.east + bounds.west) / 2,
    );
    _center = center;
    _zoom = _zoomStart = fitZoom(bounds, size, padding: 48).toDouble();
    return center;
  }
}
