import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the rider who is not in a club has put away the card that points at nearby clubs.
class SoloHint extends ChangeNotifier {
  SoloHint({SoloHintStore? store}) : _store = store ?? _Preferences();

  final SoloHintStore _store;

  bool dismissed = false;

  Future<void> load() async {
    dismissed = await _store.read();
    notifyListeners();
  }

  Future<void> dismiss() async {
    dismissed = true;
    notifyListeners();
    await _store.write();
  }
}

abstract interface class SoloHintStore {
  Future<bool> read();
  Future<void> write();
}

class _Preferences implements SoloHintStore {
  static const _key = 'solo_club_hint_dismissed';
  final _prefs = SharedPreferencesAsync();

  @override
  Future<bool> read() async {
    try {
      return await _prefs.getBool(_key) ?? false;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> write() async {
    try {
      await _prefs.setBool(_key, true);
    } on Object {
      // Not kept; the card returns next time.
    }
  }
}
