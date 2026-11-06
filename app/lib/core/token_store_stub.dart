import 'token_store.dart';

/// Web builds use the session cookie, so there is no token to keep.
TokenStore createTokenStore() => const NoopTokenStore();
