import 'dart:typed_data';

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

  bool get isRecording => state == 'recording';
  bool get isPaused => state == 'paused';
  bool get isIdle => state == 'idle';

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
  Future<bool> requestPermissions();

  Future<void> start({bool autoPause = true});

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  Future<RecorderSnapshot> state();

  Stream<RecorderSnapshot> get events;

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
