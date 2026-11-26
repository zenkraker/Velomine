import '../../core/format.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/loading_state.dart';

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n.dart';
import '../../core/location_service.dart';
import '../../core/map_defaults.dart';
import '../rides/detail/geo.dart';
import '../../core/tokens.dart';
import '../../core/widgets/bottom_action_bar.dart';
import '../../core/widgets/page_scaffold.dart';

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
    // Outside the shell: the page asks for the header on a phone too. The map has a fixed height, so it
    // sits in the page's scroll view; its gestures claim the pointer at once so a drag moves the map.
    return Scaffold(
      body: PageHeaderScope(
        showOnPhone: true,
        child: PageScaffold(
          title: l10n.locationPickerTitle,
          subtitle: l10n.locationPickerHelp,
          onBack: () => Navigator.of(context).maybePop(),
          maxWidth: AppLayout.contentNarrow,
          bottomAction: BottomActionBar.button(
            buttonKey: const Key('location-use'),
            label: l10n.locationPickerUse,
            onPressed: _use,
            maxWidth: AppLayout.contentNarrow,
          ),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: SizedBox(height: AppClub.pickerMapHeight, child: _map()),
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
          child: RawGestureDetector(
            key: const Key('location-map'),
            gestures: {
              _EagerScaleRecognizer:
                  GestureRecognizerFactoryWithHandlers<_EagerScaleRecognizer>(
                    _EagerScaleRecognizer.new,
                    (recognizer) {
                      recognizer
                        ..onStart = (details) {
                          _focalStart = details.localFocalPoint;
                          _latitudeStart = latitude;
                          _longitudeStart = longitude;
                          _zoomStart = _zoom;
                        }
                        ..onUpdate = _pan;
                    },
                  ),
            },
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
                if (_locating) const LoadingState(),
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: IconButton.filledTonal(
                    key: const Key('location-current'),
                    tooltip: context.l10n.locationPickerCurrent,
                    onPressed: _locating ? null : () => _locate(tell: true),
                    icon: const Icon(Icons.my_location),
                  ),
                ),
                Positioned(
                  left: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      '${decimal(latitude, 5)}, '
                      '${decimal(longitude, 5)}',
                      key: const Key('location-readout'),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: colors.surface.withValues(alpha: 0.75),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xs / 2,
                    ),
                    child: Text(
                      widget.attribution,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: colors.onSurface),
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

/// A scale recogniser that claims the pointer on touch down, so the page's scroll view does not take a
/// drag that is meant to move the map.
class _EagerScaleRecognizer extends ScaleGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}
