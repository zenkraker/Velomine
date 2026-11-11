import 'package:file_selector/file_selector.dart';

/// Opens the ride file picker. The real one is in app.dart; tests pass their own.
typedef FilePicker = Future<XFile?> Function();

/// The real ride file picker: FIT, GPX, TCX or a gzipped one.
Future<XFile?> pickRideFile() => openFile(
  acceptedTypeGroups: const [
    XTypeGroup(label: 'Rides', extensions: ['fit', 'gpx', 'tcx', 'gz']),
  ],
);

/// Opens the picker for a Strava export, the ZIP Strava hands out.
Future<XFile?> pickStravaExport() => openFile(
  acceptedTypeGroups: const [
    XTypeGroup(label: 'Strava export', extensions: ['zip']),
  ],
);

/// Opens the picker for a GPX file to turn into a club route.
Future<XFile?> pickGpxFile() => openFile(
  acceptedTypeGroups: const [
    XTypeGroup(label: 'GPX', extensions: ['gpx']),
  ],
);

/// Opens an address in the phone's or computer's browser (the data export download). The real one is in app.dart.
typedef LinkOpener = Future<void> Function(Uri uri);

/// Sends the browser to the single sign-on provider. The real one is in app.dart; tests pass their own.
typedef SsoStarter = Future<void> Function();
