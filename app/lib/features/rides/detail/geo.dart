import 'dart:math' as math;
import 'dart:ui';

/// Web Mercator, the projection every slippy map tile set (OpenStreetMap and others) uses.
/// World pixel coordinates at [zoom] run from 0 to 256 * 2^zoom in both directions.
const tileSize = 256.0;

typedef LatLon = ({double lat, double lon});

typedef Bounds = ({double north, double south, double east, double west});

double worldX(double lon, int zoom) =>
    (lon + 180) / 360 * tileSize * math.pow(2, zoom);

double worldY(double lat, int zoom) {
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

/// Where the route sits on screen: a map of [size] pixels at [zoom], centred on the middle of the route.
class MapView {
  MapView({required this.bounds, required this.size, required this.zoom})
    : originX =
          (worldX(bounds.east, zoom) + worldX(bounds.west, zoom)) / 2 -
          size.width / 2,
      originY =
          (worldY(bounds.north, zoom) + worldY(bounds.south, zoom)) / 2 -
          size.height / 2;

  factory MapView.fit(List<LatLon> points, Size size) {
    final bounds = boundsOf(points);
    return MapView(bounds: bounds, size: size, zoom: fitZoom(bounds, size));
  }

  final Bounds bounds;
  final Size size;
  final int zoom;

  /// The world pixel at the top-left corner of the view.
  final double originX;
  final double originY;

  Offset project(LatLon p) =>
      Offset(worldX(p.lon, zoom) - originX, worldY(p.lat, zoom) - originY);

  /// The map tiles that cover the view, each with its address and position on screen.
  List<MapTile> tiles(String urlTemplate) {
    final count = 1 << zoom;
    final firstX = (originX / tileSize).floor();
    final lastX = ((originX + size.width) / tileSize).floor();
    final firstY = math.max(0, (originY / tileSize).floor());
    final lastY = math.min(
      count - 1,
      ((originY + size.height) / tileSize).floor(),
    );
    return [
      for (var y = firstY; y <= lastY; y++)
        for (var x = firstX; x <= lastX; x++)
          MapTile(
            url: urlTemplate
                .replaceAll('{z}', '$zoom')
                .replaceAll('{x}', '${x % count}')
                .replaceAll('{y}', '$y'),
            left: x * tileSize - originX,
            top: y * tileSize - originY,
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
