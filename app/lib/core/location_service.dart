import 'package:geolocator/geolocator.dart';

/// A point on the earth, as latitude and longitude in degrees.
typedef GeoPoint = ({double latitude, double longitude});

/// Where the device says the rider is. One position on demand, never a stream; null when the device cannot help.
abstract interface class LocationService {
  Future<GeoPoint?> current();
}

/// The platform's position, after asking for permission. Null on refusal, on a missing service or on a timeout.
class DeviceLocationService implements LocationService {
  const DeviceLocationService();

  @override
  Future<GeoPoint?> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } on Object {
      // A browser without a secure context and a phone with location turned off both land here.
      return null;
    }
  }
}
