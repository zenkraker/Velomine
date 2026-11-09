import 'dart:math' as math;
import 'dart:ui';

/// Web Mercator, the projection every slippy map tile set (OpenStreetMap and others) uses.
/// World pixel coordinates at [zoom] run from 0 to 256 * 2^zoom in both directions.
const tileSize = 256.0;

typedef LatLon = ({double lat, double lon});

typedef Bounds = ({double north, double south, double east, double west});

double worldX(double lon, num zoom) =>
    (lon + 180) / 360 * tileSize * math.pow(2, zoom);

double worldY(double lat, num zoom) {
  final rad = lat * math.pi / 180;
  return (1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) /
      2 *
      tileSize *
      math.pow(2, zoom);
}

Bounds boundsOf(List<LatLon> points) {
  var north = -90.0, south = 90.0, east = -180.0, west = 180.0;
  for (final p in points) {
    north = math.max(north, p.lat);
    south = math.min(south, p.lat);
    east = math.max(east, p.lon);
    west = math.min(west, p.lon);
  }
  return (north: north, south: south, east: east, west: west);
}

/// The most detailed zoom at which the whole route fits inside [size], leaving [padding] on every side.
int fitZoom(
  Bounds b,
  Size size, {
  double padding = 28,
  int minZoom = 2,
  int maxZoom = 17,
}) {
  for (var z = maxZoom; z > minZoom; z--) {
    final width = worldX(b.east, z) - worldX(b.west, z);
    final height = worldY(b.south, z) - worldY(b.north, z);
    if (width <= size.width - 2 * padding &&
        height <= size.height - 2 * padding) {
      return z;
    }
  }
  return minZoom;
}

/// The centre and zoom after dragging [delta] pixels and pinching by [scale].
/// The zoom stays fractional, so a pinch moves the map continuously instead of
/// snapping from one tile level to the next.
({LatLon center, double zoom}) pannedView({
  required LatLon center,
  required num zoom,
  required Offset delta,
  required double scale,
  num minZoom = 2,
  num maxZoom = 18,
}) {
  final nextZoom = (zoom + math.log(scale) / math.ln2)
      .clamp(minZoom, maxZoom)
      .toDouble();
  final pixels = tileSize * math.pow(2, nextZoom);
  final lon = center.lon - delta.dx / pixels * 360;
  final y = worldY(center.lat, nextZoom) - delta.dy;
  final n = math.pi * (1 - 2 * y / pixels);
  final lat = 180 / math.pi * math.atan((math.exp(n) - math.exp(-n)) / 2);
  return (
    center: (lat: lat.clamp(-85, 85), lon: (lon + 180) % 360 - 180),
    zoom: nextZoom,
  );
}

/// Where the route sits on screen: a map of [size] pixels at [zoom], centred on the middle of the route.
class MapView {
  MapView({required this.bounds, required this.size, required num zoom})
    : zoom = zoom.toDouble(),
      originX =
          (worldX(bounds.east, zoom) + worldX(bounds.west, zoom)) / 2 -
          size.width / 2,
      originY =
          (worldY(bounds.north, zoom) + worldY(bounds.south, zoom)) / 2 -
          size.height / 2;

  factory MapView.fit(List<LatLon> points, Size size) {
    final bounds = boundsOf(points);
    return MapView(bounds: bounds, size: size, zoom: fitZoom(bounds, size));
  }

  /// A view centred on [center], for panning and picking a point.
  MapView.centered({
    required LatLon center,
    required this.size,
    required num zoom,
  }) : zoom = zoom.toDouble(),
       bounds = (
         north: center.lat,
         south: center.lat,
         east: center.lon,
         west: center.lon,
       ),
       originX = worldX(center.lon, zoom) - size.width / 2,
       originY = worldY(center.lat, zoom) - size.height / 2;

  final Bounds bounds;
  final Size size;
  final double zoom;

  /// The integer tile level used, and the size one of its tiles has on screen.
  /// A fractional [zoom] is drawn by scaling that level instead of snapping.
  int get tileZoom => zoom.round();

  double get tilePixels => tileSize * math.pow(2, zoom - tileZoom).toDouble();

  /// The world pixel at the top-left corner of the view.
  final double originX;
  final double originY;

  Offset project(LatLon p) =>
      Offset(worldX(p.lon, zoom) - originX, worldY(p.lat, zoom) - originY);

  /// The latitude and longitude under a point on screen.
  LatLon unproject(Offset offset) {
    final scale = tileSize * math.pow(2, zoom).toDouble();
    final x = originX + offset.dx;
    final y = originY + offset.dy;
    final lon = x / scale * 360 - 180;
    final n = math.pi * (1 - 2 * y / scale);
    final lat = 180 / math.pi * math.atan((math.exp(n) - math.exp(-n)) / 2);
    return (lat: lat.clamp(-85, 85), lon: lon);
  }

  /// The map tiles that cover the view, each with its address and position on screen.
  List<MapTile> tiles(String urlTemplate) {
    final level = tileZoom;
    final pixels = tilePixels;
    final count = 1 << level;
    final firstX = (originX / pixels).floor();
    final lastX = ((originX + size.width) / pixels).floor();
    final firstY = math.max(0, (originY / pixels).floor());
    final lastY = math.min(
      count - 1,
      ((originY + size.height) / pixels).floor(),
    );
    return [
      for (var y = firstY; y <= lastY; y++)
        for (var x = firstX; x <= lastX; x++)
          MapTile(
            url: urlTemplate
                .replaceAll('{z}', '$level')
                .replaceAll('{x}', '${x % count}')
                .replaceAll('{y}', '$y'),
            left: x * pixels - originX,
            top: y * pixels - originY,
          ),
    ];
  }
}

class MapTile {
  const MapTile({required this.url, required this.left, required this.top});

  final String url;
  final double left;
  final double top;
}
