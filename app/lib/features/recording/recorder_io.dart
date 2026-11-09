import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'recorder.dart';
import 'recorder_log.dart';

/// Talks to the Android foreground service. A missing native side is reported as a normal [RecorderException].
class NativeRecorder implements Recorder {
  static const _channel = MethodChannel('velomine/recorder');
  static const _events = EventChannel('velomine/recorder/events');

  @override
  bool get sensorsSupported => defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> requestPermissions() async {
    recorderLog('permissions: asking');
    final granted = await _call<bool>(
      () => _channel.invokeMethod<bool>('requestPermissions'),
    );
    recorderLog('permissions: granted=$granted');
    return granted;
  }

  @override
  Future<void> start({
    bool autoPause = true,
    String rideType = 'road',
    bool ebike = false,
  }) async {
    recorderLog(
      'start: sending autoPause=$autoPause rideType=$rideType ebike=$ebike',
    );
    await _callVoid(
      () => _channel.invokeMethod<void>('start', {
        'autoPause': autoPause,
        'rideType': rideType,
        'ebike': ebike,
      }),
    );
    recorderLog('start: returned');
  }

  @override
  Future<void> pause() async {
    recorderLog('pause: sending');
    await _callVoid(() => _channel.invokeMethod<void>('pause'));
    recorderLog('pause: returned');
  }

  @override
  Future<void> resume() async {
    recorderLog('resume: sending');
    await _callVoid(() => _channel.invokeMethod<void>('resume'));
    recorderLog('resume: returned');
  }

  @override
  Future<void> stop() async {
    recorderLog('stop: sending');
    await _callVoid(() => _channel.invokeMethod<void>('stop'));
    recorderLog('stop: returned');
  }

  @override
  Future<RecorderSnapshot> state() async {
    final map = await _call<Map<dynamic, dynamic>>(
      () => _channel.invokeMethod<Map<dynamic, dynamic>>('getState'),
    );
    final snapshot = RecorderSnapshot.fromMap(Map<String, dynamic>.from(map));
    recorderLog(
      'state: state=${snapshot.state} ride=${snapshot.rideId} '
      'startedAt=${snapshot.startedAt} elapsed=${snapshot.elapsedS} '
      'moving=${snapshot.movingS} distance=${snapshot.distanceM} '
      'speed=${snapshot.speedMs} accuracy=${snapshot.accuracyM} '
      'autoPaused=${snapshot.autoPaused} error=${snapshot.error}',
    );
    return snapshot;
  }

  /// One broadcast stream for every listener (the title bar and the Record screen). Creating a new
  /// `receiveBroadcastStream` per call would open a second native subscription, and the Android side keeps one sink.
  late final Stream<RecorderSnapshot> _eventStream = _events
      .receiveBroadcastStream()
      .map((event) {
        final map = Map<String, dynamic>.from(event as Map<dynamic, dynamic>);
        final snapshot = RecorderSnapshot.fromMap(map);
        recorderLog(
          'event: state=${snapshot.state} ride=${snapshot.rideId} '
          'startedAt=${snapshot.startedAt} elapsed=${snapshot.elapsedS} '
          'moving=${snapshot.movingS} distance=${snapshot.distanceM} '
          'speed=${snapshot.speedMs} accuracy=${snapshot.accuracyM} '
          'autoPaused=${snapshot.autoPaused} error=${snapshot.error}',
        );
        return snapshot;
      });

  @override
  Stream<RecorderSnapshot> get events => _eventStream;

  @override
  Future<bool> requestSensorPermissions() async {
    recorderLog('sensor permissions: asking');
    final granted = await _call<bool>(
      () => _channel.invokeMethod<bool>('requestSensorPermissions'),
    );
    recorderLog('sensor permissions: granted=$granted');
    return granted;
  }

  @override
  Future<List<SensorInfo>> scanSensors() async {
    recorderLog('sensors: scanning');
    final list = await _call<List<dynamic>>(
      () => _channel.invokeMethod<List<dynamic>>('scanSensors'),
    );
    final sensors = [
      for (final item in list)
        SensorInfo.fromMap(Map<String, dynamic>.from(item as Map)),
    ];
    recorderLog('sensors: found ${sensors.length}');
    return sensors;
  }

