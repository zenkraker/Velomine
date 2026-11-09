import 'package:shared_preferences/shared_preferences.dart';

/// The recorder options that belong to this phone.
abstract interface class RecorderSettingsStore {
  Future<bool?> readAutoPause();

  Future<void> writeAutoPause(bool value);

  Future<String?> readRideType();

  Future<void> writeRideType(String value);

  Future<bool?> readEbike();

  Future<void> writeEbike(bool value);
}

class PreferencesRecorderSettingsStore implements RecorderSettingsStore {
  static const _autoPauseKey = 'recorderAutoPause';
  static const _rideTypeKey = 'recorderRideType';
  static const _ebikeKey = 'recorderEbike';
  SharedPreferencesAsync? _prefs;

  SharedPreferencesAsync get _instance => _prefs ??= SharedPreferencesAsync();

  @override
  Future<bool?> readAutoPause() async {
    try {
      return await _instance.getBool(_autoPauseKey);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> writeAutoPause(bool value) async {
    try {
      await _instance.setBool(_autoPauseKey, value);
    } on Object {
      // The choice still applies until the app closes.
    }
  }

  @override
  Future<String?> readRideType() async {
    try {
      return await _instance.getString(_rideTypeKey);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> writeRideType(String value) async {
    try {
      await _instance.setString(_rideTypeKey, value);
    } on Object {
      // The choice still applies until the app closes.
    }
  }

  @override
  Future<bool?> readEbike() async {
    try {
      return await _instance.getBool(_ebikeKey);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> writeEbike(bool value) async {
    try {
      await _instance.setBool(_ebikeKey, value);
    } on Object {
      // The choice still applies until the app closes.
    }
  }
}
