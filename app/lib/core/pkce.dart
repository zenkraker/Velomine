import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// A PKCE pair (RFC 7636): the app keeps the [verifier] secret and sends only the [challenge], so a code caught by
/// another app on the phone is useless to it.
class Pkce {
  Pkce._(this.verifier, this.challenge);

  /// A fresh pair: 32 random bytes as the verifier (43 characters), its SHA-256 as the challenge.
  factory Pkce.generate([Random? random]) {
    final rng = random ?? Random.secure();
    final verifier = _base64Url([
      for (var i = 0; i < 32; i++) rng.nextInt(256),
    ]);
    return Pkce.fromVerifier(verifier);
  }

  factory Pkce.fromVerifier(String verifier) => Pkce._(
    verifier,
    _base64Url(sha256.convert(ascii.encode(verifier)).bytes),
  );

  final String verifier;
  final String challenge;

  static String _base64Url(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
}
