import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'location_service.dart';

/// A point the rider saved on this device for their account, used for nearby clubs when the device will not
/// share its position. It never goes to the server except inside a nearby-clubs request.
class HomeLocation extends ChangeNotifier {
  HomeLocation({HomeLocationStore? store}) : _store = store ?? _Preferences();

  final HomeLocationStore _store;

  GeoPoint? position;
  String? _account;

  /// Reads the point saved for [account], so one person on a shared device never sees another's.
  Future<void> load(String account) async {
    _account = account;
    position = await _store.read(account);
    notifyListeners();
  }

  Future<void> save(GeoPoint point) async {
    final account = _account;
    if (account == null) return;
    position = point;
    notifyListeners();
    await _store.write(account, point);
  }

  Future<void> clear() async {
    final account = _account;
    position = null;
    notifyListeners();
    if (account != null) await _store.clear(account);
  }

  /// The session is gone: forget the point in memory but leave it saved for the next sign-in.
  void forget() {
    _account = null;
    position = null;
    notifyListeners();
  }
}

abstract interface class HomeLocationStore {
  Future<GeoPoint?> read(String account);
  Future<void> write(String account, GeoPoint position);
  Future<void> clear(String account);
}

class _Preferences implements HomeLocationStore {
  final _prefs = SharedPreferencesAsync();

  static String _latitudeKey(String account) => 'home_latitude_$account';

  static String _longitudeKey(String account) => 'home_longitude_$account';

  @override
  Future<GeoPoint?> read(String account) async {
    try {
      final latitude = await _prefs.getDouble(_latitudeKey(account));
      final longitude = await _prefs.getDouble(_longitudeKey(account));
      return latitude == null || longitude == null
          ? null
          : (latitude: latitude, longitude: longitude);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(String account, GeoPoint position) async {
    try {
      await _prefs.setDouble(_latitudeKey(account), position.latitude);
      await _prefs.setDouble(_longitudeKey(account), position.longitude);
    } on Object {
      // Not kept; the app still uses the point until it closes.
    }
  }

  @override
  Future<void> clear(String account) async {
    try {
      await _prefs.remove(_latitudeKey(account));
      await _prefs.remove(_longitudeKey(account));
    } on Object {
      // Nothing to remove.
    }
  }
}
