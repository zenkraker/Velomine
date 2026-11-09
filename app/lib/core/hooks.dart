import 'package:file_selector/file_selector.dart';

/// Opens the ride file picker. The real one is in app.dart; tests pass their own.
typedef FilePicker = Future<XFile?> Function();

/// The real ride file picker: FIT, GPX, TCX or a gzipped one.
Future<XFile?> pickRideFile() => openFile(
  acceptedTypeGroups: const [
    XTypeGroup(label: 'Rides', extensions: ['fit', 'gpx', 'tcx', 'gz']),
  ],
);

/// Opens an address in the phone's or computer's browser (the data export download). The real one is in app.dart.
typedef LinkOpener = Future<void> Function(Uri uri);

/// Sends the browser to the single sign-on provider. The real one is in app.dart; tests pass their own.
typedef SsoStarter = Future<void> Function();
