import 'dart:typed_data';

import 'recorder.dart';

class UnsupportedRecorder implements Recorder {
  const UnsupportedRecorder();

  Never get _unsupported => throw const RecorderException(
    'unsupported',
    'Recording is only available on the phone.',
  );

  @override
  bool get sensorsSupported => false;

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<bool> requestSensorPermissions() async => false;

  @override
  Future<List<SensorInfo>> scanSensors() async => const [];

  @override
  Future<void> pairSensor(SensorInfo sensor) async => _unsupported;

  @override
  Future<void> forgetSensor() async {}

  @override
  Future<void> start({
    bool autoPause = true,
    String rideType = 'road',
    bool ebike = false,
  }) async => _unsupported;

  @override
  Future<void> pause() async => _unsupported;

  @override
  Future<void> resume() async => _unsupported;

  @override
  Future<void> stop() async => _unsupported;

  @override
  Future<RecorderSnapshot> state() async => const RecorderSnapshot(
    state: 'idle',
    elapsedS: 0,
    movingS: 0,
    distanceM: 0,
  );

  @override
  Stream<RecorderSnapshot> get events => const Stream.empty();

  @override
  Future<List<LocalRide>> listRides() async => const [];

  @override
  Future<Uint8List?> readFit(String id) async => null;

  @override
  Future<LocalRide?> finalizeRide(String id) async => _unsupported;

  @override
  Future<bool> deleteRide(String id) async => false;

  @override
  Future<void> markUploadState(
    String id,
    String state, {
    String? serverRideId,
    String? error,
    int? attempts,
  }) async {}

  @override
  Future<void> scheduleUpload(String serverUrl) async {}
}

Recorder createRecorder() => const UnsupportedRecorder();
