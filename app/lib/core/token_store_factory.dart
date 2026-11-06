import 'token_store.dart';
import 'token_store_stub.dart'
    if (dart.library.io) 'token_store_io.dart'
    as platform;

TokenStore createTokenStore() => platform.createTokenStore();
