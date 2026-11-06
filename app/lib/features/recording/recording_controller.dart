import 'dart:async';

import 'package:flutter/foundation.dart';

import 'recorder.dart';
import 'recorder_log.dart';
import 'recorder_settings.dart';
import 'upload_queue.dart';

String recorderErrorText(String? code) => switch (code) {
  'permission' => 'Allow precise location, and notifications if asked, so the ride can keep recording.',
  'gps_off' => 'Turn on location (GPS) to record a ride.',
  'location' => 'The phone could not start location updates.',
  'unsupported' => 'Recording is only available on the phone.',
  'too_short' => 'The ride was too short to save.',
  'fit_failed' => 'The ride could not be saved.',
  'still_recording' => 'Stop the ride before finishing it.',
  'not_found' => 'That ride is no longer on this phone.',
  _ => 'The recorder could not do that. Try again.',
};

/// Drives the recording screen. The native service keeps recording when this screen is closed; opening it again
/// reads the live state back.
class RecordingController extends ChangeNotifier {
  RecordingController({
    required this.recorder,
    this.uploads,
    RecorderSettingsStore? settingsStore,
  }) : settingsStore = settingsStore ?? PreferencesRecorderSettingsStore();

  final Recorder recorder;
  final RideUploadQueue? uploads;
  final RecorderSettingsStore settingsStore;
  bool autoPause = true;

  RecorderSnapshot state = const RecorderSnapshot(
    state: 'idle',
    elapsedS: 0,
    movingS: 0,
    distanceM: 0,
  );
  List<LocalRide> rides = [];
  bool loading = false;
  bool busy = false;
  String? error;

  StreamSubscription<RecorderSnapshot>? _events;
  bool _started = false;
  bool _disposed = false;
  bool _uploadsResumed = false;

  Future<void> init() async {
    if (_started) return;
    _started = true;
    recorderLog('controller: init');
    _events = recorder.events.listen(
      _onSnapshot,
      onError: (Object error) {
        recorderLog('controller: event stream error $error');
        _setError('Could not read the recorder.');
      },
    );
    autoPause = await settingsStore.readAutoPause() ?? true;
    recorderLog('controller: autoPause=$autoPause');
    if (uploads != null) {
      await uploads!.init();
      uploads!.addListener(_notify);
    }
    await refresh();
  }

