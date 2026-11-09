import 'package:flutter_appauth/flutter_appauth.dart';

import 'app_sso.dart';

AppSso createPlatformAppSso() => FlutterAppSso();

class FlutterAppSso implements AppSso {
  @override
  Future<AppSsoResult> signIn(AppSsoConfig config) async {
    try {
      final response = await FlutterAppAuth().authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          config.clientId,
          config.redirectUri,
          discoveryUrl: config.discoveryUrl,
          scopes: config.scopes,
          allowInsecureConnections: config.allowInsecureConnections,
        ),
      );
      final idToken = response.idToken;
      if (idToken == null || idToken.isEmpty) {
        return const AppSsoResult.failed();
      }
      return AppSsoResult.success(
        idToken: idToken,
        accessToken: response.accessToken,
      );
    } on FlutterAppAuthUserCancelledException {
      return const AppSsoResult.cancelled();
    } on Object {
      return const AppSsoResult.failed();
    }
  }
}
