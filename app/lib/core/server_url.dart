/// A server address fixed at build time, for development: `--dart-define=VELOMINE_URL=...`.
/// Empty when the build does not set one; on a phone the member enters the address instead.
String configuredServerUrl() => const String.fromEnvironment('VELOMINE_URL');
