# flutter_map 8.3.2

Approved by the owner on 2026-11-26; the evaluation was waived. This page records the facts, not a decision to take.

## Need
Every map in the app (the ride route, the full-screen route, the location picker, the meeting point) was drawn by hand: tile maths, panning and pinching, a tile ring and a fade-in. A map widget replaces all of it. The platform has none.

## Alternatives considered
Keep the hand-drawn map (a gesture, tile and zoom engine of our own to maintain). Other community map packages were not compared: the owner chose this one.

## Licence
BSD-3-Clause. Compatible with Velomine's licence.

## Maintenance
- Publisher: fleaflet.dev; community-maintained.
- Version taken: 8.3.2 (latest stable, changelog dated 2026-08-27).
- 8.2.0 added in-memory tile caching to `NetworkTileProvider`; 8.3.0 made it WASM-compatible. Reading the 8.3.2 source, the built-in cache is a file cache on Android and iOS (the platform cache directory, 1 GB by default, honouring the tile server's freshness headers) and does nothing on the web, where the browser's HTTP cache serves. Capped at 100 MB in `AppMap` (`maxCacheSize`).

## Security
- Known advisories or CVEs: none found.
- No telemetry found. It contacts only the configured tile addresses.
- Transitive dependencies from pub.dev: async, collection, dart_earcut, dart_polylabel2, flutter, http, latlong2, meta, path, path_provider, proj4dart, uuid. `pub get` also locked archive, jni_flutter, mgrs_dart, path_provider_android, path_provider_foundation, posix, simple_sparse_list, unicode and wkt_parser beneath them.
- `latlong2` (0.10.1) is also a direct dependency, because `flutter_map` does not re-export `LatLng` and the analyzer requires a package that is imported to be declared. Only `app_map.dart` imports it.

## Platform support
- Flutter: Android, iOS and web; pure Dart, with `path_provider` for the tile cache on the phone.
- Raster tiles only. On the web the browser sets the User-Agent, so the OpenStreetMap Referer comes from `<meta name="referrer" content="strict-origin">` in `app/web/index.html`. On the phone `mapTileHeaders` sets the User-Agent.

## Size and performance
Not measured.

## Risk and exit plan
If it is abandoned, `AppMap` is the only file that imports it; the rest of the app speaks lines, dots and a centre. Replacing it means rewriting that one widget.

## Recommendation
Approved with conditions, as recorded in `approved.md`: raster tiles from the configured address only, one wrapper, theme colours only, attribution always visible, no prefetching or bulk download.
