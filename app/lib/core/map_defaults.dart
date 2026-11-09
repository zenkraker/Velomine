/// The map is always on. These match the server's defaults and are used until the server info arrives.
const defaultMapTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

const defaultMapAttribution = '© OpenStreetMap contributors';

/// OpenStreetMap's tile policy needs a User-Agent that names the app; the phone's
/// default `Dart/... (dart:io)` is refused with a 403 block page. A browser sets
/// its own, so the header only matters on a phone or desktop.
const mapTileHeaders = {
  'User-Agent': 'Velomine (+https://github.com/zenkraker/Velomine)',
};
