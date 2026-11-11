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

  @override
  Future<T> locked<T>(Future<T> Function() body) async {
    // The native side only tries once, so the waiting happens here as short pauses instead of a frozen UI.
    var held = false;
    var unavailable = false;
    for (var attempt = 0; attempt < 50 && !held; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      try {
        held = await _channel.invokeMethod<bool>('lockRefresh') ?? false;
      } on Object {
        unavailable = true;
        break; // storage unavailable: carry on unlocked rather than fail the sign-in
      }
    }
    if (!held && !unavailable) throw const TokenLockBusy();
    try {
      return await body();
    } finally {
      if (held) {
        try {
          await _channel.invokeMethod<void>('unlockRefresh');
        } on Object {
          // The lock is stale after a minute and the next writer clears it.
        }
      }
    }
  }
}

TokenStore createTokenStore() => NativeTokenStore();
