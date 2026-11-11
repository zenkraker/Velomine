/// Where the mobile app keeps its refresh token.
///
/// The web app uses the server's session cookie instead, so it uses [NoopTokenStore].
abstract interface class TokenStore {
  Future<String?> readRefreshToken();

  Future<void> writeRefreshToken(String token);

  Future<void> clear();

  /// Runs [body] while no other writer rotates the token. The background upload worker takes the same lock, so two
  /// refreshes of the single-use token never overlap. A store with no shared writer just runs [body].
  Future<T> locked<T>(Future<T> Function() body);
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

  @override
  Future<T> locked<T>(Future<T> Function() body) => body();
}
