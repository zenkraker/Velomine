import 'package:flutter/material.dart';

import '../../core/format.dart';
import 'recorder.dart';
import 'recorder_factory.dart';
import 'recorder_settings.dart';
import 'recording_controller.dart';
import 'ride_uploader.dart';
import 'upload_queue.dart';

/// Record a ride with the phone, and see the rides saved on this phone.
class RecordingScreen extends StatefulWidget {
  const RecordingScreen({
    super.key,
    this.recorder,
    this.uploader,
    this.onUnauthorized,
    this.uploadStore,
    this.settingsStore,
    this.serverUrl,
    this.uploadPollInterval = const Duration(seconds: 1),
  });

  /// Tests pass a fake; the app uses the native service.
  final Recorder? recorder;

  /// Null in tests that only cover recording; the app passes the server uploader.
  final RideUploader? uploader;

  final VoidCallback? onUnauthorized;
  final UploadStateStore? uploadStore;
  final RecorderSettingsStore? settingsStore;
  final String? serverUrl;
  final Duration uploadPollInterval;

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late final Recorder _recorder = widget.recorder ?? createRecorder();
  late final RecordingController _controller = RecordingController(
    recorder: _recorder,
    settingsStore: widget.settingsStore,
    uploads: widget.uploader == null
        ? null
        : RideUploadQueue(
            recorder: _recorder,
            uploader: widget.uploader!,
            store: widget.uploadStore ?? PreferencesUploadStateStore(),
            serverUrl: widget.serverUrl,
            pollInterval: widget.uploadPollInterval,
            onUnauthorized: widget.onUnauthorized,
          ),
  );

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;
        final live = state.isRecording || state.isPaused;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              if (live)
                _LiveCard(
                  state: state,
                  busy: _controller.busy,
                  onPause: _controller.pause,
                  onResume: _controller.resume,
                  onStop: _controller.stop,
                )
              else
                _StartCard(
                  busy: _controller.busy,
                  loading: _controller.loading,
                  autoPause: _controller.autoPause,
                  onAutoPause: _controller.setAutoPause,
                  onStart: _controller.start,
                ),
              if (_controller.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _controller.error!,
                  key: const Key('record-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'On this phone',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (_controller.rides.isEmpty && !_controller.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No rides recorded on this phone yet.',
                    key: Key('no-local-rides'),
                  ),
                )
              else
                for (final ride in _controller.rides)
                  _LocalRideCard(
                    ride: ride,
                    upload: _controller.uploads?.stateFor(ride.id),
                    busy: _controller.busy,
                    onFinalize: () => _controller.finalizeRide(ride.id),
                    onDelete: () => _controller.deleteRide(ride.id),
                    onUpload: _controller.uploads == null
                        ? null
                        : () => _controller.uploads!.enqueue(ride.id),
                    onRetryUpload: _controller.uploads == null
                        ? null
                        : () => _controller.uploads!.retry(ride.id),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({
    required this.busy,
    required this.loading,
    required this.autoPause,
    required this.onAutoPause,
    required this.onStart,
  });

  final bool busy;
  final bool loading;
  final bool autoPause;
  final Future<void> Function(bool value) onAutoPause;
  final Future<void> Function() onStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Record a ride',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'The phone keeps recording with the screen off. Your ride is saved '
              'on this phone first; uploads are added next.',
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('record-start'),
              onPressed: busy || loading ? null : onStart,
              icon: const Icon(Icons.play_arrow),
              label: Text(busy ? 'Starting…' : 'Start recording'),
            ),
            SwitchListTile(
              key: const Key('auto-pause-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Pause when stopped'),
              subtitle: const Text(
                'After 3 seconds at 0.1 km/h or slower; resumes above it.',
              ),
              value: autoPause,
              onChanged: busy || loading ? null : onAutoPause,
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({
    required this.state,
    required this.busy,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final RecorderSnapshot state;
  final bool busy;
  final Future<void> Function() onPause;
  final Future<void> Function() onResume;
  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
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
                      ? 'Auto-paused'
                      : paused
                      ? 'Paused'
                      : 'Recording',
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
                _Value(label: 'Moving', value: stopwatch(state.movingS)),
                _Value(label: 'Distance', value: km(state.distanceM)),
                _Value(label: 'Speed', value: kmh(state.speedMs)),
                _Value(
                  label: 'GPS',
                  value: state.accuracyM == null
                      ? '–'
                      : '±${state.accuracyM!.round()} m',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                FilledButton.icon(
                  key: Key(paused ? 'record-resume' : 'record-pause'),
                  onPressed: busy ? null : (paused ? onResume : onPause),
                  icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                  label: Text(paused ? 'Resume' : 'Pause'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  key: const Key('record-stop'),
                  onPressed: busy ? null : onStop,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop and save'),
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
  const _Value({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
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

  String _stateText() {
    if (_uploaded) return 'Uploaded';
    if (upload != null) {
      return switch (upload!.state) {
        UploadState.uploading => 'Uploading…',
        UploadState.processing => 'Server is reading it…',
        UploadState.queued => 'Waiting to upload',
        UploadState.failed => 'Upload failed',
        _ => 'Ready to upload',
      };
    }
    return switch (ride.uploadState) {
      UploadState.uploading => 'Uploading…',
      UploadState.processing => 'Server is reading it…',
      UploadState.failed => 'Upload failed',
      _ => _rideStateText(),
    };
  }

  String _rideStateText() => switch (ride.state) {
    'recording' => 'Recording on this phone',
    'paused' => 'Paused',
    'ready' => 'Ready to upload',
    'interrupted' => 'Interrupted',
    'failed' => 'Could not be saved',
    _ => ride.state,
  };

  String? _errorText() {
    if (_failed) {
      return uploadErrorText(upload?.error ?? ride.uploadError);
    }
    if (ride.isFailed) return recorderErrorText(ride.error);
    if (ride.isInterrupted) {
      return 'The recording stopped unexpectedly. Finish it to keep the ride.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final error = _errorText();
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
              '${_stateText()} · ${km(ride.distanceM)} · ${stopwatch(ride.movingS)}'
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
                    child: const Text('Finish'),
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
                    child: Text(_failed ? 'Retry' : 'Upload'),
                  ),
                IconButton(
                  key: Key('delete-${ride.id}'),
                  tooltip: 'Delete this ride from the phone',
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

String uploadErrorText(String? code) => switch (code) {
  'no_file' => 'The FIT file is missing on this phone.',
  'offline' => 'Could not reach the server. Try again.',
  'sign_in' => 'Sign in again to upload.',
  'timeout' => 'The server took too long to read the ride.',
  'server_failed' => 'The server could not read this ride.',
  _ when code?.startsWith('http_') == true =>
    'The server refused the upload (${code!.substring(5)}).',
  _ => 'Upload failed. Try again.',
};
