import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/location_service.dart';
import '../../core/map_defaults.dart';
import '../rides/detail/geo.dart';
import '../../core/tokens.dart';

/// Picks a point for a club, or for the rider's saved fallback. The map is always there: the pin stays at the
/// centre and the map moves under it.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initial,
    required this.tileUrl,
    required this.attribution,
    required this.locationService,
  });

  final GeoPoint? initial;
  final String tileUrl;
  final String attribution;
  final LocationService locationService;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _minZoom = 3;
  static const _maxZoom = 18;

  double? _latitude;
  double? _longitude;
  double _zoom = 14;
  bool _locating = false;

  Offset? _focalStart;
  double? _latitudeStart;
  double? _longitudeStart;
  double _zoomStart = 14;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initial?.latitude;
    _longitude = widget.initial?.longitude;
    if (_latitude == null) {
      _locate(tell: false);
    }
  }

  Future<void> _locate({required bool tell}) async {
    setState(() => _locating = true);
    final point = await widget.locationService.current();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (point != null) {
        _latitude = point.latitude;
        _longitude = point.longitude;
        _zoom = 15;
      }
    });
    if (point == null && tell) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.locationCurrentUnavailable)),
      );
    }
  }

  void _pan(ScaleUpdateDetails details) {
    final start = _focalStart;
    final latitudeStart = _latitudeStart;
    final longitudeStart = _longitudeStart;
    if (start == null || latitudeStart == null || longitudeStart == null) {
      return;
    }

    final moved = pannedView(
      center: (lat: latitudeStart, lon: longitudeStart),
      zoom: _zoomStart,
      delta: details.localFocalPoint - start,
      scale: details.scale,
      minZoom: _minZoom,
      maxZoom: _maxZoom,
    );

    setState(() {
      _zoom = moved.zoom;
      _latitude = moved.center.lat;
      _longitude = moved.center.lon;
    });
  }

  void _use() {
    final latitude = _latitude;
    final longitude = _longitude;
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.locationMapFirst)));
      return;
    }
    Navigator.of(context)
        .pop<GeoPoint>((latitude: latitude, longitude: longitude));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.locationPickerTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(l10n.locationPickerHelp),
            ),
            Expanded(child: _map()),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('location-use'),
                  onPressed: _use,
                  icon: const Icon(Icons.place),
                  label: Text(l10n.locationPickerUse),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _map() {
    final latitude = _latitude ?? 0;
    final longitude = _longitude ?? 0;
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        final view = MapView.centered(
          center: (lat: latitude, lon: longitude),
          size: size,
          zoom: _zoom,
        );
        final colors = Theme.of(context).colorScheme;
        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              setState(() {
                _zoom = (_zoom + (event.scrollDelta.dy > 0 ? -1 : 1))
                    .clamp(_minZoom, _maxZoom)
                    .toDouble();
              });
            }
          },
          child: GestureDetector(
            key: const Key('location-map'),
            onScaleStart: (details) {
              _focalStart = details.localFocalPoint;
              _latitudeStart = latitude;
              _longitudeStart = longitude;
              _zoomStart = _zoom;
            },
            onScaleUpdate: _pan,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(color: colors.surfaceContainerHighest),
                ),
                for (final tile in view.tiles(widget.tileUrl))
                  Positioned(
                    left: tile.left,
                    top: tile.top,
                    width: view.tilePixels,
                    height: view.tilePixels,
                    child: Image.network(
                      tile.url,
                      headers: mapTileHeaders,
                      fit: BoxFit.fill,
                      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                Center(child: Icon(Icons.place, size: 44, color: colors.error)),
                if (_locating) const Center(child: CircularProgressIndicator()),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filledTonal(
                    key: const Key('location-current'),
                    tooltip: context.l10n.locationPickerCurrent,
                    onPressed: _locating ? null : () => _locate(tell: true),
                    icon: const Icon(Icons.my_location),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        '${latitude.toStringAsFixed(5)}, '
                        '${longitude.toStringAsFixed(5)}',
                        key: const Key('location-readout'),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.75),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      widget.attribution,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
