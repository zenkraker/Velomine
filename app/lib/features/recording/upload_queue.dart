import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velomine_api/api.dart';

import '../../core/telemetry.dart';
import 'recorder.dart';
import 'recorder_log.dart';
import 'ride_uploader.dart';

/// What the upload queue is doing with one local ride.
class UploadState {
  const UploadState({
    required this.state,
    this.serverRideId,
    this.error,
    this.attempts = 0,
  });

  static const queued = 'queued';
  static const uploading = 'uploading';
  static const processing = 'processing';
  static const uploaded = 'uploaded';
  static const failed = 'failed';

  final String state;
  final String? serverRideId;
  final String? error;
  final int attempts;

  bool get isUploaded => state == uploaded;
  bool get isBusy =>
      state == queued || state == uploading || state == processing;
  bool get isFailed => state == failed;

  Map<String, Object?> toJson() => {
    'state': state,
    'serverRideId': serverRideId,
    'error': error,
    'attempts': attempts,
  };

  static UploadState? fromJson(Object? value) {
    if (value is! Map) return null;
    final state = value['state'] as String?;
    if (state == null) return null;
    return UploadState(
      state: state,
      serverRideId: value['serverRideId'] as String?,
      error: value['error'] as String?,
      attempts: (value['attempts'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Where upload state is kept across app restarts. Tests pass one in memory.
abstract interface class UploadStateStore {
  Future<Map<String, UploadState>> read();

  Future<void> write(Map<String, UploadState> states);
}

class PreferencesUploadStateStore implements UploadStateStore {
  static const _key = 'rideUploads';
  SharedPreferencesAsync? _prefs;

  SharedPreferencesAsync get _instance => _prefs ??= SharedPreferencesAsync();

  @override
  Future<Map<String, UploadState>> read() async {
    try {
      final raw = await _instance.getString(_key);
      if (raw == null) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final states = <String, UploadState>{};
      for (final entry in decoded.entries) {
        final state = UploadState.fromJson(entry.value);
        if (state != null) states[entry.key.toString()] = state;
      }
      return states;
    } on Object {
      return {};
    }
  }

  @override
  Future<void> write(Map<String, UploadState> states) async {
    try {
      await _instance.setString(
        _key,
        jsonEncode({
          for (final entry in states.entries) entry.key: entry.value.toJson(),
        }),
      );
    } on Object {
      // The upload still worked; only the remembered state is lost.
    }
  }
}

/// Uploads finished local rides to the server, one at a time per ride, with the local id as the idempotency key.
///
/// The work is imperative (timers, retries, persisted progress), so it stays a
/// plain repository object; its state is exposed as a stream, which Riverpod
/// turns into [uploadStatesProvider].
class RideUploadQueue {
  RideUploadQueue({
    required this.recorder,
    required this.uploader,
    required this.store,
    required this.accountId,
    required this.telemetry,
    this.serverUrl,
    this.pollInterval = const Duration(seconds: 1),
    this.onUnauthorized,
  });

  final Recorder recorder;
  final RideUploader uploader;
  final UploadStateStore store;
  final TelemetryRuntime telemetry;

  /// Uploads only the rides this member recorded.
  final String accountId;
  final String? serverUrl;
  final Duration pollInterval;
  final VoidCallback? onUnauthorized;

  final _states = <String, UploadState>{};
  final _running = <String>{};
  final _updates = StreamController<Map<String, UploadState>>.broadcast(
    sync: true,
  );
  bool _disposed = false;

  UploadState? stateFor(String rideId) => _states[rideId];

  /// A snapshot of every ride's upload state.
  Map<String, UploadState> get states => Map.unmodifiable(_states);

  /// Every change to [states], so the Record screen and the title bar share one
  /// subscription instead of each polling the queue.
  Stream<Map<String, UploadState>> get updates => _updates.stream;

  Future<void> init() async {
    _states
      ..clear()
      ..addAll(await store.read());
    recorderLog('upload: init ${_states.length} remembered ride(s)');
    await _scheduleBackground();
    _notify();
  }

  /// On opening the recorder: retry unfinished uploads and queue ready rides that were never sent.
  Future<void> resume(List<LocalRide> rides) async {
    final mine = [
      for (final ride in rides)
        if (ride.accountId == accountId) ride,
    ];
    final ids = {for (final ride in mine) ride.id};
    for (final entry in _states.entries) {
      if (ids.contains(entry.key) && _shouldRetry(entry.value)) {
        unawaited(_run(entry.key));
      }
    }
    for (final ride in mine) {
      if (!ride.isReady) continue;
      if (ride.isUploaded) {
        _states[ride.id] = UploadState(
          state: UploadState.uploaded,
          serverRideId: ride.serverRideId,
          attempts: ride.uploadAttempts,
        );
        continue;
      }
      final state = _states[ride.id];
      if (state == null || state.state == UploadState.queued) {
        await enqueue(ride.id);
      }
    }
    await _scheduleBackground();
  }

  /// Network and server hiccups are tried again when the screen opens; rejected files wait for a manual Retry.
  bool _shouldRetry(UploadState state) {
    if (state.state == UploadState.queued ||
        state.state == UploadState.uploading ||
        state.state == UploadState.processing) {
      return true;
    }
    if (!state.isFailed) return false;
    final error = state.error;
    if (error == 'offline' || error == 'timeout' || error == 'http_429') {
      return true;
    }
    if (error != null && error.startsWith('http_5')) return true;
    return false;
  }

  Future<void> enqueue(String rideId, {bool retry = false}) async {
    final existing = _states[rideId];
    if (!retry && existing?.isUploaded == true) return;
    if (_running.contains(rideId)) return;
    if (!await _owns(rideId)) {
      recorderLog('upload: $rideId belongs to another member; refused');
      return;
    }

    _states[rideId] = UploadState(
      state: UploadState.queued,
      serverRideId: existing?.serverRideId,
      attempts: existing?.attempts ?? 0,
    );
    recorderLog('upload: $rideId queued');
    await _persist();
    await _scheduleBackground();
    _notify();
    unawaited(_run(rideId));
  }

  Future<void> retry(String rideId) => enqueue(rideId, retry: true);

  Future<bool> _owns(String rideId) async {
    try {
      final rides = await recorder.listRides(accountId: accountId);
      return rides.any((ride) => ride.id == rideId);
    } on Object catch (e) {
      recorderLog('upload: could not check ride $rideId: $e');
      return false;
    }
  }

  /// Drop a ride that was deleted from the phone.
  void forget(String rideId) {
    if (_states.remove(rideId) == null) return;
    recorderLog('upload: forget $rideId');
    unawaited(_persist());
    _notify();
  }

  Future<void> _run(String rideId) async {
    if (_running.contains(rideId) || _disposed) return;
    _running.add(rideId);
    final previous = _states[rideId];
    final attempts = (previous?.attempts ?? 0) + 1;
    final started = Stopwatch()..start();
    String? resultStatus;
    recorderLog('upload: $rideId attempt $attempts');

    _set(
      rideId,
      UploadState(
        state: UploadState.uploading,
        serverRideId: previous?.serverRideId,
        attempts: attempts,
      ),
      persist: true,
    );

    try {
      unawaited(
        recorder.markUploadState(
          rideId,
          UploadState.uploading,
          attempts: attempts,
        ),
      );
      final bytes = await recorder.readFit(rideId);
      if (bytes == null || bytes.isEmpty) {
        _fail(rideId, 'no_file', attempts);
        return;
      }

      final result = await uploader.upload(bytes, rideId);
      recorderLog('upload: $rideId accepted as ${result.serverRideId}');
      _set(
        rideId,
        UploadState(
          state: UploadState.processing,
          serverRideId: result.serverRideId,
          attempts: attempts,
        ),
        persist: true,
      );

      for (var poll = 0; poll < 120; poll++) {
        final status = await uploader.status(result.serverRideId);
        recorderLog(
          'upload: $rideId poll ${poll + 1} -> ${status.status} ${status.error}',
        );
        if (!status.isDone) {
          await Future<void>.delayed(pollInterval);
          continue;
        }
        if (status.status == 'ready' || status.status == 'duplicate') {
          resultStatus = status.status;
          _set(
            rideId,
            UploadState(
              state: UploadState.uploaded,
              serverRideId: result.serverRideId,
              attempts: attempts,
            ),
            persist: true,
          );
          unawaited(
            recorder.markUploadState(
              rideId,
              UploadState.uploaded,
              serverRideId: result.serverRideId,
              attempts: attempts,
            ),
          );
          return;
        }
        _fail(rideId, status.error ?? 'server_failed', attempts);
        return;
      }

      _fail(rideId, 'timeout', attempts);
    } on ApiException catch (e) {
      if (e.code == 401) {
        onUnauthorized?.call();
        _fail(rideId, 'sign_in', attempts);
      } else {
        _fail(rideId, 'http_${e.code}', attempts);
      }
    } on RideUploadException catch (e) {
      _fail(rideId, e.code, attempts);
    } on Object catch (e) {
      recorderLog('upload: $rideId failed: $e');
      _fail(rideId, 'offline', attempts);
    } finally {
      _running.remove(rideId);
      started.stop();
      _reportRun(rideId, attempts, resultStatus, started.elapsed);
      await _persist();
      _notify();
    }
  }

  void _reportRun(
    String rideId,
    int attempts,
    String? resultStatus,
    Duration elapsed,
  ) {
    final state = _states[rideId];
    final attempt = _attemptBucket(attempts);
    if (state?.isUploaded == true) {
      final attributes = <String, Object>{
        'result': resultStatus ?? 'ready',
        'attempts': attempt,
      };
      telemetry.count('ride_upload_succeeded', 1, attributes: attributes);
      telemetry.distribution(
        'ride_upload_duration',
        elapsed.inMilliseconds,
        unit: telemetryMilliseconds,
        attributes: attributes,
      );
      telemetry.log(
        TelemetryLevel.info,
        'ride upload succeeded',
        attributes: attributes,
      );
    } else if (state?.isFailed == true) {
      final reason = state?.error ?? 'unknown';
      final attributes = <String, Object>{
        'reason': reason,
        'attempts': attempt,
      };
      telemetry.count('ride_upload_failures', 1, attributes: attributes);
      telemetry.distribution(
        'ride_upload_duration',
        elapsed.inMilliseconds,
        unit: telemetryMilliseconds,
        attributes: {...attributes, 'result': 'failed'},
      );
      telemetry.log(
        TelemetryLevel.warning,
        'ride upload failed',
        attributes: attributes,
      );
    }
  }

  static String _attemptBucket(int attempts) => attempts <= 1
      ? '1'
      : attempts == 2
      ? '2'
      : '3+';

  void _fail(String rideId, String error, int attempts) {
    recorderLog('upload: $rideId failed code=$error attempt=$attempts');
    _set(
      rideId,
      UploadState(
        state: UploadState.failed,
        serverRideId: _states[rideId]?.serverRideId,
        error: error,
        attempts: attempts,
      ),
      persist: true,
    );
    unawaited(
      recorder.markUploadState(
        rideId,
        UploadState.failed,
        serverRideId: _states[rideId]?.serverRideId,
        error: error,
        attempts: attempts,
      ),
    );
  }

  Future<void> _scheduleBackground() async {
    final url = serverUrl;
    if (url == null || url.isEmpty) return;
    try {
      await recorder.scheduleUpload(url);
    } on Object catch (e) {
      recorderLog('upload: could not schedule background work: $e');
    }
  }

  void _set(String rideId, UploadState state, {required bool persist}) {
    _states[rideId] = state;
    if (persist) unawaited(_persist());
    _notify();
  }

  Future<void> _persist() => store.write(Map.unmodifiable(_states));

  void _notify() {
    if (_disposed) return;
    telemetry.gauge(
      'ride_upload_pending',
      _states.values.where((state) => !state.isUploaded).length,
    );
    _updates.add(states);
  }

  void dispose() {
    _disposed = true;
    unawaited(_updates.close());
  }
}
