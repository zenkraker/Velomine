import 'dart:typed_data';

/// A heart-rate strap found while pairing. [address] is the phone's identifier for it and stays on the phone.
class SensorInfo {
  const SensorInfo({required this.address, required this.name, this.rssi});

  final String address;
  final String name;
  final int? rssi;

  static SensorInfo fromMap(Map<String, dynamic> map) => SensorInfo(
    address: map['address'] as String? ?? '',
    name: map['name'] as String? ?? 'Heart-rate strap',
    rssi: (map['rssi'] as num?)?.toInt(),
  );
}

/// The live state of the phone's recorder.
class RecorderSnapshot {
  const RecorderSnapshot({
    required this.state,
    this.rideId,
    this.startedAt,
    required this.elapsedS,
    required this.movingS,
    required this.distanceM,
    this.speedMs,
    this.accuracyM,
    this.error,
    this.autoPaused = false,
    this.sensorName,
    this.sensorStatus = 'none',
    this.heartRateBpm,
  });

  final String state;
  final String? rideId;
  final DateTime? startedAt;
  final double elapsedS;
  final double movingS;
  final double distanceM;
  final double? speedMs;
  final double? accuracyM;
  final String? error;

  /// The pause was made by the speed monitor, not by the member.
  final bool autoPaused;

  /// The strap this phone remembers, if any.
  final String? sensorName;

  /// "none", "paired", "connecting", "connected", "off" or "denied".
  final String sensorStatus;

  /// The latest reading, only while the strap is connected during a ride.
  final int? heartRateBpm;

  bool get isRecording => state == 'recording';
  bool get isPaused => state == 'paused';
  bool get isIdle => state == 'idle';

  bool get sensorConnected => sensorStatus == 'connected';

  static RecorderSnapshot fromMap(Map<String, dynamic> map) {
    final started = map['startedAt'] as num?;
    return RecorderSnapshot(
      state: map['state'] as String? ?? 'idle',
      rideId: map['rideId'] as String?,
      startedAt: started == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(started.toInt()),
      elapsedS: (map['elapsedS'] as num?)?.toDouble() ?? 0,
      movingS: (map['movingS'] as num?)?.toDouble() ?? 0,
      distanceM: (map['distanceM'] as num?)?.toDouble() ?? 0,
      speedMs: (map['speedMs'] as num?)?.toDouble(),
      accuracyM: (map['accuracyM'] as num?)?.toDouble(),
      error: map['error'] as String?,
      autoPaused: map['autoPaused'] as bool? ?? false,
      sensorName: map['sensorName'] as String?,
      sensorStatus: map['sensorStatus'] as String? ?? 'none',
      heartRateBpm: (map['heartRateBpm'] as num?)?.toInt(),
    );
  }
}

/// A ride saved on this phone, before or instead of being uploaded.
class LocalRide {
  const LocalRide({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.state,
    required this.distanceM,
    required this.movingS,
    this.error,
    this.uploadState,
    this.serverRideId,
    this.uploadError,
    this.uploadAttempts = 0,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String state;
  final double distanceM;
  final double movingS;
  final String? error;

  /// The background worker and the Dart queue keep this on the phone.
  final String? uploadState;
  final String? serverRideId;
  final String? uploadError;
  final int uploadAttempts;

  bool get isUploaded => uploadState == 'uploaded';

  bool get isInterrupted => state == 'interrupted';
  bool get isReady => state == 'ready';
  bool get isFailed => state == 'failed';
  bool get isLive => state == 'recording' || state == 'paused';

  static LocalRide fromMap(Map<String, dynamic> map) {
    final started = map['startedAt'] as num? ?? 0;
    final ended = map['endedAt'] as num?;
    return LocalRide(
      id: map['id'] as String? ?? '',
      startedAt: DateTime.fromMillisecondsSinceEpoch(started.toInt()),
      endedAt: ended == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(ended.toInt()),
      state: map['state'] as String? ?? 'interrupted',
      distanceM: (map['distanceM'] as num?)?.toDouble() ?? 0,
      movingS: (map['movingS'] as num?)?.toDouble() ?? 0,
      error: map['error'] as String?,
      uploadState: map['uploadState'] as String?,
      serverRideId: map['serverRideId'] as String?,
      uploadError: map['uploadError'] as String?,
      uploadAttempts: (map['uploadAttempts'] as num?)?.toInt() ?? 0,
    );
  }
}

class RecorderException implements Exception {
  const RecorderException(this.code, [this.message]);

  final String code;
  final String? message;

  @override
  String toString() => message ?? code;
}

/// The phone recorder. Android implements it with a foreground service; the web has no recorder.
abstract interface class Recorder {
  /// Whether this platform can pair Bluetooth sensors (phone only).
  bool get sensorsSupported;

  Future<bool> requestPermissions();

  Future<void> start({bool autoPause = true});

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  Future<RecorderSnapshot> state();

  Stream<RecorderSnapshot> get events;

  /// Asks for the nearby-devices permissions the pairing screen needs.
  Future<bool> requestSensorPermissions();

  /// Scans for a few seconds and returns the heart-rate straps found.
  Future<List<SensorInfo>> scanSensors();

  /// Remembers [sensor] for the next rides. Connecting is left to the recorder service.
  Future<void> pairSensor(SensorInfo sensor);

  Future<void> forgetSensor();

  Future<List<LocalRide>> listRides();

  /// The finished FIT file, or null when the ride has none yet.
  Future<Uint8List?> readFit(String id);

  Future<LocalRide?> finalizeRide(String id);

  Future<bool> deleteRide(String id);

  /// Records where the upload got to, for the background worker and the list.
  Future<void> markUploadState(
    String id,
    String state, {
    String? serverRideId,
    String? error,
    int? attempts,
  });

  /// Asks the platform to upload when the app is not open (WorkManager on Android; no-op elsewhere).
  Future<void> scheduleUpload(String serverUrl);
}
