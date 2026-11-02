import 'package:file_selector/file_selector.dart';

/// Opens the ride file picker. The real one is in app.dart; tests pass their own.
typedef FilePicker = Future<XFile?> Function();

/// Sends the browser to the single sign-on provider. The real one is in app.dart; tests pass their own.
typedef SsoStarter = Future<void> Function();