  Future<void> refresh() async {
    if (_disposed) return;
    recorderLog('controller: refresh');
    loading = true;
    _notify();
    try {
      state = await recorder.state();
      rides = await recorder.listRides();
      error = state.error == null ? null : recorderErrorText(state.error);
      recorderLog(
        'controller: refresh done state=${state.state} rides=${rides.length}',
      );
      for (final ride in rides) {
        recorderLog('controller: ride ${describeRide(ride)}');
      }
      if (uploads != null && !_uploadsResumed) {
        _uploadsResumed = true;
        unawaited(uploads!.resume(rides));
      }
    } on RecorderException catch (e) {
      recorderLog('controller: refresh failed ${e.code} ${e.message}');
      _setError(recorderErrorText(e.code));
    } on Object catch (e) {
      recorderLog('controller: refresh failed $e');
      _setError('Could not read the recorder.');
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> start() async {
    if (busy) return;
    recorderLog('controller: start');
    busy = true;
    error = null;
    _notify();
    try {
      final granted = await recorder.requestPermissions();
      recorderLog('controller: start permission=$granted');
      if (!granted) {
        _setError(recorderErrorText('permission'));
        return;
      }
      await recorder.start(autoPause: autoPause);
      recorderLog('controller: start native call returned; waiting for state');
      await _waitForRunning();
      recorderLog('controller: start done state=${state.state}');
    } on RecorderException catch (e) {
      recorderLog('controller: start failed ${e.code} ${e.message}');
      _setError(recorderErrorText(e.code));
    } on Object catch (e) {
      recorderLog('controller: start failed $e');
      _setError(recorderErrorText(null));
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> setAutoPause(bool value) async {
    autoPause = value;
    recorderLog('controller: autoPause set to $value');
    await settingsStore.writeAutoPause(value);
    _notify();
  }

  Future<void> pause() async {
    recorderLog('controller: pause');
    await _act(recorder.pause);
  }

  Future<void> resume() async {
    recorderLog('controller: resume');
    await _act(recorder.resume);
  }

  Future<void> stop() async {
    recorderLog('controller: stop');
    final rideId = state.rideId;
    await _act(recorder.stop);
    recorderLog('controller: stop native call done; refreshing list');
    if (!_disposed) await refresh();
    if (rideId != null && uploads != null) {
      recorderLog('controller: queue upload for stopped ride $rideId');
      await uploads!.enqueue(rideId);
    }
  }

  Future<void> finalizeRide(String id) async {
    if (busy) return;
    recorderLog('controller: finalize $id');
    busy = true;
    error = null;
    _notify();
    try {
      final ride = await recorder.finalizeRide(id);
      if (ride != null && ride.isFailed) {
        _setError(recorderErrorText(ride.error));
      }
      rides = await recorder.listRides();
      if (ride?.isReady == true && uploads != null) {
        recorderLog('controller: queue upload for finished ride $id');
        await uploads!.enqueue(id);
      }
    } on RecorderException catch (e) {
      _setError(recorderErrorText(e.code));
    } on Object {
      _setError(recorderErrorText(null));
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> deleteRide(String id) async {
    if (busy) return;
    recorderLog('controller: delete $id');
    busy = true;
    error = null;
    _notify();
    try {
      if (!await recorder.deleteRide(id)) {
        _setError(recorderErrorText('not_found'));
      } else {
        uploads?.forget(id);
      }
      rides = await recorder.listRides();
    } on RecorderException catch (e) {
      _setError(recorderErrorText(e.code));
    } on Object {
      _setError(recorderErrorText(null));
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _act(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    error = null;
    _notify();
    try {
      await action();
      state = await recorder.state();
      recorderLog('controller: action done state=${state.state}');
    } on RecorderException catch (e) {
      recorderLog('controller: action failed ${e.code} ${e.message}');
      _setError(recorderErrorText(e.code));
    } on Object catch (e) {
      recorderLog('controller: action failed $e');
      _setError(recorderErrorText(null));
    } finally {
      busy = false;
      _notify();
    }
  }

  /// The service starts asynchronously; give it a moment before showing the screen's recording state.
  Future<void> _waitForRunning() async {
    for (var i = 0; i < 8; i++) {
      state = await recorder.state();
      recorderLog(
        'controller: wait running attempt ${i + 1} state=${state.state}',
      );
      if (!state.isIdle) return;
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    state = await recorder.state();
    if (state.isIdle) {
      recorderLog('controller: wait running timed out');
      _setError(recorderErrorText(null));
    }
  }

  void _onSnapshot(RecorderSnapshot snapshot) {
    if (_disposed) return;
    final wasLive = state.isRecording || state.isPaused;
    recorderLog(
      'controller: snapshot state=${snapshot.state} wasLive=$wasLive '
      'ride=${snapshot.rideId} autoPaused=${snapshot.autoPaused} '
      'error=${snapshot.error}',
    );
    state = snapshot;
    if (snapshot.error != null) {
      _setError(recorderErrorText(snapshot.error));
    } else {
      error = null;
      _notify();
    }
    // A stopped service reports idle; read the finished local ride again.
    if (wasLive && snapshot.isIdle) {
      recorderLog('controller: service went idle; refreshing rides');
      unawaited(_refreshRides());
    }
  }

  Future<void> _refreshRides() async {
    try {
      rides = await recorder.listRides();
      recorderLog('controller: rides refreshed: ${rides.length}');
      for (final ride in rides) {
        recorderLog('controller: ride ${describeRide(ride)}');
      }
      _notify();
    } on Object catch (e) {
      recorderLog('controller: rides refresh failed $e');
      // The screen still shows the last list.
    }
  }

  void _setError(String message) {
    recorderLog('controller: error $message');
    error = message;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _events?.cancel();
    uploads?.removeListener(_notify);
    uploads?.dispose();
    super.dispose();
  }
}
