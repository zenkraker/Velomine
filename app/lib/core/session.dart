import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:velomine_api/api.dart';

import 'app_sso.dart';
import 'session_auth.dart';
import 'telemetry.dart';

enum SessionStatus { loading, signedOut, signedIn }

/// Why a sign-in or sign-up did not work, for the screens to explain.
enum AuthProblem {
  wrongPassword,
  wrongCode,
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
    required this.appSso,
    required this.useCookies,
    required this.serverUrl,
    required this.telemetry,
    this.ssoError,
  }) : accounts = AccountsApi(client),
       rides = RidesApi(client),
       bikes = BikesApi(client),
       analytics = AnalyticsApi(client),
       admin = AdminApi(client),
       clubs = ClubApi(client),
       coach = ClubsApi(client),
       sharing = SharingApi(client),
       privacy = PrivacyApi(client),
       wellbeing = WellbeingApi(client),
       notifications = NotificationsApi(client),
       routes = RoutesApi(client),
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

  /// The member's own privacy choices: stream switches, trimming and saved zones.
  final PrivacyApi privacy;

  /// Check-ins, ride RPE and notes.
  final WellbeingApi wellbeing;
  final NotificationsApi notifications;

  /// The club's route library and the draft of a ride's line.
  final RoutesApi routes;
  final ServerApi server;
  final SessionAuth auth;
  final AppSso appSso;
  final bool useCookies;
  final TelemetryRuntime telemetry;

  /// The address this session belongs to, without a trailing slash.
  final String serverUrl;

  /// The reason single sign-on did not work: the server's `?sso_error=...` on the web, or the code the phone's
  /// exchange returned. The sign-in screen explains it.
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

    telemetry.count(
      'session_restore',
      1,
      attributes: {
        'result': switch (status) {
          SessionStatus.signedIn => 'signed_in',
          SessionStatus.signedOut =>
            restoreProblem == null ? 'signed_out' : 'unavailable',
          SessionStatus.loading => 'loading',
        },
      },
    );
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

  /// Signs in directly against the provider as a public client, then exchanges its ID token for Velomine tokens.
  Future<void> signInWithSso() async {
    await _signInWithSso();
    final success = status == SessionStatus.signedIn;
    final result = success
        ? 'success'
        : ssoError == null
        ? 'cancelled'
        : 'failed';
    telemetry.count(
      'sso_sign_in',
      1,
      attributes: {'result': result, 'reason': ?ssoError},
    );
    if (success) {
      telemetry.log(TelemetryLevel.info, 'sso sign-in succeeded');
    } else if (result == 'failed') {
      telemetry.log(
        TelemetryLevel.warning,
        'sso sign-in failed',
        attributes: {'reason': ssoError ?? 'unknown'},
      );
    }
  }

  Future<void> _signInWithSso() async {
    final info = sso;
    if (info == null ||
        !info.appSsoEnabled ||
        info.appAuthority == null ||
        info.appClientId == null ||
        info.appRedirectUri == null) {
      reportSsoError('failed');
      return;
    }

    clearSsoError();
    final AppSsoResult result;
    try {
      result = await appSso.signIn(
        AppSsoConfig(
          authority: info.appAuthority!,
          clientId: info.appClientId!,
          redirectUri: info.appRedirectUri!,
          scopes: info.appScopes,
        ),
      );
    } on Object {
      reportSsoError('failed');
      return;
    }
    if (result.outcome == AppSsoOutcome.cancelled) return;
    final idToken = result.idToken;
    if (result.outcome != AppSsoOutcome.success || idToken == null) {
      reportSsoError('failed');
      return;
    }

    TokenResponse? token;
    try {
      token = await accounts.exchangeSsoToken(
        ExchangeSsoTokenRequest(
          idToken: idToken,
          accessToken: result.accessToken,
          deviceLabel: Optional.present(_deviceLabel),
        ),
      );
    } on ApiException catch (e) {
      reportSsoError(_ssoErrorCode(e) ?? 'failed');
      return;
    } on Object {
      reportSsoError('failed');
      return;
    }
    if (token == null) {
      reportSsoError('failed');
      return;
    }

    await auth.accept(token);
    try {
      me = await accounts.getMe();
    } on ApiException catch (e) {
      if (e.code == 401) {
        await auth.clear();
        reportSsoError('failed');
        return;
      }
    } on Object {
      // The token is good; the next screen will read the member again.
    }

    status = SessionStatus.signedIn;
    _notify();
  }

  /// The server's `{ "error": "..." }` body, so the screen shows the same words as the web callback.
  static String? _ssoErrorCode(ApiException error) {
    final body = error.message;
    if (body == null || body.isEmpty) return null;
    try {
      final json = jsonDecode(body);
      return json is Map && json['error'] is String
          ? json['error'] as String
          : null;
    } on FormatException {
      return null;
    }
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

  /// Saves the chosen units on the account so every device follows them.
  Future<void> setUnits(String units) async {
    try {
      me = await accounts.setMyUnits(SetMyUnitsRequest(units: units)) ?? me;
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

  /// Returns null on success, or the reason it failed. A non-null challenge means the account has a second factor:
  /// the screen asks for the code and calls [completeTwoFactor].
  Future<({AuthProblem? problem, String? challenge})> signIn(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    final result = await _signIn(email, password, rememberMe: rememberMe);
    final problem = result.problem;
    final resultName =
        problem?.name ?? (result.challenge == null ? 'success' : 'two_factor');
    telemetry.count('sign_in', 1, attributes: {'result': resultName});
    if (problem == null) {
      telemetry.log(
        TelemetryLevel.info,
        result.challenge == null
            ? 'sign-in succeeded'
            : 'sign-in needs a second factor',
      );
    } else {
      telemetry.log(
        TelemetryLevel.warning,
        'sign-in failed',
        attributes: {'reason': problem.name},
      );
    }
    return result;
  }

  Future<({AuthProblem? problem, String? challenge})> _signIn(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    // Keys and autofill can add a space at either end; it must not decide whether
    // an account matches.
    email = email.trim();
    password = password.trim();
    restoreProblem = null;

    late final int statusCode;
    String? challenge;
    TokenResponse? token;
    try {
      final response = await accounts.loginWithHttpInfo(
        LoginRequest(
          email: email,
          password: password,
          useCookies: Optional.present(useCookies),
          rememberMe: Optional.present(rememberMe),
          deviceLabel: Optional.present(_deviceLabel),
        ),
      );
      statusCode = response.statusCode;
      if (statusCode == 202) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        challenge = body['challenge'] as String?;
      } else if (statusCode < 400 && response.body.isNotEmpty) {
        token = TokenResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
    } on Object {
      return (problem: AuthProblem.unavailable, challenge: null);
    }

    if (challenge != null) {
      return (problem: null, challenge: challenge);
    }

    // A 202 without a challenge would otherwise look like a successful sign-in with no session.
    if (statusCode == 202) {
      return (problem: AuthProblem.unavailable, challenge: null);
    }

    if (statusCode >= 400) {
      if (statusCode == 401) await auth.clear();
      return (
        problem: switch (statusCode) {
          401 => AuthProblem.wrongPassword,
          403 => AuthProblem.notApproved,
          423 => AuthProblem.lockedOut,
          _ => AuthProblem.unavailable,
        },
        challenge: null,
      );
    }

    if (!useCookies) {
      if (token == null) {
        return (problem: AuthProblem.unavailable, challenge: null);
      }
      await auth.accept(token, persist: rememberMe);
    }

    final problem = await _finishSignIn();
    return (problem: problem, challenge: null);
  }

  /// The second step: the challenge from [signIn] and the code from the authenticator app, or a recovery code.
  Future<AuthProblem?> completeTwoFactor(
    String challenge,
    String code, {
    bool rememberMe = true,
  }) async {
    final problem = await _completeTwoFactor(
      challenge,
      code,
      rememberMe: rememberMe,
    );
    telemetry.count(
      'sign_in_two_factor',
      1,
      attributes: {'result': problem?.name ?? 'success'},
    );
    if (problem == null) {
      telemetry.log(TelemetryLevel.info, 'two-factor sign-in succeeded');
    } else {
      telemetry.log(
        TelemetryLevel.warning,
        'two-factor sign-in failed',
        attributes: {'reason': problem.name},
      );
    }
    return problem;
  }

  Future<AuthProblem?> _completeTwoFactor(
    String challenge,
    String code, {
    bool rememberMe = true,
  }) async {
    try {
      final response = await accounts.loginTwoFactorWithHttpInfo(
        LoginTwoFactorRequest(
          challenge: challenge,
          code: code.trim(),
          useCookies: Optional.present(useCookies),
          rememberMe: Optional.present(rememberMe),
          deviceLabel: Optional.present(_deviceLabel),
        ),
      );

      if (response.statusCode >= 400) {
        if (response.statusCode == 401) await auth.clear();
        return switch (response.statusCode) {
          401 => AuthProblem.wrongCode,
          403 => AuthProblem.notApproved,
          423 => AuthProblem.lockedOut,
          _ => AuthProblem.unavailable,
        };
      }

      if (!useCookies) {
        if (response.body.isEmpty) return AuthProblem.unavailable;
        final token = TokenResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        if (token == null) return AuthProblem.unavailable;
        await auth.accept(token, persist: rememberMe);
      }

      return await _finishSignIn();
    } on Object {
      return AuthProblem.unavailable;
    }
  }

  /// Reads the member after the server accepted the sign-in.
  Future<AuthProblem?> _finishSignIn() async {
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

  /// A label the session list can show, without asking the platform for a model name.
  String get _deviceLabel {
    if (kIsWeb) return 'Web app';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android app',
      TargetPlatform.iOS => 'iPhone app',
      TargetPlatform.macOS => 'Mac app',
      TargetPlatform.windows => 'Windows app',
      TargetPlatform.linux => 'Linux app',
      _ => 'App',
    };
  }

  /// Returns null on success. [approved] says whether the new account can sign in right away.
  Future<({AuthProblem? problem, bool approved})> signUp(
    String email,
    String displayName,
    String password,
  ) async {
    final result = await _signUp(email, displayName, password);
    final problem = result.problem;
    telemetry.count(
      'sign_up',
      1,
      attributes: {
        'result': problem?.name ?? 'success',
        'approved': result.approved,
      },
    );
    if (problem == null) {
      telemetry.log(TelemetryLevel.info, 'sign-up succeeded');
    } else {
      telemetry.log(
        TelemetryLevel.warning,
        'sign-up failed',
        attributes: {'reason': problem.name},
      );
    }
    return result;
  }

  Future<({AuthProblem? problem, bool approved})> _signUp(
    String email,
    String displayName,
    String password,
  ) async {
    email = email.trim();
    displayName = displayName.trim();
    password = password.trim();
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
      // Ending the session on the server also removes it from the member's device list; a token on its own would
      // simply expire.
      await accounts.logout();
    } on Object {
      // The session is dropped on this side either way.
    }
    await auth.clear();
    me = null;
    status = SessionStatus.signedOut;
    restoreProblem = null;
    // Report before the app closes the SDK for the signed-out state.
    telemetry.count('sign_out', 1);
    telemetry.log(TelemetryLevel.info, 'signed out');
    _notify();
  }

  /// A call came back 401: the session ended (expired token, revoked token or cookie). Back to the sign-in screen.
  void sessionExpired() {
    if (status != SessionStatus.signedIn) return;
    unawaited(auth.clear());
    me = null;
    status = SessionStatus.signedOut;
    telemetry.count('session_expired', 1);
    _notify();
  }
}
