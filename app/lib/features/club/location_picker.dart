import '../../core/format.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/loading_state.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n.dart';
import '../../core/location_service.dart';
import '../../core/map_defaults.dart';
import '../rides/detail/geo.dart';
import '../../core/tokens.dart';
import '../../core/widgets/bottom_action_bar.dart';
import '../../core/widgets/inline_error.dart';
import '../../core/widgets/page_scaffold.dart';
import 'location_picker_state.dart';
import 'location_picker_view_model.dart';

/// Picks a point for a club, or for the rider's saved fallback. The map is always there: the pin stays at the
/// centre and the map moves under it.
///
/// The point the page was opened with is read once, on the first build: the page is pushed, never rebuilt under
/// another point.
class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initial,
    required this.tileUrl,
    required this.attribution,
  });

  final GeoPoint? initial;
  final String tileUrl;
  final String attribution;

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  late final LocationPickerArgs _args = LocationPickerArgs(widget.initial);

  /// Gestures only: where a drag or a pinch started.
  Offset? _focalStart;
  GeoPoint? _pointStart;
  double _zoomStart = locationPickerZoom;

  @override
  void initState() {
    super.initState();
    // Opened without a point, the page asks the device once, silently.
    if (widget.initial == null) {
      Future.microtask(
        () =>
            ref.read(locationPickerViewModelProvider(_args).notifier).locate(),
      );
    }
  }

  LocationPickerViewModel get _notifier =>
      ref.read(locationPickerViewModelProvider(_args).notifier);

  void _pan(LocationPickerState state, ScaleUpdateDetails details) {
    final start = _focalStart;
    final pointStart = _pointStart;
    if (start == null || pointStart == null) return;

    final moved = pannedView(
      center: (lat: pointStart.latitude, lon: pointStart.longitude),
      zoom: _zoomStart,
      delta: details.localFocalPoint - start,
      scale: details.scale,
      minZoom: 3,
      maxZoom: 18,
    );
    _notifier.moveTo((
      latitude: moved.center.lat,
      longitude: moved.center.lon,
    ), zoom: moved.zoom);
  }

  void _use() {
    final point = _notifier.use();
    if (point == null) return;
    Navigator.of(context).pop<GeoPoint>(point);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(locationPickerViewModelProvider(_args));
    final note = switch (state.note) {
      LocationPickerNote.deviceMissing => l10n.locationCurrentUnavailable,
      LocationPickerNote.pointMissing => l10n.locationMapFirst,
      null => null,
    };
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
              child: SizedBox(
                height: AppClub.pickerMapHeight,
                child: _map(state),
              ),
            ),
            if (note != null)
              InlineError(note, key: const Key('location-error')),
          ],
        ),
      ),
    );
  }

  Widget _map(LocationPickerState state) {
    final point = state.point;
    final latitude = point?.latitude ?? 0;
    final longitude = point?.longitude ?? 0;
    final colors = Theme.of(context).colorScheme;
    final view = MapView.centered(
      center: (lat: latitude, lon: longitude),
      size: Size(MediaQuery.sizeOf(context).width, AppClub.pickerMapHeight),
      zoom: state.zoom,
    );
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _notifier.moveTo((
            latitude: latitude,
            longitude: longitude,
          ), zoom: state.zoom + (event.scrollDelta.dy > 0 ? -1 : 1));
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
                      _pointStart = point;
                      _zoomStart = state.zoom;
                    }
                    ..onUpdate = (details) => _pan(state, details);
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
            if (state.locate.running) const LoadingState(),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: IconButton.filledTonal(
                key: const Key('location-current'),
                tooltip: context.l10n.locationPickerCurrent,
                onPressed: state.locate.running ? null : _notifier.locate,
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
                  '${decimal(latitude, 5)}, ${decimal(longitude, 5)}',
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
