/// Where the mobile app keeps its refresh token.
///
/// The web app uses the server's session cookie instead, so it uses [NoopTokenStore].
abstract interface class TokenStore {
  Future<String?> readRefreshToken();

  Future<void> writeRefreshToken(String token);

  Future<void> clear();
}

/// The web build (and tests that do not exercise storage) keep nothing.
class NoopTokenStore implements TokenStore {
  const NoopTokenStore();

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> writeRefreshToken(String token) async {}

  @override
  Future<void> clear() async {}
}
