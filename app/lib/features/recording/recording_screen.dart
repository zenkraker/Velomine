import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../l10n/generated/app_localizations.dart';
import 'recorder.dart';
import 'recording_providers.dart';
import 'recording_view_model.dart';
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

/// Record a ride with the phone, and see the rides saved on this phone.
class RecordingScreen extends ConsumerWidget {
  const RecordingScreen({super.key});

  Future<void> _pairSensor(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(recordingViewModelProvider.notifier);
    final sensor = await showModalBottomSheet<SensorInfo>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SensorSheet(
        requestPermission: notifier.requestSensorPermissions,
        scan: notifier.scanSensors,
      ),
    );
    if (sensor == null) return;
    await notifier.pairSensor(sensor);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(recordingViewModelProvider);
    final recorder = ref.watch(recorderProvider);
    final uploadsEnabled = ref.watch(uploadQueueProvider) != null;
    final notifier = ref.read(recordingViewModelProvider.notifier);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (s.live)
            _LiveCard(
              state: s.snapshot,
              sensorsSupported: recorder?.sensorsSupported ?? false,
              busy: s.command.running,
              onPause: notifier.pause,
              onResume: notifier.resume,
              onStop: notifier.stop,
            )
          else
            _StartCard(
              busy: s.command.running,
              loading: s.loading,
              autoPause: s.autoPause,
              rideType: s.rideType,
              ebike: s.ebike,
              onAutoPause: notifier.setAutoPause,
              onRideType: notifier.setRideType,
              onEbike: notifier.setEbike,
              onStart: notifier.start,
              sensorsSupported: recorder?.sensorsSupported ?? false,
              sensorName: s.snapshot.sensorName,
              sensorStatus: s.snapshot.sensorStatus,
              onPair: () => _pairSensor(context, ref),
              onForget: notifier.forgetSensor,
            ),
          if (s.errorCode != null) ...[
            const SizedBox(height: 12),
            Text(
              recorderErrorText(context.l10n, s.errorCode),
              key: const Key('record-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            context.l10n.onThisPhone,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (s.rides.isEmpty && !s.loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                context.l10n.noLocalRides,
                key: const Key('no-local-rides'),
              ),
            )
          else
            for (final ride in s.rides)
              _LocalRideCard(
                ride: ride,
                upload: s.uploads[ride.id],
                busy: s.command.running,
                onFinalize: () => notifier.finalizeRide(ride.id),
                onDelete: () => notifier.deleteRide(ride.id),
                onUpload: uploadsEnabled
                    ? () => notifier.uploadRide(ride.id)
                    : null,
                onRetryUpload: uploadsEnabled
                    ? () => notifier.retryUpload(ride.id)
                    : null,
              ),
        ],
      ),
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({
    required this.busy,
    required this.loading,
    required this.autoPause,
    required this.rideType,
    required this.ebike,
    required this.onAutoPause,
    required this.onRideType,
    required this.onEbike,
    required this.onStart,
    required this.sensorsSupported,
    required this.sensorName,
    required this.sensorStatus,
    required this.onPair,
    required this.onForget,
  });

  final bool busy;
  final bool loading;
  final bool autoPause;
  final String rideType;
  final bool ebike;
  final Future<void> Function(bool value) onAutoPause;
  final Future<void> Function(String value) onRideType;
  final Future<void> Function(bool value) onEbike;
  final Future<void> Function() onStart;
  final bool sensorsSupported;
  final String? sensorName;
  final String sensorStatus;
  final VoidCallback onPair;
  final Future<void> Function() onForget;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recordRide,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(l10n.recordIntro),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('record-start'),
              onPressed: busy || loading ? null : onStart,
              icon: const Icon(Icons.play_arrow),
              label: Text(busy ? l10n.starting : l10n.startRecording),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: InputDecoration(labelText: l10n.recorderRideType),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: const Key('record-ride-type'),
                  value: rideType,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: 'road',
                      child: Text(l10n.bikeKindRoad),
                    ),
                    DropdownMenuItem(
                      value: 'gravel',
                      child: Text(l10n.bikeKindGravel),
                    ),
                    DropdownMenuItem(
                      value: 'mountain',
                      child: Text(l10n.bikeKindMountain),
                    ),
                    DropdownMenuItem(
                      value: 'track',
                      child: Text(l10n.bikeKindTrack),
                    ),
                    DropdownMenuItem(
                      value: 'indoor',
                      child: Text(l10n.rideTypeIndoor),
                    ),
                    DropdownMenuItem(
                      value: 'virtual',
                      child: Text(l10n.rideTypeVirtual),
                    ),
                    DropdownMenuItem(
                      value: 'commute',
                      child: Text(l10n.rideTypeCommute),
                    ),
                  ],
                  onChanged: busy || loading
                      ? null
                      : (value) {
                          if (value != null) onRideType(value);
                        },
                ),
              ),
            ),
            SwitchListTile(
              key: const Key('record-ebike-switch'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.recorderEbike),
              subtitle: Text(l10n.recorderEbikeHelp),
              value: ebike,
              onChanged: busy || loading ? null : onEbike,
            ),
            SwitchListTile(
              key: const Key('auto-pause-switch'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.pauseWhenStopped),
              subtitle: Text(l10n.pauseWhenStoppedHelp),
              value: autoPause,
              onChanged: busy || loading ? null : onAutoPause,
            ),
            if (sensorsSupported) ...[
              const Divider(height: 32),
              _SensorTile(
                name: sensorName,
                status: sensorStatus,
                busy: busy || loading,
                onPair: onPair,
                onForget: onForget,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The paired strap on the start card. Pairing is remembered; the connection belongs to the ride.
class _SensorTile extends StatelessWidget {
  const _SensorTile({
    required this.name,
    required this.status,
    required this.busy,
    required this.onPair,
    required this.onForget,
  });

  final String? name;
  final String status;
  final bool busy;
  final VoidCallback onPair;
  final Future<void> Function() onForget;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final paired = name != null;
    final connected = status == 'connected';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        paired ? Icons.favorite : Icons.monitor_heart_outlined,
        color: connected ? Theme.of(context).colorScheme.error : null,
      ),
      title: Text(name ?? l10n.heartRateStrap),
      subtitle: Text(paired ? sensorStatusText(l10n, status) : l10n.nonePaired),
      trailing: TextButton(
        key: Key(paired ? 'forget-sensor' : 'pair-sensor'),
        onPressed: busy
            ? null
            : () {
                if (paired) {
                  onForget();
                } else {
                  onPair();
                }
              },
        child: Text(paired ? l10n.forget : l10n.pair),
      ),
    );
  }
}

