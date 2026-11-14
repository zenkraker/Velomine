import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/motion.dart';
import '../rides/ride_type_chips.dart';
import '../../l10n/generated/app_localizations.dart';
import 'recorder.dart';
import 'recording_providers.dart';
import 'recording_view_model.dart';
import 'upload_queue.dart';
import '../../core/tokens.dart';
import '../../core/units.dart';
import '../../core/widgets/stat_tile.dart';

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

  /// Runs a recorder command and confirms it with a short vibration, but only once it succeeded.
  Future<void> _haptic(
    WidgetRef ref,
    Future<void> Function() command,
    Future<void> Function() feedback,
  ) async {
    await command();
    final state = ref.read(recordingViewModelProvider);
    // The command finishes Ok even when the recorder reports a failure, so the error code decides.
    if (!kIsWeb && state.command.completed && state.errorCode == null) {
      await feedback();
    }
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
              onPause: () =>
                  _haptic(ref, notifier.pause, HapticFeedback.lightImpact),
              onResume: () =>
                  _haptic(ref, notifier.resume, HapticFeedback.mediumImpact),
              onStop: () =>
                  _haptic(ref, notifier.stop, HapticFeedback.heavyImpact),
            )
          else
            _StartCard(
              busy: s.command.running,
              loading: s.loading,
              autoPause: s.autoPause,
              rideType: s.rideType,
              ebike: s.ebike,
              onStart: () =>
                  _haptic(ref, notifier.start, HapticFeedback.mediumImpact),
              sensorName: s.snapshot.sensorName,
            ),
          if (s.errorCode != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              recorderErrorText(context.l10n, s.errorCode),
              key: const Key('record-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(
            context.l10n.onThisPhone,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (s.recordedRides.isEmpty && !s.loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                context.l10n.noLocalRides,
                key: const Key('no-local-rides'),
              ),
            )
          else
            for (final ride in s.recordedRides)
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

/// The name of a recorder ride type, including the ones a saved ride has no field for.
String _rideTypeName(AppLocalizations l10n, String id) => switch (id) {
  'indoor' => l10n.rideTypeIndoor,
  'virtual' => l10n.rideTypeVirtual,
  'commute' => l10n.rideTypeCommute,
  _ => disciplineName(l10n, id),
};

class _StartCard extends StatelessWidget {
  const _StartCard({
    required this.busy,
    required this.loading,
    required this.autoPause,
    required this.rideType,
    required this.ebike,
    required this.onStart,
    required this.sensorName,
  });

  final bool busy;
  final bool loading;
  final bool autoPause;
  final String rideType;
  final bool ebike;
  final Future<void> Function() onStart;
  final String? sensorName;

  /// What the ride will be recorded as, in one line, so Start needs no scrolling first.
  String _summary(BuildContext context) {
    final l10n = context.l10n;
    return [
      _rideTypeName(l10n, rideType),
      if (ebike) l10n.recorderEbike,
      if (autoPause) l10n.pauseWhenStopped,
      ?sensorName,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            Text(
              l10n.recordRide,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            // Said before the system asks: starting needs the position and keeps a notification.
            Text(
              l10n.recordPermissionHelp,
              key: const Key('record-permission-help'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              key: const Key('record-start'),
              onPressed: busy || loading ? null : onStart,
              icon: const Icon(Icons.play_arrow),
              label: Text(busy ? l10n.starting : l10n.startRecording),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _summary(context),
                    key: const Key('record-settings-summary'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  key: const Key('record-settings'),
                  tooltip: l10n.recorderSettings,
                  onPressed: () => showRecorderSettings(context),
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The choices a ride needs before it starts: type, e-bike, auto-pause and the strap.
///
/// The sheet watches the recorder itself, so a strap paired from inside it appears without reopening.
Future<void> showRecorderSettings(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: AnimationStyle(
        duration: motionDuration(context, AppMotion.standard),
      ),
      builder: (_) => const _SettingsSheet(),
    );

class _SettingsSheet extends ConsumerStatefulWidget {
  const _SettingsSheet();

  @override
  ConsumerState<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<_SettingsSheet> {
  bool _pairing = false;

  Future<void> _pair() async {
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
    setState(() => _pairing = true);
    await notifier.pairSensor(sensor);
    if (mounted) setState(() => _pairing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = ref.watch(recordingViewModelProvider);
    final notifier = ref.read(recordingViewModelProvider.notifier);
    final sensorsSupported =
        ref.watch(recorderProvider)?.sensorsSupported ?? false;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                Text(
                  l10n.recorderSettings,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                DropdownButtonFormField<String>(
                  key: const Key('record-ride-type'),
                  initialValue: s.rideType,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.recorderRideType),
                  items: [
                    for (final id in const [
                      'road',
                      'gravel',
                      'mountain',
                      'track',
                      'indoor',
                      'virtual',
                      'commute',
                    ])
                      DropdownMenuItem(
                        value: id,
                        child: Text(_rideTypeName(l10n, id)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) notifier.setRideType(value);
                  },
                ),
                // The strap row is what needs the room at the bottom of a phone sheet, so the two
                // switches stay to one line each.
                SwitchListTile(
                  key: const Key('record-ebike-switch'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(l10n.recorderEbike),
                  value: s.ebike,
                  onChanged: notifier.setEbike,
                ),
                SwitchListTile(
                  key: const Key('auto-pause-switch'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(l10n.pauseWhenStopped),
                  subtitle: Text(l10n.pauseWhenStoppedHelp),
                  value: s.autoPause,
                  onChanged: notifier.setAutoPause,
                ),
                if (sensorsSupported)
                  _SensorTile(
                    name: s.snapshot.sensorName,
                    status: s.snapshot.sensorStatus,
                    busy: _pairing,
                    onPair: _pair,
                    onForget: notifier.forgetSensor,
                  ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const Key('record-settings-done'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.done),
            ),
          ),
        ),
      ],
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

class _LiveCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final units = ref.watch(unitsChoiceViewModelProvider);
    final paused = state.isPaused;
    final autoPaused = paused && state.autoPaused;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
                const SizedBox(width: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.md),
            Text(
              stopwatch(state.elapsedS),
              key: const Key('record-clock'),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xl,
              runSpacing: 8,
              children: [
                StatTile(label: l10n.moving, value: stopwatch(state.movingS)),
                StatTile(
                  label: l10n.statDistance,
                  value: km(units, state.distanceM),
                ),
                StatTile(
                  label: l10n.statAverageSpeed,
                  value: kmh(units, state.speedMs),
                ),
                StatTile(
                  label: l10n.gps,
                  value: state.accuracyM == null
                      ? '–'
                      : '±${state.accuracyM!.round()} m',
                ),
                if (state.sensorName != null)
                  StatTile(
                    label: l10n.heartRate,
                    value: state.heartRateBpm == null
                        ? '–'
                        : '${state.heartRateBpm} bpm',
                    valueKey: const Key('readout-heartrate'),
                  ),
              ],
            ),
            if (sensorsSupported && state.sensorName != null) ...[
              const SizedBox(height: AppSpacing.sm),
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
                  const SizedBox(width: AppSpacing.sm),
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

class _LocalRideCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final units = ref.watch(unitsChoiceViewModelProvider);
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
              '${_stateText(l10n)} · ${km(units, ride.distanceM)} · ${stopwatch(ride.movingS)}'
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
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.pairStrapHelp),
            const SizedBox(height: AppSpacing.lg),
            if (_scanning) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
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
            const SizedBox(height: AppSpacing.sm),
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
