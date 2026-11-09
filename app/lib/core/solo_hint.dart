import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'solo_hint.g.dart';

/// Where the dismissal is kept. Tests override it with an in-memory store.
final soloHintStoreProvider = Provider<SoloHintStore>(
  (ref) => PreferencesSoloHintStore(),
);

/// Whether the rider who is not in a club has put away the card that points at
/// nearby clubs.
@Riverpod(keepAlive: true)
class SoloHintViewModel extends _$SoloHintViewModel {
  @override
  bool build() {
    Future.microtask(_load);
    return false;
  }

  Future<void> _load() async {
    final dismissed = await ref.read(soloHintStoreProvider).read();
    if (!ref.mounted) return;
    state = dismissed;
  }

  Future<void> dismiss() async {
    state = true;
    await ref.read(soloHintStoreProvider).write();
  }
}

abstract interface class SoloHintStore {
  Future<bool> read();
  Future<void> write();
}

class PreferencesSoloHintStore implements SoloHintStore {
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
