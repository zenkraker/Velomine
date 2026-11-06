import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'server_url.dart';

/// Where this phone's Velomine server is, kept on the device so it is asked for once.
///
/// The web app is served by the server itself, so it always uses its own origin and never shows a setup screen.
class ServerConfig extends ChangeNotifier {
  ServerConfig({ServerConfigStore? store, bool? web, this.webOrigin})
    : _store = store ?? _Preferences(),
      _web = web ?? kIsWeb;

  final ServerConfigStore _store;
  final bool _web;

  /// Tests use this instead of the browser's own origin.
  final String? webOrigin;

  String? _baseUrl;
  String? _previousUrl;

  /// The server address without a trailing slash, or null until one is chosen on a phone.
  String? get baseUrl => _baseUrl;

  /// The last address, kept only so the setup screen can prefill it after "Change server".
  String? get previousUrl => _previousUrl;

  /// What to put in the setup field before the member types anything.
  String get suggestedUrl => configuredServerUrl().isNotEmpty
      ? normalizeServerUrl(configuredServerUrl()) ?? ''
      : (kDebugMode ? 'http://localhost:8080' : '');

  Future<void> load() async {
    if (_web) {
      _baseUrl = webOrigin ?? Uri.base.origin;
      return;
    }

    final saved = await _store.read();
    final normalized = saved == null ? null : normalizeServerUrl(saved);
    if (normalized != null) {
      _baseUrl = normalized;
      return;
    }

    // A development build may point at one server without asking.
    final configured = normalizeServerUrl(configuredServerUrl());
    if (configured != null) _baseUrl = configured;
  }

  Future<void> save(String url) async {
    final normalized = normalizeServerUrl(url);
    if (normalized == null) {
      throw ArgumentError.value(url, 'url', 'Not a server address.');
    }
    _baseUrl = normalized;
    notifyListeners();
    await _store.write(normalized);
  }

  Future<void> clear() async {
    _previousUrl = _baseUrl;
    _baseUrl = null;
    notifyListeners();
    await _store.write(null);
  }
}

/// Where the address is kept. Tests pass one in memory.
abstract interface class ServerConfigStore {
  Future<String?> read();

  Future<void> write(String? value);
}

class _Preferences implements ServerConfigStore {
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
