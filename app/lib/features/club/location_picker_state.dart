import '../../core/command.dart';
import '../../core/location_service.dart';

/// The state the map picker opens with: the point it was given, if any.
class LocationPickerArgs {
  const LocationPickerArgs(this.initial);

  final GeoPoint? initial;

  @override
  bool operator ==(Object other) =>
      other is LocationPickerArgs && other.initial == initial;

  @override
  int get hashCode => initial.hashCode;
}

/// What the line under the map has to say, for the view to word in the language on screen.
enum LocationPickerNote { deviceMissing, pointMissing }

/// The chosen point, where the map is looking, and the two things the page can complain about.
class LocationPickerState {
  const LocationPickerState({
    this.point,
    this.zoom = 14,
    this.locate = const CommandState.idle(),
    this.note,
  });

  /// The centre of the map: the point the page returns.
  final GeoPoint? point;

  final double zoom;

  /// Asking the device for one position.
  final VoidCommand locate;

  /// Why there is nothing to use, or why the device gave no position; null once the rider moves on.
  final LocationPickerNote? note;

  LocationPickerState copyWith({
    GeoPoint? point,
    double? zoom,
    VoidCommand? locate,
    LocationPickerNote? note,
    bool clearNote = false,
  }) => LocationPickerState(
    point: point ?? this.point,
    zoom: zoom ?? this.zoom,
    locate: locate ?? this.locate,
    note: clearNote ? null : (note ?? this.note),
  );
}
