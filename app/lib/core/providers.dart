import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import 'hooks.dart';
import 'location_service.dart';
import 'server_config.dart';
import 'session.dart';
import 'session_auth.dart';
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

  final auth = SessionAuth(
    baseUrl: baseUrl,
    store: ref.watch(tokenStoreProvider),
    useCookies: kIsWeb,
  );
  final client = ApiClient(basePath: baseUrl, authentication: auth);
  final session = Session(
    client: client,
    auth: auth,
    useCookies: kIsWeb,
    serverUrl: baseUrl,
    ssoError: Uri.base.queryParameters['sso_error'],
  );
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

/// How often an upload is checked until the server has read it. Tests shorten
/// it so they do not wait a second per poll.
final ridePollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 1),
);
