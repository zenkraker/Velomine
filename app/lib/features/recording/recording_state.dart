import '../../core/command.dart';
import 'recorder.dart';
import 'upload_queue.dart';

/// The recording screen: what the phone is doing, the rides saved on it, and
/// the start-card choices.
class RideRecordingState {
  const RideRecordingState({
    this.snapshot = const RecorderSnapshot(
      state: 'idle',
      elapsedS: 0,
      movingS: 0,
      distanceM: 0,
    ),
    this.rides = const [],
    this.uploads = const {},
    this.loading = false,
    this.command = const CommandState.idle(),
    this.autoPause = true,
    this.rideType = 'road',
    this.ebike = false,
    this.errorCode,
  });

  final RecorderSnapshot snapshot;
  final List<LocalRide> rides;

  /// What the upload queue is doing with each local ride, by local id.
  final Map<String, UploadState> uploads;

  final bool loading;

  /// Start, pause, resume, stop, finalize, delete, pair and forget share one
  /// command, so every button is disabled while one runs.
  final VoidCommand command;

  final bool autoPause;
  final String rideType;
  final bool ebike;

  /// The recorder's last error code, in the same vocabulary as the recorder.
  final String? errorCode;

  bool get live => snapshot.isRecording || snapshot.isPaused;

  RideRecordingState copyWith({
    RecorderSnapshot? snapshot,
    List<LocalRide>? rides,
    Map<String, UploadState>? uploads,
    bool? loading,
    VoidCommand? command,
    bool? autoPause,
    String? rideType,
    bool? ebike,
    String? errorCode,
    bool clearError = false,
  }) => RideRecordingState(
    snapshot: snapshot ?? this.snapshot,
    rides: rides ?? this.rides,
    uploads: uploads ?? this.uploads,
    loading: loading ?? this.loading,
    command: command ?? this.command,
    autoPause: autoPause ?? this.autoPause,
    rideType: rideType ?? this.rideType,
    ebike: ebike ?? this.ebike,
    errorCode: clearError ? null : (errorCode ?? this.errorCode),
  );
}
