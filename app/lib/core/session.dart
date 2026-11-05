import 'package:flutter/foundation.dart';
import 'package:velomine_api/api.dart';

import 'pkce.dart';

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

/// Who is signed in, and the calls that change that.
///
/// The web app keeps its session in a cookie the server sets (the browser sends it by itself). Other builds hold the
/// bearer token in memory only for now, so they sign in again after a restart.
class Session extends ChangeNotifier {
  Session({
    required ApiClient client,
    required this.bearer,
    required this.useCookies,
    this.ssoError,
  }) : accounts = AccountsApi(client),
       rides = RidesApi(client),
       bikes = BikesApi(client),
       analytics = AnalyticsApi(client),
       notifications = NotificationsApi(client),
       server = ServerApi(client);

  final AccountsApi accounts;
  final RidesApi rides;
  final BikesApi bikes;
  final AnalyticsApi analytics;
  final NotificationsApi notifications;
  final ServerApi server;
  final bool useCookies;
  final HttpBearerAuth bearer;

  /// The reason single sign-on did not work: the server's `?sso_error=...` on the web, the same reason in the link
  /// the phone is handed back through. The sign-in screen explains it.
  String? ssoError;

  /// The secret of the sign-in the phone started in the browser; the code that comes back is only good with it.
  String? _ssoVerifier;

  SessionStatus status = SessionStatus.loading;
  MeResponse? me;
  SsoInfoResponse? sso;
  ServerInfoResponse? serverInfo;

  bool get isAdmin => me?.roles.contains('admin') ?? false;

  /// Called once at start: find out whether the cookie already holds a session, and whether SSO is offered.
  Future<void> restore() async {
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
    try {
      me = await accounts.getMe();
      status = me == null ? SessionStatus.signedOut : SessionStatus.signedIn;
    } on ApiException {
      status = SessionStatus.signedOut;
    } on Object {
      status = SessionStatus.signedOut;
    }
    notifyListeners();
  }

  /// The address to open in the phone's browser to sign in with single sign-on. The browser ends up on the app's own
  /// link (`com.velomine.app:/sso-callback?code=...`), which [finishAppSso] turns into a session.
  Uri appSsoUrl(String server) {
    final pkce = Pkce.generate();
    _ssoVerifier = pkce.verifier;
    return Uri.parse('$server/api/v1/accounts/sso/login')
        .replace(queryParameters: {'codeChallenge': pkce.challenge});
  }

  /// Trades the one-time code from the browser for a session. Returns null on success, or the reason in the same
  /// words as `?sso_error=`.
  Future<String?> finishAppSso(String code) async {
    final verifier = _ssoVerifier;
    _ssoVerifier = null; // a code is good once
    if (verifier == null) return 'failed'; // the app was closed while the browser was open: start again
    try {
      final token = await accounts.exchangeSsoCode(
        ExchangeSsoCodeRequest(code: code, codeVerifier: verifier),
      );
      bearer.accessToken = token?.accessToken ?? '';
      me = await accounts.getMe();
      status = SessionStatus.signedIn;
      notifyListeners();
      return null;
    } on Object {
      bearer.accessToken = '';
      return 'failed';
    }
  }

  /// Reads the signed-in member again, after they changed something shown elsewhere (their name).
  Future<void> refreshMe() async {
    try {
      me = await accounts.getMe() ?? me;
      notifyListeners();
    } on Object {
      // Keeps the name it had; the next start reads it again.
    }
  }

  /// Returns null on success, or the reason it failed.
  Future<AuthProblem?> signIn(String email, String password) async {
    try {
      final token = await accounts.login(
        LoginRequest(
          email: email,
          password: password,
          useCookies: Optional.present(useCookies),
        ),
      );
      if (!useCookies) bearer.accessToken = token?.accessToken ?? '';
      me = await accounts.getMe();
      status = SessionStatus.signedIn;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return switch (e.code) {
        403 => AuthProblem.notApproved,
        423 => AuthProblem.lockedOut,
        401 => AuthProblem.wrongPassword,
        _ => AuthProblem.unavailable,
      };
    } on Object {
      return AuthProblem.unavailable;
    }
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
    bearer.accessToken = '';
    me = null;
    status = SessionStatus.signedOut;
    notifyListeners();
  }

  /// A call came back 401: the session ended (expired token or cookie). Back to the sign-in screen.
  void sessionExpired() {
    if (status != SessionStatus.signedIn) return;
    bearer.accessToken = '';
    me = null;
    status = SessionStatus.signedOut;
    notifyListeners();
  }
}
