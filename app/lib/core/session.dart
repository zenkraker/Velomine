import 'dart:async';

import 'package:velomine_api/api.dart';

import 'pkce.dart';
import 'session_auth.dart';

enum SessionStatus { loading, signedOut, signedIn }

/// Why a sign-in or sign-up did not work, for the screens to explain.
enum AuthProblem {
  wrongPassword,
  notApproved,
  lockedOut,
  signUpClosed,
  weakPassword,
  emailTaken,
  unavailable,
}

/// The session fields a screen or the router reacts to.
class SessionState {
  const SessionState({
    required this.status,
    this.me,
    this.sso,
    this.serverInfo,
    this.restoreProblem,
    this.pendingJoinCode,
    this.ssoError,
  });

  final SessionStatus status;
  final MeResponse? me;
  final SsoInfoResponse? sso;
  final ServerInfoResponse? serverInfo;

  /// Set when a saved session could not be brought back because the server was
  /// unreachable.
  final AuthProblem? restoreProblem;

  final String? pendingJoinCode;
  final String? ssoError;

  bool get isAdmin => me?.roles.contains('admin') ?? false;
}

/// Who is signed in, and the calls that change that.
///
/// The web app keeps its session in a cookie the server sets (the browser sends it by itself). The phone app keeps
/// the refresh token in the platform's secure storage, so it can come back after a restart without the password.
///
/// The work is imperative and long-lived, so this is a plain repository object:
/// it emits [states] and Riverpod exposes that stream as [sessionViewModelProvider].
class Session {
  Session({
    required ApiClient client,
    required this.auth,
    required this.useCookies,
    required this.serverUrl,
    this.ssoError,
  }) : accounts = AccountsApi(client),
       rides = RidesApi(client),
       bikes = BikesApi(client),
       analytics = AnalyticsApi(client),
       admin = AdminApi(client),
       clubs = ClubApi(client),
       coach = ClubsApi(client),
       sharing = SharingApi(client),
       wellbeing = WellbeingApi(client),
       notifications = NotificationsApi(client),
       server = ServerApi(client) {
    auth.onSignedOut = sessionExpired;
  }

  final AccountsApi accounts;
  final RidesApi rides;
  final BikesApi bikes;
  final AnalyticsApi analytics;
  final AdminApi admin;
  final ClubApi clubs;

  /// The club-scoped endpoints a coach uses: athletes, their training and their rides.
  final ClubsApi coach;
  final SharingApi sharing;

  /// Check-ins, ride RPE and notes.
  final WellbeingApi wellbeing;
  final NotificationsApi notifications;
  final ServerApi server;
  final SessionAuth auth;
  final bool useCookies;

  /// The address this session belongs to, without a trailing slash.
  final String serverUrl;

  /// The reason single sign-on did not work: the server's `?sso_error=...` on the web, the same reason in the link
  /// the phone is handed back through. The sign-in screen explains it.
  String? ssoError;

  /// Clears that reason once the member tries to sign in again.
  void clearSsoError() {
    if (ssoError == null) return;
    ssoError = null;
    _notify();
  }

  /// Records why single sign-on came back without a session, so the sign-in
  /// screen can explain it.
  void reportSsoError(String reason) {
    ssoError = reason;
    _notify();
  }

  /// The secret of the sign-in the phone started in the browser; the code that comes back is only good with it.
  String? _ssoVerifier;

  /// A join code from an invite link, kept while a signed-out visitor signs in, so the link still works afterwards.
  String? pendingJoinCode;

  SessionStatus status = SessionStatus.loading;
  MeResponse? me;
  SsoInfoResponse? sso;
  ServerInfoResponse? serverInfo;

  /// Set when a saved session could not be brought back because the server was unreachable.
  AuthProblem? restoreProblem;

  bool _disposed = false;
  final _states = StreamController<SessionState>.broadcast(sync: true);

  /// Every change a screen, the router or a ViewModel reacts to.
  Stream<SessionState> get states => _states.stream;

  /// What [states] last emitted: the value a new listener starts from.
  SessionState get snapshot => SessionState(
    status: status,
    me: me,
    sso: sso,
    serverInfo: serverInfo,
    restoreProblem: restoreProblem,
    pendingJoinCode: pendingJoinCode,
    ssoError: ssoError,
  );

  bool get isAdmin => me?.roles.contains('admin') ?? false;

  void _notify() {
    if (!_disposed) _states.add(snapshot);
  }

  void dispose() {
    _disposed = true;
    unawaited(_states.close());
  }

  /// Called once at start: find out whether a session is saved, and whether SSO is offered.
  Future<void> restore() async {
    status = SessionStatus.loading;
    restoreProblem = null;
    _notify();

    try {
      serverInfo = await server.getServerInfo();
    } on Object {
      serverInfo = null; // no map background; everything else works
    }
    try {
      sso = await accounts.getSsoInfo();
    } on Object {
      sso = null;
    }

    if (useCookies) {
      await _restoreCookie();
    } else {
      await _restoreToken();
    }

    _notify();
  }

  /// Tries again after [restoreProblem] said the server was unreachable.
  Future<void> retryRestore() => restore();

  Future<void> _restoreCookie() async {
    try {
      me = await accounts.getMe();
      status = me == null ? SessionStatus.signedOut : SessionStatus.signedIn;
    } on ApiException {
      status = SessionStatus.signedOut;
    } on Object {
      status = SessionStatus.signedOut;
    }
  }

