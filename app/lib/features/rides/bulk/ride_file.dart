import 'dart:typed_data';

/// One file offered for upload, from a dropped folder or a file picker.
///
/// The web build implements it over the browser's own `File`; tests use a fake.
abstract interface class RideFileEntry {
  /// The file's own name, such as `2026-11-02-081500.fit`.
  String get name;

  /// Where it sat in the dropped folder, such as `Activities/2026/ride.fit`. Only for telling files apart.
  String get path;

  Future<Uint8List> read();
}

/// Ride files carry one of these endings, gzipped or not. Everything else in a bike computer's folder
/// (settings, workouts, notes) is skipped.
const rideFileExtensions = ['fit', 'gpx', 'tcx'];

/// Whether [name] looks like a ride file: `.fit`, `.gpx` or `.tcx`, or the same with `.gz`, in any letter case.
bool isRideFileName(String name) {
  var lower = name.toLowerCase();
  if (lower.endsWith('.gz')) lower = lower.substring(0, lower.length - 3);
  for (final extension in rideFileExtensions) {
    if (lower.endsWith('.$extension') && lower.length > extension.length + 1) {
      return true;
    }
  }
  return false;
}

/// The ride files among [entries], and how many other files were set aside.
({List<RideFileEntry> rides, int skipped}) selectRideFiles(
  Iterable<RideFileEntry> entries,
) {
  final rides = <RideFileEntry>[];
  var skipped = 0;
  for (final entry in entries) {
    if (isRideFileName(entry.name)) {
      rides.add(entry);
    } else {
      skipped++;
    }
  }
  return (rides: rides, skipped: skipped);
}
