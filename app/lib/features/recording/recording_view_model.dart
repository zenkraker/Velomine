import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/providers.dart';
import '../../core/result.dart';
import 'recorder.dart';
import 'recorder_log.dart';
import 'recording_providers.dart';
import 'recording_state.dart';

part 'recording_view_model.g.dart';

/// Drives the recording screen. The native service keeps recording when this
/// screen is closed; opening it again reads the live state back.
@Riverpod(keepAlive: true)
class RecordingViewModel extends _$RecordingViewModel {
  String? _accountId;
  bool _started = false;
  bool _uploadsResumed = false;

  @override
  RideRecordingState build() {
    final recorder = ref.watch(recorderProvider);
    final queue = ref.watch(uploadQueueProvider);
    final accountId = ref.watch(signedInUserIdProvider);
    if (recorder == null || accountId == null) {
      _accountId = null;
      _started = false;
      _uploadsResumed = false;
      return const RideRecordingState();
    }
    if (accountId != _accountId) {
      // Another member signed in: this one's rides and uploads start from empty.
      _accountId = accountId;
      _started = false;
      _uploadsResumed = false;
    }

    ref.listen(recorderSnapshotViewModelProvider, (_, snapshot) {
      if (!ref.mounted) return;
      final wasLive = state.snapshot.isRecording || state.snapshot.isPaused;
      state = snapshot.error == null
          ? state.copyWith(snapshot: snapshot, clearError: true)
          : state.copyWith(snapshot: snapshot, errorCode: snapshot.error);
      // A stopped service reports idle; read the finished local ride again.
      if (wasLive && snapshot.isIdle) {
        recorderLog('recording: service went idle; refreshing rides');
        unawaited(_refreshRides());
      }
    });

    ref.listen(uploadStatesProvider, (_, next) {
      final uploads = next.value;
      if (uploads == null) return;
      state = state.copyWith(uploads: uploads);
    });

    Future.microtask(_init);
    return RideRecordingState(uploads: queue?.states ?? const {});
  }

  Future<void> _init() async {
    if (_started) return;
    _started = true;
    final store = ref.read(recorderSettingsStoreProvider);
    final autoPause = await store.readAutoPause() ?? true;
    final rideType = await store.readRideType() ?? 'road';
    final ebike = await store.readEbike() ?? false;
    if (!ref.mounted) return;
    state = state.copyWith(
      autoPause: autoPause,
      rideType: rideType,
      ebike: ebike,
    );
    await refresh();
  }

