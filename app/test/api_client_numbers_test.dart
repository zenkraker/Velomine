import 'package:flutter_test/flutter_test.dart';
import 'package:velomine_api/api.dart';

void main() {
  test(
    'RideStreamsResponse_ShouldReadWholeNumbersAndNulls_WhenTheServerSendsThem',
    () {
      final streams = RideStreamsResponse.fromJson({
        'time': [79, 120.5],
        'latitude': [46.5, null],
        'longitude': [11.3, null],
        'altitude': [300, null],
        'speed': [null, 5.5],
        'distance': [null, null],
        'heartRate': [140, null],
        'power': [250, null],
        'cadence': [90, null],
        'temperature': [21, null],
      });

      expect(streams!.time, [79.0, 120.5]);
      expect(streams.latitude, [46.5, null]);
      expect(streams.altitude, [300.0, null]);
      expect(streams.heartRate, [140, null]);
    },
  );
}