  Future<void> _restoreToken() async {
    final restored = await auth.restore();
    if (restored == SessionRestore.unavailable) {
      status = SessionStatus.signedOut;
      restoreProblem = AuthProblem.unavailable;
      return;
    }
    if (restored != SessionRestore.restored) {
      status = SessionStatus.signedOut;
      return;
    }

    try {
      me = await accounts.getMe();
      status = me == null ? SessionStatus.signedOut : SessionStatus.signedIn;
    } on ApiException catch (e) {
      if (e.code == 401) {
        await auth.clear();
      } else {
        restoreProblem = AuthProblem.unavailable;
      }
      status = SessionStatus.signedOut;
    } on Object {
      restoreProblem = AuthProblem.unavailable;
      status = SessionStatus.signedOut;
    }
  }

  /// The address to open in the phone's browser to sign in with single sign-on. The browser ends up on the app's own
  /// link (`com.velomine.app:/sso-callback?code=...`), which [finishAppSso] turns into a session.
  Uri appSsoUrl() {
    final pkce = Pkce.generate();
    _ssoVerifier = pkce.verifier;
    return Uri.parse('$serverUrl/api/v1/accounts/sso/login')
        .replace(queryParameters: {'codeChallenge': pkce.challenge});
  }

  /// Trades the one-time code from the browser for a session. Returns null on success, or the reason in the same
  /// words as `?sso_error=`.
  Future<String?> finishAppSso(String code) async {
    final verifier = _ssoVerifier;
    _ssoVerifier = null; // a code is good once
    if (verifier == null) return 'failed'; // the app was closed while the browser was open: start again

    TokenResponse? token;
    try {
      token = await accounts.exchangeSsoCode(
        ExchangeSsoCodeRequest(code: code, codeVerifier: verifier),
      );
    } on Object {
      return 'failed';
    }
    if (token == null) return 'failed';

    await auth.accept(token);
    try {
      me = await accounts.getMe();
    } on ApiException catch (e) {
      if (e.code == 401) {
        await auth.clear();
        return 'failed';
      }
    } on Object {
      // The token is good; the next screen will read the member again.
    }

    status = SessionStatus.signedIn;
    _notify();
    return null;
  }

  /// Saves the chosen language on the account so every device follows it. Null means "follow the device".
  Future<void> setLanguage(String? language) async {
    try {
      me =
          await accounts.setMyLanguage(
            SetMyLanguageRequest(language: Optional.present(language)),
          ) ??
          me;
      _notify();
    } on Object {
      // The local choice still applies; the next sign-in or change tries again.
    }
  }

  /// Reads the signed-in member again, after they changed something shown elsewhere (their name).
  Future<void> refreshMe() async {
    try {
      me = await accounts.getMe() ?? me;
      _notify();
    } on Object {
      // Keeps the name it had; the next start reads it again.
    }
  }

  /// Returns null on success, or the reason it failed.
  Future<AuthProblem?> signIn(String email, String password) async {
    restoreProblem = null;

    TokenResponse? token;
    try {
      token = await accounts.login(
        LoginRequest(
          email: email,
          password: password,
          useCookies: Optional.present(useCookies),
        ),
      );
    } on ApiException catch (e) {
      if (e.code == 401) {
        await auth.clear();
        return AuthProblem.wrongPassword;
      }
      return switch (e.code) {
        403 => AuthProblem.notApproved,
        423 => AuthProblem.lockedOut,
        _ => AuthProblem.unavailable,
      };
    } on Object {
      return AuthProblem.unavailable;
    }

    if (!useCookies) {
      if (token == null) return AuthProblem.unavailable;
      await auth.accept(token);
    }

    try {
      me = await accounts.getMe();
    } on ApiException catch (e) {
      if (e.code == 401) await auth.clear();
      return AuthProblem.unavailable;
    } on Object {
      // The login succeeded; the next call will read the member again.
      return AuthProblem.unavailable;
    }

    status = SessionStatus.signedIn;
    _notify();
    return null;
  }

  /// Returns null on success. [approved] says whether the new account can sign in right away.
  Future<({AuthProblem? problem, bool approved})> signUp(
    String email,
    String displayName,
    String password,
  ) async {
    try {
      final created = await accounts.register(
        RegisterRequest(
          email: email,
          displayName: displayName,
          password: password,
        ),
      );
      return (problem: null, approved: created?.isApproved ?? false);
    } on ApiException catch (e) {
      final problem = switch (e.code) {
        403 => AuthProblem.signUpClosed,
        400 =>
          e.message?.contains('already') ?? false
              ? AuthProblem.emailTaken
              : AuthProblem.weakPassword,
        _ => AuthProblem.unavailable,
      };
      return (problem: problem, approved: false);
    } on Object {
      return (problem: AuthProblem.unavailable, approved: false);
    }
  }

  Future<void> signOut() async {
    try {
      if (useCookies) await accounts.logout();
    } on Object {
      // The session is dropped on this side either way.
    }
    await auth.clear();
    me = null;
    status = SessionStatus.signedOut;
    restoreProblem = null;
    _notify();
  }

  /// A call came back 401: the session ended (expired token, revoked token or cookie). Back to the sign-in screen.
  void sessionExpired() {
    if (status != SessionStatus.signedIn) return;
    unawaited(auth.clear());
    me = null;
    status = SessionStatus.signedOut;
    _notify();
  }
}
