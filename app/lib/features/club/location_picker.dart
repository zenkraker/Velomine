import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/location_service.dart';
import '../rides/detail/geo.dart';

/// Picks a point for a club, or for the rider's saved fallback. With a map background the pin stays at the centre
/// and the map moves under it; without one the coordinates are typed.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initial,
    this.tileUrl,
    this.attribution,
    required this.locationService,
  });

  final GeoPoint? initial;
  final String? tileUrl;
  final String? attribution;
  final LocationService locationService;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _minZoom = 3;
  static const _maxZoom = 18;

  late final _latField = TextEditingController(
    text: widget.initial?.latitude.toStringAsFixed(5) ?? '',
  );
  late final _lonField = TextEditingController(
    text: widget.initial?.longitude.toStringAsFixed(5) ?? '',
  );

  double? _latitude;
  double? _longitude;
  int _zoom = 14;
  bool _locating = false;
  String? _fieldError;

  Offset? _focalStart;
  double? _latitudeStart;
  double? _longitudeStart;
  int _zoomStart = 14;

  bool get _hasMap => widget.tileUrl != null;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initial?.latitude;
    _longitude = widget.initial?.longitude;
    if (_hasMap && _latitude == null) {
      _locate(tell: false);
    }
  }

  @override
  void dispose() {
    _latField.dispose();
    _lonField.dispose();
    super.dispose();
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

    final zoom = (_zoomStart + math.log(details.scale) / math.ln2)
        .round()
        .clamp(_minZoom, _maxZoom);
    final delta = details.localFocalPoint - start;
    final scale = tileSize * math.pow(2, zoom);
    final longitude = longitudeStart - delta.dx / scale * 360;
    final y = worldY(latitudeStart, zoom) - delta.dy;
    final n = math.pi * (1 - 2 * y / scale);
    final latitude =
        180 / math.pi * math.atan((math.exp(n) - math.exp(-n)) / 2);

    setState(() {
      _zoom = zoom;
      _latitude = latitude.clamp(-85, 85);
      _longitude = (longitude + 180) % 360 - 180;
    });
  }

  /// Takes the typed coordinates; false when they are not two numbers in range.
  bool _takeFields() {
    final latitude = double.tryParse(
      _latField.text.trim().replaceAll(',', '.'),
    );
    final longitude = double.tryParse(
      _lonField.text.trim().replaceAll(',', '.'),
    );
    if (latitude == null ||
        longitude == null ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      setState(() => _fieldError = context.l10n.locationCoordinatesInvalid);
      return false;
    }

    setState(() {
      _fieldError = null;
      _latitude = latitude;
      _longitude = longitude;
    });
    return true;
  }

  void _use() {
    if (_hasMap) {
      if (_latitude == null || _longitude == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.locationMapFirst)));
        return;
      }
    } else if (!_takeFields()) {
      return;
    }

    final latitude = _latitude;
    final longitude = _longitude;
    if (latitude == null || longitude == null) return;
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
              child: Text(
                _hasMap ? l10n.locationPickerHelp : l10n.locationNoMap,
              ),
            ),
            Expanded(child: _hasMap ? _map() : _coordinates()),
            Padding(
              padding: const EdgeInsets.all(16),
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
                _zoom = (_zoom + (event.scrollDelta.dy > 0 ? -1 : 1)).clamp(
                  _minZoom,
                  _maxZoom,
                );
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
                for (final tile in view.tiles(widget.tileUrl!))
                  Positioned(
                    left: tile.left,
                    top: tile.top,
                    width: tileSize,
                    height: tileSize,
                    child: Image.network(
                      tile.url,
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
                if (widget.attribution != null &&
                    widget.attribution!.isNotEmpty)
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
          ),
        );
      },
    );
  }

  Widget _coordinates() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('location-lat'),
                controller: _latField,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.locationLatitude,
                  hintText: context.l10n.locationCoordinatesHint,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const Key('location-lon'),
                controller: _lonField,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.locationLongitude,
                  hintText: context.l10n.locationCoordinatesHint,
                ),
              ),
            ),
          ],
        ),
        if (_fieldError != null) ...[
          const SizedBox(height: 12),
          Text(
            _fieldError!,
            key: const Key('location-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}
