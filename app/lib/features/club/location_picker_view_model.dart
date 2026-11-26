import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/location_service.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import 'location_picker_state.dart';

part 'location_picker_view_model.g.dart';

/// The zoom the map opens at, and the one it goes to once the device gives a position.
const locationPickerZoom = 14.0;
const locationPickerDeviceZoom = 15.0;

/// The device's position as a value: the picker never sees the service's null.
class LocationPickerData {
  LocationPickerData(this._service);

  final LocationService _service;

  Future<Result<GeoPoint?>> current() async {
    try {
      return Ok(await _service.current());
    } on Object {
      // A platform that refuses outright is the same as one that says nothing.
      return const Ok(null);
    }
  }
}

@riverpod
LocationPickerData locationPickerData(Ref ref) =>
    LocationPickerData(ref.watch(locationServiceProvider));

/// The map picker for one point: where the map looks, and asking the device for the rider's position.
///
/// Route scoped: one map, one point. The page returns the point itself; nothing is saved here.
@riverpod
class LocationPickerViewModel extends _$LocationPickerViewModel {
  static const _minZoom = 3.0;
  static const _maxZoom = 18.0;

  @override
  LocationPickerState build(LocationPickerArgs args) =>
      LocationPickerState(point: args.initial, zoom: locationPickerZoom);

  /// Moves the map, and takes back what the page was complaining about.
  void moveTo(GeoPoint point, {required double zoom}) => state = state.copyWith(
    point: point,
    zoom: zoom.clamp(_minZoom, _maxZoom),
    clearNote: true,
  );

  /// One position from the device, told to the rider when it gives none: the map stays where it was.
  Future<void> locate() async {
    if (state.locate.running) return;
    state = state.copyWith(locate: state.locate.start(), clearNote: true);
    final result = await ref.read(locationPickerDataProvider).current();
    if (!ref.mounted) return;
    final point = result.valueOrNull;
    state = point == null
        ? state.copyWith(
            locate: state.locate.finish(result),
            note: LocationPickerNote.deviceMissing,
          )
        : state.copyWith(
            locate: state.locate.finish(result),
            point: point,
            zoom: locationPickerDeviceZoom,
          );
  }

  /// The point to return, or null when the rider has not put the map anywhere: the page then says what to do.
  GeoPoint? use() {
    if (state.point == null) {
      state = state.copyWith(note: LocationPickerNote.pointMissing);
    }
    return state.point;
  }
}
