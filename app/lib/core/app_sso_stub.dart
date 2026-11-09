import 'app_sso.dart';

AppSso createPlatformAppSso() => const _UnsupportedAppSso();

class _UnsupportedAppSso implements AppSso {
  const _UnsupportedAppSso();

  @override
  Future<AppSsoResult> signIn(AppSsoConfig config) async =>
      const AppSsoResult.failed();
}
