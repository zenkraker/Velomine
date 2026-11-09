import 'app_sso_stub.dart' if (dart.library.io) 'app_sso_io.dart';

enum AppSsoOutcome { success, cancelled, failed }

/// What the server told the phone to use for a direct OpenID Connect sign-in.
class AppSsoConfig {
  const AppSsoConfig({
    required this.authority,
    required this.clientId,
    required this.redirectUri,
    required this.scopes,
  });

  final String authority;
  final String clientId;
  final String redirectUri;
  final List<String> scopes;

  bool get allowInsecureConnections => authority.startsWith('http://');

  String get discoveryUrl =>
      '${authority.replaceFirst(RegExp(r'/$'), '')}/.well-known/openid-configuration';
}

/// The provider tokens the app must hand to the server; the server is the trust boundary and issues Velomine tokens.
class AppSsoResult {
  const AppSsoResult.success({required this.idToken, this.accessToken})
    : outcome = AppSsoOutcome.success;

  const AppSsoResult.cancelled()
    : outcome = AppSsoOutcome.cancelled,
      idToken = null,
      accessToken = null;

  const AppSsoResult.failed()
    : outcome = AppSsoOutcome.failed,
      idToken = null,
      accessToken = null;

  final AppSsoOutcome outcome;
  final String? idToken;
  final String? accessToken;
}

abstract interface class AppSso {
  Future<AppSsoResult> signIn(AppSsoConfig config);
}

AppSso createAppSso() => createPlatformAppSso();
