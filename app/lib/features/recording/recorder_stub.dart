import 'dart:typed_data';

import 'recorder.dart';

class UnsupportedRecorder implements Recorder {
  const UnsupportedRecorder();

  Never get _unsupported => throw const RecorderException(
    'unsupported',
    'Recording is only available on the phone.',
  );

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<void> start({bool autoPause = true}) async => _unsupported;

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
