import 'package:flutter/services.dart';

import 'token_store.dart';

/// The refresh token is kept by the small native secure-storage channel:
/// Android Keystore on Android, Keychain on iOS. It is never written to
/// shared preferences, backups or logs.
class NativeTokenStore implements TokenStore {
  static const _channel = MethodChannel('velomine/secure_storage');

  @override
  Future<String?> readRefreshToken() async {
    try {
      return await _channel.invokeMethod<String>('readRefreshToken');
    } on Object {
      return null; // storage unavailable, or the key was invalidated
    }
  }

  @override
  Future<void> writeRefreshToken(String token) async {
    try {
      await _channel.invokeMethod<void>('writeRefreshToken', token);
    } on Object {
      // The session still works until the app closes; the next start asks to sign in again.
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _channel.invokeMethod<void>('clear');
    } on Object {
      // Nothing more we can do; a missing token simply means signed out.
    }
  }
}

TokenStore createTokenStore() => NativeTokenStore();
