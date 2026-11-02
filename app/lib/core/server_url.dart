import 'package:flutter/foundation.dart';

/// Where the Velomine server is.
///
/// The web app is served by the server itself, so it uses its own address and the browser's cookies work.
/// Other builds take the address from `--dart-define=VELOMINE_URL=https://your-server`.
String serverUrl() {
  const configured = String.fromEnvironment('VELOMINE_URL');
  if (configured.isNotEmpty) return configured;
  return kIsWeb ? Uri.base.origin : 'http://localhost:8080';
}
