import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import 'app_sso.dart';
import 'hooks.dart';
import 'location_service.dart';
import 'server_config.dart';
import 'session.dart';
import 'session_auth.dart';
import 'telemetry.dart';
import 'telemetry_http_client.dart';
import 'token_store.dart';

part 'providers.g.dart';

/// Where the refresh token is kept. `main` overrides it with the platform store.
final tokenStoreProvider = Provider<TokenStore>(
  (ref) => throw UnimplementedError('main() provides the token store.'),
);

/// The session for the chosen server. A new address rebuilds it, and with it
/// every ViewModel that holds member data.
@Riverpod(keepAlive: true)
Session session(Ref ref) {
  final config = ref.watch(serverConfigViewModelProvider).value;
  final baseUrl = config?.baseUrl;
  if (baseUrl == null) {
    throw StateError('No server address is chosen.');
  }

  final telemetry = ref.watch(telemetryRuntimeProvider);
  final auth = SessionAuth(
    baseUrl: baseUrl,
    store: ref.watch(tokenStoreProvider),
    useCookies: kIsWeb,
    refreshClient: TelemetryHttpClient(
      inner: http.Client(),
      telemetry: telemetry,
    ),
  );
  final client = ApiClient(basePath: baseUrl, authentication: auth);
  final httpClient = TelemetryHttpClient(
    inner: client.client,
    telemetry: telemetry,
  );
  client.client = httpClient;
  final session = Session(
    client: client,
    auth: auth,
    appSso: createAppSso(),
    useCookies: kIsWeb,
    serverUrl: baseUrl,
    ssoError: Uri.base.queryParameters['sso_error'],
    telemetry: telemetry,
  );
  // One place ends the session on a 401, whichever call it was.
  httpClient.onUnauthorized = session.sessionExpired;
  unawaited(session.restore());
  ref.onDispose(session.dispose);
  return session;
}

/// The session's reactive state: status, member, server details and the reason
/// a sign-in did not work. It mirrors [Session.states] into Riverpod.
@Riverpod(keepAlive: true)
class SessionViewModel extends _$SessionViewModel {
  @override
  SessionState build() {
    final session = ref.watch(sessionProvider);
    final subscription = session.states.listen((next) {
      if (ref.mounted) state = next;
    });
    ref.onDispose(subscription.cancel);
    return session.snapshot;
  }
}

/// Who is signed in, or null. A ViewModel that holds member data watches this,
/// so signing out or switching account rebuilds it with empty state.
final signedInUserIdProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionViewModelProvider);
  return session.status == SessionStatus.signedIn ? session.me?.id : null;
});

/// Where the device says the rider is. Tests override it with a fixed position.
final locationServiceProvider = Provider<LocationService>(
  (ref) => const DeviceLocationService(),
);

/// Opens the ride file picker. Tests override it with a file that needs no disk.
final filePickerProvider = Provider<FilePicker>((ref) => pickRideFile);

/// Opens the picker for a Strava export archive. Tests override it like the ride one.
final importFilePickerProvider = Provider<FilePicker>(
  (ref) => pickStravaExport,
);

/// Opens the picker for a GPX file to turn into a club route. Tests override it too.
final gpxFilePickerProvider = Provider<FilePicker>((ref) => pickGpxFile);

/// How often an import is checked until the server has read the archive.
final importPollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 1),
);

/// How often an upload is checked until the server has read it. Tests shorten
/// it so they do not wait a second per poll.
final ridePollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 1),
);
