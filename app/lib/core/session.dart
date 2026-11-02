import 'package:flutter/foundation.dart';
import 'package:velomine_api/api.dart';

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
       server = ServerApi(client);

  final AccountsApi accounts;
  final RidesApi rides;
  final BikesApi bikes;
  final ServerApi server;
  final bool useCookies;
  final HttpBearerAuth bearer;

  /// The reason the server gave when single sign-on sent the browser back unsuccessfully (`?sso_error=...`).
  final String? ssoError;

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
    // Single sign-on goes through the browser and comes back to the web app. A phone build cannot be handed back
    // to yet, so only the web app offers it.
    try {
      sso = useCookies ? await accounts.getSsoInfo() : null;
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
