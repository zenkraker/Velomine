import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../geo.dart';
import '../map_defaults.dart';
import '../motion.dart';
import '../tokens.dart';
import 'chart_chrome.dart';

/// A line over the map: [borderColor] draws a halo of [borderWidth] on each side of it.
class AppMapLine {
  const AppMapLine({
    required this.points,
    required this.color,
    required this.width,
    this.borderColor,
    this.borderWidth = 0,
  });

  final List<LatLon> points;
  final Color color;
  final double width;
  final Color? borderColor;
  final double borderWidth;
}

/// A round dot over the map, [size] across including its [ringColor] ring of [ringWidth].
class AppMapDot {
  const AppMapDot({
    required this.at,
    required this.color,
    required this.ringColor,
    required this.size,
    required this.ringWidth,
  });

  final LatLon at;
  final Color color;
  final Color ringColor;
  final double size;
  final double ringWidth;
}

/// The one map of the app, drawn by `flutter_map` and the only file that imports it. Tiles come from [tileUrl]
/// (none draws the lines alone and asks no server for anything). Give it either [fit], the points to frame, or
/// [center] and [zoom]; with [center], a new centre or zoom moves the map, and [onMoved] reports what the rider
/// dragged or pinched it to.
class AppMap extends StatefulWidget {
  const AppMap({
    super.key,
    this.tileUrl,
    this.attribution,
    this.attributionAlignment = Alignment.bottomRight,
    this.attributionInset = EdgeInsets.zero,
    this.fit,
    this.fitPadding = AppSpacing.xl,
    this.center,
    this.zoom = 14,
    this.interactive = false,
    this.dimTiles = false,
    this.lines = const [],
    this.dots = const [],
    this.onMoved,
    this.overlay = const [],
  }) : assert(
         (fit == null) != (center == null),
         'Give a map either points to fit or a centre.',
       );

  /// The tile address with `{z}`, `{x}` and `{y}`; null for no tiles.
  final String? tileUrl;
  final String? attribution;
  final Alignment attributionAlignment;

  /// Room kept round the credit, for a system bar the map runs under.
  final EdgeInsets attributionInset;
  final List<LatLon>? fit;
  final double fitPadding;
  final LatLon? center;
  final double zoom;

  /// Whether the rider can pan and zoom it. A map that is not interactive lets every touch through to its parent.
  final bool interactive;

  /// Lowers the tiles' saturation and brightness, so a line over them stays the loudest thing.
  final bool dimTiles;
  final List<AppMapLine> lines;
  final List<AppMapDot> dots;
  final void Function(LatLon center, double zoom)? onMoved;

  /// Widgets over the map, placed by the caller.
  final List<Widget> overlay;

  /// The nearest and the furthest the map can zoom.
  static const minZoom = 3.0;
  static const maxZoom = 18.0;

  static const _tileCacheBytes = 100 * 1000 * 1000;

  /// Replaces the network tile provider, for tests that must not reach a server.
  static TileProvider Function()? tileProviderForTests;

  @override
  State<AppMap> createState() => _AppMapState();
}

