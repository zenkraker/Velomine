import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../l10n/generated/app_localizations.dart';
import 'recorder.dart';
import 'recorder_log.dart';
import 'recorder_settings.dart';
import 'upload_queue.dart';

String recorderErrorText(AppLocalizations l10n, String? code) => switch (code) {
  'permission' => l10n.recorderPermission,
  'gps_off' => l10n.recorderGpsOff,
  'location' => l10n.recorderLocationFailed,
  'unsupported' => l10n.recorderUnsupported,
  'too_short' => l10n.recorderTooShort,
  'fit_failed' => l10n.recorderFitFailed,
  'still_recording' => l10n.recorderStillRecording,
  'not_found' => l10n.recorderRideNotFound,
  'bluetooth_off' => l10n.recorderBluetoothOff,
  'bluetooth_denied' => l10n.recorderBluetoothDenied,
  'sensor_not_found' => l10n.recorderSensorNotFound,
  'recorder_unreadable' => l10n.recorderUnreadable,
  _ => l10n.recorderFailed,
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
  String rideType = 'road';
  bool ebike = false;

  RecorderSnapshot state = const RecorderSnapshot(
    state: 'idle',
    elapsedS: 0,
    movingS: 0,
    distanceM: 0,
  );
  List<LocalRide> rides = [];
  bool loading = false;
  bool busy = false;
  String? errorCode;

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
        _setError('recorder_unreadable');
      },
    );
    autoPause = await settingsStore.readAutoPause() ?? true;
    rideType = await settingsStore.readRideType() ?? 'road';
    ebike = await settingsStore.readEbike() ?? false;
    recorderLog(
      'controller: autoPause=$autoPause rideType=$rideType ebike=$ebike',
    );
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
      errorCode = state.error;
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
      _setError(e.code);
    } on Object catch (e) {
      recorderLog('controller: refresh failed $e');
      _setError('recorder_unreadable');
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> start() async {
    if (busy) return;
    recorderLog('controller: start');
    busy = true;
    errorCode = null;
    _notify();
    try {
      final granted = await recorder.requestPermissions();
      recorderLog('controller: start permission=$granted');
      if (!granted) {
        _setError('permission');
        return;
      }
      await recorder.start(
        autoPause: autoPause,
        rideType: rideType,
        ebike: ebike,
      );
      recorderLog('controller: start native call returned; waiting for state');
      await _waitForRunning();
      recorderLog('controller: start done state=${state.state}');
    } on RecorderException catch (e) {
      recorderLog('controller: start failed ${e.code} ${e.message}');
      _setError(e.code);
    } on Object catch (e) {
      recorderLog('controller: start failed $e');
      _setError(null);
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

  Future<void> setRideType(String value) async {
    rideType = value;
    recorderLog('controller: rideType set to $value');
    await settingsStore.writeRideType(value);
    _notify();
  }

  Future<void> setEbike(bool value) async {
    ebike = value;
    recorderLog('controller: ebike set to $value');
    await settingsStore.writeEbike(value);
    _notify();
  }

  Future<bool> requestSensorPermissions() =>
      recorder.requestSensorPermissions();

  Future<List<SensorInfo>> scanSensors() => recorder.scanSensors();

  Future<void> pairSensor(SensorInfo sensor) async {
    recorderLog('controller: pair ${sensor.name} at ${sensor.address}');
    try {
      await recorder.pairSensor(sensor);
      state = await recorder.state();
      errorCode = null;
    } on RecorderException catch (e) {
      recorderLog('controller: pair failed ${e.code} ${e.message}');
      _setError(e.code);
    } on Object catch (e) {
      recorderLog('controller: pair failed $e');
      _setError(null);
    }
    _notify();
  }

  Future<void> forgetSensor() async {
    recorderLog('controller: forget the strap');
    try {
      await recorder.forgetSensor();
      state = await recorder.state();
      errorCode = null;
    } on RecorderException catch (e) {
      _setError(e.code);
    } on Object {
      _setError(null);
    }
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
    errorCode = null;
    _notify();
    try {
      final ride = await recorder.finalizeRide(id);
      if (ride != null && ride.isFailed) {
        _setError(ride.error);
      }
      rides = await recorder.listRides();
      if (ride?.isReady == true && uploads != null) {
        recorderLog('controller: queue upload for finished ride $id');
        await uploads!.enqueue(id);
      }
    } on RecorderException catch (e) {
      _setError(e.code);
    } on Object {
      _setError(null);
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> deleteRide(String id) async {
    if (busy) return;
    recorderLog('controller: delete $id');
    busy = true;
    errorCode = null;
    _notify();
    try {
      if (!await recorder.deleteRide(id)) {
        _setError('not_found');
      } else {
        uploads?.forget(id);
      }
      rides = await recorder.listRides();
    } on RecorderException catch (e) {
      _setError(e.code);
    } on Object {
      _setError(null);
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _act(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    errorCode = null;
    _notify();
    try {
      await action();
      state = await recorder.state();
      recorderLog('controller: action done state=${state.state}');
    } on RecorderException catch (e) {
      recorderLog('controller: action failed ${e.code} ${e.message}');
      _setError(e.code);
    } on Object catch (e) {
      recorderLog('controller: action failed $e');
      _setError(null);
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
      _setError(null);
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
      _setError(snapshot.error);
    } else {
      errorCode = null;
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

  void _setError(String? code) {
    recorderLog('controller: error ');
    errorCode = code;
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
