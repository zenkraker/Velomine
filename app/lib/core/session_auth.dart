import 'package:http/http.dart' as http;
import 'package:velomine_api/api.dart';

import 'token_store.dart';

/// What happened when the app tried to bring back a saved session.
enum SessionRestore {
  /// A new access token was obtained; the member is signed in.
  restored,

  /// There is no saved session, or the server refused it.
  signedOut,

  /// The server could not be reached. The refresh token is kept for the next try.
  unavailable,
}

/// The refresh token could not be exchanged because the server is unreachable.
/// The request is stopped instead of being sent without a token.
class SessionUnavailable implements Exception {
  const SessionUnavailable();

  @override
  String toString() => 'The server could not be reached.';
}

/// Applies the bearer token to requests for the phone app, refreshing it first when it is about to expire.
///
/// The refresh endpoint is called through a separate [ApiClient] without authentication, so refreshing can never
/// recurse. It is single-flight: several requests that notice the expiry at the same time wait for one refresh.
class SessionAuth implements Authentication {
  SessionAuth({
    required this.baseUrl,
    required this.store,
    required this.useCookies,
    this.refreshClient,
    this.onSignedOut,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final String baseUrl;
  final TokenStore store;
  final bool useCookies;

  /// Tests pass the fake server's client; null means a new HTTP client.
  final http.Client? refreshClient;

  /// Called when the server refuses the refresh token. The session then ends.
  void Function()? onSignedOut;

  final DateTime Function() _now;

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;
  Future<bool>? _refreshing;
  bool _lastRefreshUnavailable = false;

  String? get accessToken => _accessToken;

  @override
  Future<void> applyToParams(
    List<QueryParam> queryParams,
    Map<String, String> headerParams,
  ) async {
    if (useCookies) return;

    if (_needsRefresh) {
      if (_refreshToken == null) return; // signing in: no token yet
      final refreshed = await _refresh();
      if (!refreshed) {
        // The server refused it: let the request go unauthenticated and end the session.
        // It could not be reached: stop here, so the request is not mistaken for a signed-out one.
        if (_lastRefreshUnavailable) throw const SessionUnavailable();
        return;
      }
    }

    final token = _accessToken;
    if (token != null && token.isNotEmpty) {
      headerParams['Authorization'] = 'Bearer $token';
    }
  }

  Future<SessionRestore> restore() async {
    if (useCookies) return SessionRestore.signedOut;

    final saved = await store.readRefreshToken();
    if (saved == null || saved.isEmpty) return SessionRestore.signedOut;

    _refreshToken = saved;
    final refreshed = await _refresh();
    if (refreshed) return SessionRestore.restored;
    return _lastRefreshUnavailable
        ? SessionRestore.unavailable
        : SessionRestore.signedOut;
  }

  /// Takes the token pair from login or single sign-on and keeps the refresh token for the next start.
  /// With [persist] false the token stays in memory only, so closing the app asks for the password again.
  Future<void> accept(TokenResponse token, {bool persist = true}) async {
    _accessToken = token.accessToken;
    _refreshToken = token.refreshToken;
    _expiresAt = _now().add(Duration(seconds: token.expiresIn));
    try {
      if (persist) {
        await store.writeRefreshToken(token.refreshToken);
      } else {
        // A token from an earlier "stay logged in" sign-in must not bring back the old session.
        await store.clear();
      }
    } on Object {
      // The session still works until the app closes; the next start asks to sign in again.
    }
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    try {
      await store.clear();
    } on Object {
      // Nothing else to do.
    }
  }

  bool get _needsRefresh {
    if (_accessToken == null) return true;
    final expiresAt = _expiresAt;
    return expiresAt == null ||
        !_now().isBefore(expiresAt.subtract(const Duration(seconds: 30)));
  }

  Future<bool> _refresh() {
    final running = _refreshing;
    if (running != null) return running;

    final future = _doRefresh();
    _refreshing = future;
    future.whenComplete(() {
      if (identical(_refreshing, future)) _refreshing = null;
    });
    return future;
  }

  Future<bool> _doRefresh() => store.locked(_refreshNow);

  Future<bool> _refreshNow() async {
    // The background upload worker rotates the same token file; use whatever is stored now, so a token it just
    // renewed is not presented again as stolen.
    final saved = await store.readRefreshToken();
    if (saved != null && saved.isNotEmpty) _refreshToken = saved;
    final refreshToken = _refreshToken;
    if (refreshToken == null) return false;

    _lastRefreshUnavailable = false;
    try {
      final client = ApiClient(basePath: baseUrl);
      if (refreshClient != null) client.client = refreshClient!;
      final token = await AccountsApi(client)
          .refresh(RefreshRequest(refreshToken: refreshToken));

      if (token == null) {
        _lastRefreshUnavailable = true;
        return false;
      }

      await accept(token);
      return true;
    } on ApiException catch (e) {
      if (e.code == 401) {
        await clear();
        onSignedOut?.call();
      } else {
        _lastRefreshUnavailable = true;
      }
      return false;
    } on Object {
      _lastRefreshUnavailable = true;
      return false;
    }
  }
}