  Future<void> refresh() async {
    final recorder = ref.read(recorderProvider);
    final accountId = _accountId;
    if (recorder == null || accountId == null) return;
    state = state.copyWith(loading: true);
    try {
      final snapshot = await recorder.state();
      final rides = await recorder.listRides(accountId: accountId);
      if (!ref.mounted) return;
      state = state.copyWith(
        snapshot: snapshot,
        rides: rides,
        errorCode: snapshot.error,
        clearError: snapshot.error == null,
      );
      final queue = ref.read(uploadQueueProvider);
      if (queue != null && !_uploadsResumed) {
        _uploadsResumed = true;
        unawaited(queue.resume(rides));
      }
    } on RecorderException catch (e) {
      recorderLog('recording: refresh failed ${e.code} ${e.message}');
      _error(e.code);
    } on Object {
      _error('recorder_unreadable');
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> start() async {
    final recorder = ref.read(recorderProvider);
    final accountId = _accountId;
    if (recorder == null || accountId == null || state.command.running) return;
    state = state.copyWith(command: state.command.start(), clearError: true);
    try {
      final granted = await recorder.requestPermissions();
      if (!granted) {
        _error('permission');
        return;
      }
      await recorder.start(
        autoPause: state.autoPause,
        rideType: state.rideType,
        ebike: state.ebike,
        accountId: accountId,
      );
      await _waitForRunning(recorder);
    } on RecorderException catch (e) {
      recorderLog('recording: start failed ${e.code} ${e.message}');
      _error(e.code);
    } on Object {
      _error(null);
    } finally {
      _finishCommand();
    }
  }

  Future<void> setAutoPause(bool value) async {
    state = state.copyWith(autoPause: value);
    await ref.read(recorderSettingsStoreProvider).writeAutoPause(value);
  }

  Future<void> setRideType(String value) async {
    state = state.copyWith(rideType: value);
    await ref.read(recorderSettingsStoreProvider).writeRideType(value);
  }

  Future<void> setEbike(bool value) async {
    state = state.copyWith(ebike: value);
    await ref.read(recorderSettingsStoreProvider).writeEbike(value);
  }

  Future<bool> requestSensorPermissions() async =>
      ref.read(recorderProvider)?.requestSensorPermissions() ?? false;

  Future<List<SensorInfo>> scanSensors() async =>
      ref.read(recorderProvider)?.scanSensors() ?? const [];

  Future<void> pairSensor(SensorInfo sensor) =>
      _act((recorder) => recorder.pairSensor(sensor));

  Future<void> forgetSensor() => _act((recorder) => recorder.forgetSensor());

  Future<void> pause() => _act((recorder) => recorder.pause());

  Future<void> resume() => _act((recorder) => recorder.resume());

  Future<void> stop() async {
    final rideId = state.snapshot.rideId;
    await _act((recorder) => recorder.stop());
    await refresh();
    final queue = ref.read(uploadQueueProvider);
    if (rideId != null && queue != null) {
      recorderLog('recording: queue upload for stopped ride $rideId');
      await queue.enqueue(rideId);
    }
  }

  Future<void> finalizeRide(String id) async {
    final recorder = ref.read(recorderProvider);
    if (recorder == null || state.command.running) return;
    recorderLog('recording: finalize $id');
    state = state.copyWith(command: state.command.start(), clearError: true);
    try {
      final ride = await recorder.finalizeRide(id);
      if (ride != null && ride.isFailed) _error(ride.error);
      if (!ref.mounted) return;
      state = state.copyWith(
        rides: await recorder.listRides(accountId: _accountId),
      );
      final queue = ref.read(uploadQueueProvider);
      if (ride?.isReady == true && queue != null) {
        await queue.enqueue(id);
      }
    } on RecorderException catch (e) {
      _error(e.code);
    } on Object {
      _error(null);
    } finally {
      _finishCommand();
    }
  }

  /// Queues a finished local ride for upload.
  Future<void> uploadRide(String id) async =>
      ref.read(uploadQueueProvider)?.enqueue(id);

  /// Tries a rejected upload again.
  Future<void> retryUpload(String id) async =>
      ref.read(uploadQueueProvider)?.retry(id);

  Future<void> deleteRide(String id) async {
    final recorder = ref.read(recorderProvider);
    if (recorder == null || state.command.running) return;
    recorderLog('recording: delete $id');
    state = state.copyWith(command: state.command.start(), clearError: true);
    try {
      if (!await recorder.deleteRide(id)) {
        _error('not_found');
      } else {
        ref.read(uploadQueueProvider)?.forget(id);
      }
      if (!ref.mounted) return;
      state = state.copyWith(
        rides: await recorder.listRides(accountId: _accountId),
      );
    } on RecorderException catch (e) {
      _error(e.code);
    } on Object {
      _error(null);
    } finally {
      _finishCommand();
    }
  }

  Future<void> _act(Future<void> Function(Recorder recorder) action) async {
    final recorder = ref.read(recorderProvider);
    if (recorder == null || state.command.running) return;
    state = state.copyWith(command: state.command.start(), clearError: true);
    try {
      await action(recorder);
      final snapshot = await recorder.state();
      if (!ref.mounted) return;
      state = state.copyWith(snapshot: snapshot);
    } on RecorderException catch (e) {
      recorderLog('recording: action failed ${e.code} ${e.message}');
      _error(e.code);
    } on Object {
      _error(null);
    } finally {
      _finishCommand();
    }
  }

  /// The service starts asynchronously; give it a moment before showing the
  /// screen's recording state.
  Future<void> _waitForRunning(Recorder recorder) async {
    for (var i = 0; i < 8; i++) {
      final snapshot = await recorder.state();
      if (!ref.mounted) return;
      state = state.copyWith(snapshot: snapshot);
      if (!snapshot.isIdle) return;
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    final snapshot = await recorder.state();
    if (!ref.mounted) return;
    state = state.copyWith(snapshot: snapshot);
    if (snapshot.isIdle) _error(null);
  }

  Future<void> _refreshRides() async {
    final recorder = ref.read(recorderProvider);
    if (recorder == null) return;
    try {
      final rides = await recorder.listRides(accountId: _accountId);
      if (!ref.mounted) return;
      state = state.copyWith(rides: rides);
    } on Object catch (e) {
      recorderLog('recording: rides refresh failed $e');
      // The screen still shows the last list.
    }
  }

  void _finishCommand() {
    if (!ref.mounted) return;
    state = state.copyWith(command: state.command.finish(const Ok<void>(null)));
  }

  void _error(String? code) {
    if (!ref.mounted) return;
    state = state.copyWith(errorCode: code, clearError: code == null);
  }
}