  @override
  Future<void> pairSensor(SensorInfo sensor) async {
    recorderLog('sensors: pairing ${sensor.name}');
    await _callVoid(
      () => _channel.invokeMethod<void>('pairSensor', {
        'address': sensor.address,
        'name': sensor.name,
      }),
    );
  }

  @override
  Future<void> forgetSensor() async {
    recorderLog('sensors: forgetting the strap');
    await _callVoid(() => _channel.invokeMethod<void>('forgetSensor'));
  }

  @override
  Future<List<LocalRide>> listRides() async {
    final list = await _call<List<dynamic>>(
      () => _channel.invokeMethod<List<dynamic>>('listRides'),
    );
    final rides = <LocalRide>[];
    for (final item in list) {
      final map = Map<String, dynamic>.from(item as Map);
      recorderLog('listRides: raw $map');
      rides.add(LocalRide.fromMap(map));
    }
    recorderLog('listRides: ${rides.length} ride(s)');
    for (final ride in rides) {
      recorderLog('listRides: ${describeRide(ride)}');
    }
    return rides;
  }

  @override
  Future<Uint8List?> readFit(String id) async {
    recorderLog('readFit: $id');
    try {
      final bytes = await _channel.invokeMethod<Uint8List>('readFit', id);
      recorderLog('readFit: $id -> ${bytes?.length ?? 0} bytes');
      return bytes;
    } on PlatformException catch (e) {
      throw RecorderException(e.code, e.message);
    } on MissingPluginException {
      throw const RecorderException(
        'unsupported',
        'Recording is only available on the phone.',
      );
    }
  }

  @override
  Future<LocalRide?> finalizeRide(String id) async {
    recorderLog('finalizeRide: $id');
    final map = await _call<Map<dynamic, dynamic>>(
      () => _channel.invokeMethod<Map<dynamic, dynamic>>('finalizeRide', id),
    );
    final ride = LocalRide.fromMap(Map<String, dynamic>.from(map));
    recorderLog('finalizeRide: ${describeRide(ride)}');
    return ride;
  }

  @override
  Future<bool> deleteRide(String id) async {
    recorderLog('deleteRide: $id');
    final deleted = await _call<bool>(
      () => _channel.invokeMethod<bool>('deleteRide', id),
    );
    recorderLog('deleteRide: $id -> $deleted');
    return deleted;
  }

  @override
  Future<void> markUploadState(
    String id,
    String state, {
    String? serverRideId,
    String? error,
    int? attempts,
  }) async {
    recorderLog(
      'markUploadState: $id state=$state server=$serverRideId error=$error',
    );
    await _callVoid(
      () => _channel.invokeMethod<void>('markUploadState', {
        'id': id,
        'state': state,
        'serverRideId': serverRideId,
        'error': error,
        'attempts': attempts,
      }),
    );
  }

  @override
  Future<void> scheduleUpload(String serverUrl) async {
    recorderLog('scheduleUpload: $serverUrl');
    await _callVoid(
      () => _channel.invokeMethod<void>('scheduleUpload', serverUrl),
    );
  }

  Future<void> _callVoid(Future<void> Function() call) async {
    try {
      await call();
    } on PlatformException catch (e) {
      throw RecorderException(e.code, e.message);
    } on MissingPluginException {
      throw const RecorderException(
        'unsupported',
        'Recording is only available on the phone.',
      );
    }
  }

  Future<T> _call<T>(Future<T?> Function() call) async {
    try {
      final value = await call();
      if (value == null) {
        throw const RecorderException('empty', 'The recorder did not answer.');
      }
      return value;
    } on PlatformException catch (e) {
      throw RecorderException(e.code, e.message);
    } on MissingPluginException {
      throw const RecorderException(
        'unsupported',
        'Recording is only available on the phone.',
      );
    }
  }
}

Recorder createRecorder() => NativeRecorder();
