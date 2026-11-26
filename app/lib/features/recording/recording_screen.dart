import '../../core/widgets/inline_error.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../rides/ride_type_chips.dart';
import '../../l10n/generated/app_localizations.dart';
import 'recorder.dart';
import 'recording_providers.dart';
import 'recording_view_model.dart';
import 'upload_queue.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badge.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_card.dart';
import '../../core/units.dart';
import '../../core/confirm.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/form_sheet.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/stat_card.dart';

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
    return PageScaffold(
      title: context.l10n.navRecord,
      // The choices the card has no room for wait behind the menu.
      menu: PageMenu(
        buttonKey: const Key('record-settings'),
        entries: [
          PageMenuEntry(
            key: const Key('open-recorder-settings'),
            icon: Icons.tune,
            label: context.l10n.recorderSettings,
            onSelected: () => showRecorderSettings(context),
          ),
        ],
      ),
      children: [
        if (s.live)
          _LiveCard(
            state: s.snapshot,
            rideType: _rideTypeName(context.l10n, s.rideType),
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
            onStart: () =>
                _haptic(ref, notifier.start, HapticFeedback.mediumImpact),
          ),
        if (s.errorCode != null)
          InlineError(
            recorderErrorText(context.l10n, s.errorCode),
            key: const Key('record-error'),
          ),
        SectionCard(
          key: const Key('local-rides'),
          title: context.l10n.onThisPhone,
          children: [
            if (s.loading)
              const LoadingState.rows(key: Key('local-rides-loading'), count: 2)
            else if (s.recordedRides.isEmpty)
              EmptyState(
                key: const Key('no-local-rides'),
                icon: Icons.directions_bike_outlined,
                message: context.l10n.noLocalRides,
                framed: false,
              )
            else
              for (final ride in s.recordedRides)
                _LocalRideRow(
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
      ],
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

/// The height of the recorder's main controls: pressed with gloves or a thumb, mid-ride.
const double _bigControl = 56;

/// One big Start, the ride type as chips, auto-pause and the strap: everything a ride needs, on the
/// card, so starting it takes no sheet. The e-bike switch and the rest stay in the settings sheet,
/// behind the page's menu.
class _StartCard extends ConsumerStatefulWidget {
  const _StartCard({
    required this.busy,
    required this.loading,
    required this.autoPause,
    required this.rideType,
    required this.onStart,
  });

  final bool busy;
  final bool loading;
  final bool autoPause;
  final String rideType;
  final Future<void> Function() onStart;

  @override
  ConsumerState<_StartCard> createState() => _StartCardState();
}

class _StartCardState extends ConsumerState<_StartCard> {
  bool _pairing = false;

  Future<void> _pair() async {
    final notifier = ref.read(recordingViewModelProvider.notifier);
    final sensor = await showSheet<SensorInfo>(
      context,
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
    final theme = Theme.of(context);
    final s = ref.watch(recordingViewModelProvider);
    final notifier = ref.read(recordingViewModelProvider.notifier);
    final sensorsSupported =
        ref.watch(recorderProvider)?.sensorsSupported ?? false;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          Text(l10n.recordRide, style: theme.textTheme.titleMedium),
          FilledButton.icon(
            key: const Key('record-start'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(_bigControl),
            ),
            onPressed: widget.busy || widget.loading ? null : widget.onStart,
            icon: const Icon(Icons.play_arrow),
            label: Text(widget.busy ? l10n.starting : l10n.startRecording),
          ),
          // Said before the system asks: starting needs the position and keeps a notification.
          Text(
            l10n.recordPermissionHelp,
            key: const Key('record-permission-help'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Wrap(
            key: const Key('record-ride-type'),
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final id in _rideTypeIds)
                ChoiceChip(
                  key: Key('record-type-$id'),
                  label: Text(_rideTypeName(l10n, id)),
                  selected: widget.rideType == id,
                  onSelected: (_) => notifier.setRideType(id),
                ),
            ],
          ),
          SwitchListTile(
            key: const Key('auto-pause-switch'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.pauseWhenStopped),
            subtitle: Text(l10n.pauseWhenStoppedHelp),
            value: widget.autoPause,
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
    );
  }
}

/// The ride types a ride can be recorded as, the order the chips are drawn in: exactly the design's set
/// (`docs/design/pages/rides/RecordPhone.html`), which has no track and no virtual ride.
const _rideTypeIds = ['road', 'gravel', 'mountain', 'indoor', 'commute'];

/// The settings the card has no room for: the menu opens them in a sheet, and the sheet watches the
/// recorder itself, so a switch shows at once.
Future<void> showRecorderSettings(BuildContext context) =>
    showSheet<void>(context, builder: (_) => const _SettingsSheet());

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(recordingViewModelProvider);
    final notifier = ref.read(recordingViewModelProvider.notifier);
    return SheetFrame(
      title: l10n.recorderSettings,
      bottom: FilledButton(
        key: const Key('record-settings-done'),
        onPressed: () => Navigator.of(context).pop(),
        child: Text(l10n.done),
      ),
      children: [
        SwitchListTile(
          key: const Key('record-ebike-switch'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.recorderEbike),
          subtitle: Text(l10n.recorderEbikeHelp),
          value: s.ebike,
          onChanged: notifier.setEbike,
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
    required this.rideType,
    required this.sensorsSupported,
    required this.busy,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final RecorderSnapshot state;

  /// The name the card carries while the ride runs: the ride type the member chose, the only name a ride
  /// has on the phone before it is saved.
  final String rideType;
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: DefaultTextStyle.merge(
            style: theme.textTheme.bodyMedium,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    rideType,
                    key: const Key('record-name'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
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
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        stopwatch(state.movingS),
                        key: const Key('record-clock'),
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  // The clock counts moving time, and the design says so under it.
                  Text(
                    l10n.moving,
                    key: const Key('record-moving'),
                    textAlign: TextAlign.center,
                    style: muted,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xl,
                    runSpacing: AppSpacing.sm,
                    children: [
                      if (state.elapsedS != state.movingS)
                        StatFigure(
                          label: l10n.statElapsedTime,
                          value: stopwatch(state.elapsedS),
                        ),
                      StatFigure(
                        label: l10n.statDistance,
                        value: km(units, state.distanceM),
                      ),
                      StatFigure(
                        label: l10n.statAverageSpeed,
                        value: kmh(units, state.speedMs),
                      ),
                      StatFigure(
                        label: l10n.gps,
                        value: state.accuracyM == null
                            ? '–'
                            : '±${state.accuracyM!.round()} m',
                      ),
                      if (state.sensorName != null)
                        StatFigure(
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
                          size: AppIconSize.small,
                          color: state.sensorConnected
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
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
                  const SizedBox(height: AppSpacing.xl),
                  // Two full-width controls one above the other: they never overflow at a narrow width or a
                  // large text size, and each stays a big target.
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.md,
                    children: [
                      OutlinedButton.icon(
                        key: Key(paused ? 'record-resume' : 'record-pause'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(_bigControl),
                        ),
                        onPressed: busy ? null : (paused ? onResume : onPause),
                        icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                        label: Text(paused ? l10n.resume : l10n.pause),
                      ),
                      FilledButton.icon(
                        key: const Key('record-stop'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(_bigControl),
                        ),
                        onPressed: busy ? null : onStop,
                        icon: const Icon(Icons.stop),
                        label: Text(l10n.stopAndSave),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Said under the card, as the design draws it (docs/design/pages/rides/RecordingLivePhone.html).
        Text(
          l10n.recordingScreenOff,
          key: const Key('record-screen-off'),
          textAlign: TextAlign.center,
          style: muted,
        ),
      ],
    );
  }
}

class _LocalRideRow extends ConsumerWidget {
  const _LocalRideRow({
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
    // What the row is: the kind of ride, then when it happened and how far, then how its upload stands.
    return ListTile(
      key: Key('local-ride-${ride.id}'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.directions_bike_outlined),
      title: Text(_rideTypeName(l10n, ride.rideType ?? 'road')),
      subtitle: Text(
        '${dayNumber(ride.startedAt)} ${monthShort(ride.startedAt)} · '
        '${km(units, ride.distanceM)}'
        '${error == null ? '' : '\n$error'}',
      ),
      isThreeLine: error != null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          if (ride.isInterrupted && upload == null)
            TextButton(
              key: Key('finalize-${ride.id}'),
              onPressed: busy ? null : onFinalize,
              child: Text(l10n.finish),
            ),
          // The upload stands as a badge of its own, coloured by what it says.
          Flexible(
            child: AppBadge(
              _stateText(l10n),
              key: Key('local-ride-state-${ride.id}'),
              tone: _uploaded
                  ? AppBadgeTone.good
                  : _failed || ride.isFailed
                  ? AppBadgeTone.bad
                  : AppBadgeTone.neutral,
            ),
          ),
          PageMenu(
            buttonKey: Key('ride-actions-${ride.id}'),
            entries: [
              // What the row can do about its upload, then the one way out of the phone.
              if (canUpload)
                PageMenuEntry(
                  key: Key(
                    _failed ? 'retry-upload-${ride.id}' : 'upload-${ride.id}',
                  ),
                  icon: _failed ? Icons.refresh : Icons.cloud_upload_outlined,
                  label: _failed ? l10n.retry : l10n.upload,
                  onSelected: busy
                      ? () {}
                      : (_failed ? onRetryUpload : onUpload) ?? () {},
                ),
              PageMenuEntry(
                key: Key('delete-${ride.id}'),
                icon: Icons.delete_outline,
                label: l10n.deleteFromPhone,
                destructive: true,
                onSelected: busy
                    ? () {}
                    : () => scheduleMicrotask(() async {
                        if (!context.mounted) return;
                        final sure = await confirmDestructive(
                          context,
                          title: l10n.deleteLocalRideTitle,
                          body: _uploaded
                              ? l10n.deleteLocalRideBodyUploaded
                              : l10n.deleteLocalRideBodyNotUploaded,
                          action: l10n.delete,
                          key: const Key('confirm-delete-local-ride'),
                        );
                        if (sure) onDelete();
                      }),
              ),
            ],
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
    return SheetFrame(
      key: const Key('sensor-sheet'),
      title: l10n.pairStrapTitle,
      children: [
        Text(l10n.pairStrapHelp),
        if (_scanning) ...[
          const LinearProgressIndicator(),
          Text(l10n.searchingStraps, key: const Key('sensor-searching')),
        ],
        if (_errorCode != null || _found == null && !_scanning)
          InlineError(
            recorderErrorText(l10n, _errorCode),
            key: const Key('sensor-sheet-error'),
          ),
        if (found != null && found.isEmpty && !_scanning)
          Text(l10n.noStraps, key: const Key('sensor-none')),
        for (final sensor in found ?? const <SensorInfo>[])
          ListTile(
            key: Key('sensor-${sensor.address}'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.favorite),
            title: Text(sensor.name),
            subtitle: Text(sensor.address),
            trailing: sensor.rssi == null
                ? null
                : Text(l10n.sensorSignalStrength(sensor.rssi!)),
            onTap: () => Navigator.of(context).pop(sensor),
          ),
        if (!_scanning)
          TextButton(
            key: const Key('sensor-scan-again'),
            onPressed: _scan,
            child: Text(l10n.searchAgain),
          ),
      ],
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