/// What the status codes from the phone mean to a member.
String sensorStatusText(AppLocalizations l10n, String status) =>
    switch (status) {
      'connected' => l10n.sensorConnected,
      'connecting' => l10n.sensorConnecting,
      'off' => l10n.bluetoothOffState,
      'denied' => l10n.sensorDeniedState,
      _ => l10n.sensorConnectsOnStart,
    };

class _LiveCard extends StatelessWidget {
  const _LiveCard({
    required this.state,
    required this.sensorsSupported,
    required this.busy,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final RecorderSnapshot state;
  final bool sensorsSupported;
  final bool busy;
  final Future<void> Function() onPause;
  final Future<void> Function() onResume;
  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final paused = state.isPaused;
    final autoPaused = paused && state.autoPaused;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  autoPaused
                      ? Icons.motion_photos_paused
                      : paused
                      ? Icons.pause_circle_outline
                      : Icons.fiber_manual_record,
                  color: paused
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  autoPaused
                      ? l10n.autoPaused
                      : paused
                      ? l10n.paused
                      : l10n.recording,
                  key: const Key('record-state'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              stopwatch(state.elapsedS),
              key: const Key('record-clock'),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _Value(label: l10n.moving, value: stopwatch(state.movingS)),
                _Value(label: l10n.statDistance, value: km(state.distanceM)),
                _Value(label: l10n.statAverageSpeed, value: kmh(state.speedMs)),
                _Value(
                  label: l10n.gps,
                  value: state.accuracyM == null
                      ? '–'
                      : '±${state.accuracyM!.round()} m',
                ),
                if (state.sensorName != null)
                  _Value(
                    label: l10n.heartRate,
                    value: state.heartRateBpm == null
                        ? '–'
                        : '${state.heartRateBpm} bpm',
                    valueKey: const Key('readout-heartrate'),
                  ),
              ],
            ),
            if (sensorsSupported && state.sensorName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    state.sensorConnected
                        ? Icons.favorite
                        : Icons.monitor_heart_outlined,
                    size: 16,
                    color: state.sensorConnected
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    state.sensorName!,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sensorStatusText(l10n, state.sensorStatus),
                    key: const Key('sensor-status'),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                FilledButton.icon(
                  key: Key(paused ? 'record-resume' : 'record-pause'),
                  onPressed: busy ? null : (paused ? onResume : onPause),
                  icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                  label: Text(paused ? l10n.resume : l10n.pause),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  key: const Key('record-stop'),
                  onPressed: busy ? null : onStop,
                  icon: const Icon(Icons.stop),
                  label: Text(l10n.stopAndSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value, this.valueKey});

  final String label;
  final String value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(
          value,
          key: valueKey,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _LocalRideCard extends StatelessWidget {
  const _LocalRideCard({
    required this.ride,
    required this.upload,
    required this.busy,
    required this.onFinalize,
    required this.onDelete,
    this.onUpload,
    this.onRetryUpload,
  });

  final LocalRide ride;
  final UploadState? upload;
  final bool busy;
  final VoidCallback onFinalize;
  final VoidCallback onDelete;
  final VoidCallback? onUpload;
  final VoidCallback? onRetryUpload;

  bool get _uploaded => ride.isUploaded || upload?.isUploaded == true;

  bool get _failed => upload?.isFailed == true || ride.uploadState == 'failed';

  String _stateText(AppLocalizations l10n) {
    if (_uploaded) return l10n.uploaded;
    if (upload != null) {
      return switch (upload!.state) {
        UploadState.uploading => l10n.uploading,
        UploadState.processing => l10n.serverReading,
        UploadState.queued => l10n.waitingToUpload,
        UploadState.failed => l10n.uploadFailed,
        _ => l10n.readyToUpload,
      };
    }
    return switch (ride.uploadState) {
      UploadState.uploading => l10n.uploading,
      UploadState.processing => l10n.serverReading,
      UploadState.failed => l10n.uploadFailed,
      _ => _rideStateText(l10n),
    };
  }

  String _rideStateText(AppLocalizations l10n) => switch (ride.state) {
    'recording' => l10n.recordingOnPhone,
    'paused' => l10n.paused,
    'ready' => l10n.readyToUpload,
    'interrupted' => l10n.interrupted,
    'failed' => l10n.couldNotBeSaved,
    _ => ride.state,
  };

  String? _errorText(AppLocalizations l10n) {
    if (_failed) {
      return uploadErrorText(l10n, upload?.error ?? ride.uploadError);
    }
    if (ride.isFailed) return recorderErrorText(l10n, ride.error);
    if (ride.isInterrupted) return l10n.interruptedHelp;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final error = _errorText(l10n);
    final uploading =
        ride.uploadState == UploadState.uploading ||
        ride.uploadState == UploadState.processing ||
        (upload?.isBusy ?? false);
    final canUpload =
        ride.isReady && !_uploaded && !uploading && onUpload != null;
    return Card(
      key: Key('local-ride-${ride.id}'),
      child: Column(
        children: [
          ListTile(
            title: Text(dateTime(ride.startedAt)),
            subtitle: Text(
              '${_stateText(l10n)} · ${km(ride.distanceM)} · ${stopwatch(ride.movingS)}'
              '${error == null ? '' : '\n$error'}',
            ),
            isThreeLine: error != null,
            leading: Icon(
              _uploaded
                  ? Icons.cloud_done_outlined
                  : ride.isFailed || _failed
                  ? Icons.error_outline
                  : ride.isReady
                  ? Icons.check_circle_outline
                  : Icons.timer_outlined,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ride.isInterrupted && upload == null)
                  TextButton(
                    key: Key('finalize-${ride.id}'),
                    onPressed: busy ? null : onFinalize,
                    child: Text(l10n.finish),
                  ),
                if (canUpload)
                  TextButton(
                    key: Key(
                      _failed ? 'retry-upload-${ride.id}' : 'upload-${ride.id}',
                    ),
                    onPressed: busy
                        ? null
                        : _failed
                        ? onRetryUpload
                        : onUpload,
                    child: Text(_failed ? l10n.retry : l10n.upload),
                  ),
                IconButton(
                  key: Key('delete-${ride.id}'),
                  tooltip: l10n.deleteFromPhone,
                  onPressed: busy ? null : onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Finds a strap and returns the one the member taps. Pairing is saved by the recorder, not here.
class _SensorSheet extends StatefulWidget {
  const _SensorSheet({required this.requestPermission, required this.scan});

  final Future<bool> Function() requestPermission;
  final Future<List<SensorInfo>> Function() scan;

  @override
  State<_SensorSheet> createState() => _SensorSheetState();
}

class _SensorSheetState extends State<_SensorSheet> {
  List<SensorInfo>? _found;
  String? _errorCode;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _errorCode = null;
      _found = null;
    });
    try {
      final granted = await widget.requestPermission();
      if (!mounted) return;
      if (!granted) {
        setState(() {
          _scanning = false;
          _errorCode = 'bluetooth_denied';
        });
        return;
      }
      final found = await widget.scan();
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _found = found;
      });
    } on RecorderException catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _errorCode = e.code;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _errorCode = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final found = _found;
    return SafeArea(
      key: const Key('sensor-sheet'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.pairStrapTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(l10n.pairStrapHelp),
            const SizedBox(height: 16),
            if (_scanning) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
              Text(l10n.searchingStraps, key: const Key('sensor-searching')),
            ],
            if (_errorCode != null || _found == null && !_scanning)
              Text(
                recorderErrorText(l10n, _errorCode),
                key: const Key('sensor-sheet-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (found != null && found.isEmpty && !_scanning)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(l10n.noStraps, key: const Key('sensor-none')),
              ),
            for (final sensor in found ?? const <SensorInfo>[])
              ListTile(
                key: Key('sensor-${sensor.address}'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.favorite),
                title: Text(sensor.name),
                subtitle: Text(sensor.address),
                trailing: sensor.rssi == null
                    ? null
                    : Text('${sensor.rssi} dBm'),
                onTap: () => Navigator.of(context).pop(sensor),
              ),
            const SizedBox(height: 8),
            if (!_scanning)
              TextButton(
                key: const Key('sensor-scan-again'),
                onPressed: _scan,
                child: Text(l10n.searchAgain),
              ),
          ],
        ),
      ),
    );
  }
}

String uploadErrorText(AppLocalizations l10n, String? code) => switch (code) {
  'no_file' => l10n.uploadNoFile,
  'offline' => l10n.uploadOffline,
  'sign_in' => l10n.uploadSignIn,
  'timeout' => l10n.uploadTimeout,
  'server_failed' => l10n.uploadServerFailed,
  _ when code?.startsWith('http_') == true => l10n.uploadHttpRefused(
    code!.substring(5),
  ),
  _ => l10n.uploadFailedGeneric,
};
