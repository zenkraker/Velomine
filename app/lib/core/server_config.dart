import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'server_url.dart';

part 'server_config.g.dart';

/// The chosen address, and the last one so the setup screen can prefill it.
typedef ServerConfigState = ({String? baseUrl, String? previousUrl});

/// Where the address is kept. Tests override it with an in-memory store.
final serverConfigStoreProvider = Provider<ServerConfigStore>(
  (ref) => PreferencesServerConfigStore(),
);

/// Whether this build runs as the web app. Tests override it.
final isWebProvider = Provider<bool>((ref) => kIsWeb);

/// The origin the browser serves the web app from. Tests override it.
final webOriginProvider = Provider<String?>((ref) => null);

/// Where this phone's Velomine server is, kept on the device so it is asked for
/// once. The web app is served by the server itself, so it always uses its own
/// origin and never shows a setup screen.
@Riverpod(keepAlive: true)
class ServerConfigViewModel extends _$ServerConfigViewModel {
  @override
  Future<ServerConfigState> build() async {
    if (ref.watch(isWebProvider)) {
      return (
        baseUrl: ref.watch(webOriginProvider) ?? Uri.base.origin,
        previousUrl: null,
      );
    }

    final saved = await ref.watch(serverConfigStoreProvider).read();
    final normalized = saved == null ? null : normalizeServerUrl(saved);
    if (normalized != null) {
      return (baseUrl: normalized, previousUrl: null);
    }

    // A development build may point at one server without asking.
    return (
      baseUrl: normalizeServerUrl(configuredServerUrl()),
      previousUrl: null,
    );
  }

  Future<void> save(String url) async {
    final normalized = normalizeServerUrl(url);
    if (normalized == null) {
      throw ArgumentError.value(url, 'url', 'Not a server address.');
    }
    state = AsyncData((baseUrl: normalized, previousUrl: state.value?.baseUrl));
    await ref.read(serverConfigStoreProvider).write(normalized);
  }

  Future<void> clear() async {
    state = AsyncData((baseUrl: null, previousUrl: state.value?.baseUrl));
    await ref.read(serverConfigStoreProvider).write(null);
  }
}

/// What to put in the setup field before the member types anything.
String suggestedServerUrl() => configuredServerUrl().isNotEmpty
    ? normalizeServerUrl(configuredServerUrl()) ?? ''
    : (kDebugMode ? 'http://localhost:8080' : '');

/// Where the address is kept. Tests pass one in memory.
abstract interface class ServerConfigStore {
  Future<String?> read();

  Future<void> write(String? value);
}

class PreferencesServerConfigStore implements ServerConfigStore {
  static const _key = 'serverUrl';
  final _prefs = SharedPreferencesAsync();

  @override
  Future<String?> read() async {
    try {
      return await _prefs.getString(_key);
    } on Object {
      return null; // no storage available: ask again next time
    }
  }

  @override
  Future<void> write(String? value) async {
    try {
      if (value == null) {
        await _prefs.remove(_key);
      } else {
        await _prefs.setString(_key, value);
      }
    } on Object {
      // Not kept; the address still works until the app closes.
    }
  }
}

/// Checks and tidies an address the member typed. Returns null when it cannot be a server address.
///
/// The API lives under `/api/v1`, so a pasted API address is accepted too and the suffix is removed.
String? normalizeServerUrl(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri == null ||
      !uri.hasScheme ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    return null;
  }

  var path = uri.path;
  while (path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  if (path.endsWith('/api/v1')) {
    path = path.substring(0, path.length - '/api/v1'.length);
  }

  return uri.replace(path: path).toString();
}
