import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'location_service.dart';

part 'home_location.g.dart';

/// Where the saved point is kept. Tests override it with an in-memory store.
final homeLocationStoreProvider = Provider<HomeLocationStore>(
  (ref) => PreferencesHomeLocationStore(),
);

/// A point the rider saved on this device for their account, used for nearby
/// clubs when the device will not share its position. It never goes to the
/// server except inside a nearby-clubs request.
@Riverpod(keepAlive: true)
class HomeLocationViewModel extends _$HomeLocationViewModel {
  String? _account;

  @override
  GeoPoint? build() => null;

  /// Reads the point saved for [account], so one person on a shared device never
  /// sees another's.
  Future<void> load(String account) async {
    _account = account;
    final point = await ref.read(homeLocationStoreProvider).read(account);
    if (!ref.mounted) return;
    state = point;
  }

  Future<void> save(GeoPoint point) async {
    final account = _account;
    if (account == null) return;
    state = point;
    await ref.read(homeLocationStoreProvider).write(account, point);
  }

  Future<void> clear() async {
    final account = _account;
    state = null;
    if (account != null) {
      await ref.read(homeLocationStoreProvider).clear(account);
    }
  }
}

abstract interface class HomeLocationStore {
  Future<GeoPoint?> read(String account);
  Future<void> write(String account, GeoPoint position);
  Future<void> clear(String account);
}

class PreferencesHomeLocationStore implements HomeLocationStore {
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
