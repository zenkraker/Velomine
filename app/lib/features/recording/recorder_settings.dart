import 'package:shared_preferences/shared_preferences.dart';

/// The recorder options that belong to this phone.
abstract interface class RecorderSettingsStore {
  Future<bool?> readAutoPause();

  Future<void> writeAutoPause(bool value);
}

class PreferencesRecorderSettingsStore implements RecorderSettingsStore {
  static const _key = 'recorderAutoPause';
  SharedPreferencesAsync? _prefs;

  SharedPreferencesAsync get _instance => _prefs ??= SharedPreferencesAsync();

  @override
  Future<bool?> readAutoPause() async {
    try {
      return await _instance.getBool(_key);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> writeAutoPause(bool value) async {
    try {
      await _instance.setBool(_key, value);
    } on Object {
      // The choice still applies until the app closes.
    }
  }
}