class _AppMapState extends State<AppMap> {
  final _controller = MapController();
  late final TileProvider _tiles =
      AppMap.tileProviderForTests?.call() ??
      NetworkTileProvider(
        headers: {...mapTileHeaders},
        // The default disk cache on the phone is 1 GB; a route map needs far less.
        cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
          maxCacheSize: AppMap._tileCacheBytes,
        ),
      );
  bool _ready = false;

  @override
  void didUpdateWidget(AppMap old) {
    super.didUpdateWidget(old);
    final center = widget.center;
    if (center == null || !_ready) return;
    final target = LatLng(center.lat, center.lon);
    if (target == _controller.camera.center &&
        widget.zoom == _controller.camera.zoom) {
      return;
    }
    // flutter_map rebuilds itself on a move, which is not allowed while this widget is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.move(target, widget.zoom);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tiles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tileUrl = widget.tileUrl;
    final fit = widget.fit;
    final center = widget.center;
    final attribution = widget.attribution;
    final tiles = tileUrl == null
        ? null
        : TileLayer(
            urlTemplate: tileUrl,
            userAgentPackageName: 'app.velomine.velomine',
            tileProvider: _tiles,
            tileDisplay: reduceMotion(context)
                ? const TileDisplay.instantaneous()
                : const TileDisplay.fadeIn(duration: AppMotion.fast),
          );
    final map = FlutterMap(
      mapController: _controller,
      options: MapOptions(
        backgroundColor: scheme.surfaceContainerHighest,
        minZoom: AppMap.minZoom,
        maxZoom: AppMap.maxZoom,
        initialCenter: center == null
            ? const LatLng(0, 0)
            : LatLng(center.lat, center.lon),
        initialZoom: widget.zoom,
        initialCameraFit: fit == null
            ? null
            : CameraFit.coordinates(
                coordinates: [for (final p in fit) LatLng(p.lat, p.lon)],
                padding: EdgeInsets.all(widget.fitPadding),
                maxZoom: 17,
              ),
        interactionOptions: InteractionOptions(
          flags: widget.interactive
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.none,
        ),
        onMapReady: () => _ready = true,
        onPositionChanged: (camera, hasGesture) {
          if (!hasGesture) return;
          widget.onMoved?.call((
            lat: camera.center.latitude,
            lon: camera.center.longitude,
          ), camera.zoom);
        },
      ),
      children: [
        if (tiles != null)
          widget.dimTiles
              ? ColorFiltered(
                  colorFilter: ColorFilter.matrix(
                    _dimTiles(Theme.of(context).brightness == Brightness.dark),
                  ),
                  child: tiles,
                )
              : tiles,
        PolylineLayer(
          polylines: [
            for (final line in widget.lines)
              Polyline(
                points: [for (final p in line.points) LatLng(p.lat, p.lon)],
                color: line.color,
                strokeWidth: line.width,
                borderColor: line.borderColor ?? Colors.transparent,
                borderStrokeWidth: line.borderWidth,
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            for (final dot in widget.dots)
              Marker(
                point: LatLng(dot.at.lat, dot.at.lon),
                width: dot.size,
                height: dot.size,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: dot.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dot.ringColor,
                      width: dot.ringWidth,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
    return Stack(
      children: [
        Positioned.fill(
          // The callers label the map as a whole; its own pieces say nothing.
          child: ExcludeSemantics(
            child: IgnorePointer(ignoring: !widget.interactive, child: map),
          ),
        ),
        ...widget.overlay,
        if (tileUrl != null && attribution != null && attribution.isNotEmpty)
          Padding(
            padding: widget.attributionInset,
            child: Align(
              alignment: widget.attributionAlignment,
              child: MapAttribution(
                key: const Key('map-attribution'),
                text: attribution,
              ),
            ),
          ),
      ],
    );
  }
}

/// Lowers a map tile's saturation and brightness, so a route drawn over it stays the loudest thing.
/// A dark theme dims harder: its tiles are already dark.
List<double> _dimTiles(bool dark) {
  const saturation = 0.45;
  final brightness = dark ? 0.55 : 0.85;
  const r = 0.2126, g = 0.7152, b = 0.0722;
  final matrix = <double>[
    (1 - saturation) * r + saturation,
    (1 - saturation) * g,
    (1 - saturation) * b,
    0,
    0,
    (1 - saturation) * r,
    (1 - saturation) * g + saturation,
    (1 - saturation) * b,
    0,
    0,
    (1 - saturation) * r,
    (1 - saturation) * g,
    (1 - saturation) * b + saturation,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
  // Darken the three colour rows; the alpha row stays exactly as it was.
  return [
    for (var i = 0; i < matrix.length; i++)
      i ~/ 5 < 3 ? matrix[i] * brightness : matrix[i].toDouble(),
  ];
}
