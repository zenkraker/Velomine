import 'drop_source_stub.dart' if (dart.library.js_interop) 'drop_source_web.dart';
import 'ride_file.dart';

/// Where ride files come from on the web: dragged onto the page, or chosen with a button.
///
/// The phone builds get a source that supports nothing, so none of the browser code is reachable from them.
abstract interface class DropSource {
  /// False on the phone: the buttons and the drop target are not shown.
  bool get supported;

  /// True while files are being dragged over the page.
  Stream<bool> get dragging;

  /// One event per drop. The future completes once a dropped folder has been walked to the bottom.
  Stream<Future<List<RideFileEntry>>> get drops;

  /// Opens the browser's folder chooser. Call it straight from a button press: browsers allow it only then.
  /// Completes with no files when the member closes the chooser.
  Future<List<RideFileEntry>> pickFolder();

  /// Opens the browser's file chooser, for several files. Same rule as [pickFolder].
  Future<List<RideFileEntry>> pickFiles();

  void dispose();
}

DropSource createDropSource() => createPlatformDropSource();
