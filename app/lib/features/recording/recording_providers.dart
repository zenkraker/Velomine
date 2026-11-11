import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/providers.dart';
import '../../core/telemetry.dart';
import '../rides/rides_view_model.dart';
import 'recorder.dart';
import 'recorder_factory.dart';
import 'recorder_settings.dart';
import 'ride_uploader.dart';
import 'upload_queue.dart';

part 'recording_providers.g.dart';

/// The phone's recorder, or null on the web, which has no Record tab. One
/// instance is shared by the title bar and the Record screen.
final recorderProvider = Provider<Recorder?>(
  (ref) => kIsWeb ? null : createRecorder(),
);

/// Where the start-card choices are remembered.
final recorderSettingsStoreProvider = Provider<RecorderSettingsStore>(
  (ref) => PreferencesRecorderSettingsStore(),
);

/// Where upload progress is remembered across app restarts.
final uploadStateStoreProvider = Provider<UploadStateStore>(
  (ref) => PreferencesUploadStateStore(),
);

/// Uploads finished local rides, one at a time per ride. Kept alive with the
/// session so leaving the Record screen does not stop an upload.
@Riverpod(keepAlive: true)
RideUploadQueue? uploadQueue(Ref ref) {
  final recorder = ref.watch(recorderProvider);
  final accountId = ref.watch(signedInUserIdProvider);
  if (recorder == null || accountId == null) return null;
  final session = ref.watch(sessionProvider);
  final queue = RideUploadQueue(
    recorder: recorder,
    uploader: ServerRideUploader(session.rides),
    store: ref.watch(uploadStateStoreProvider),
    accountId: accountId,
    telemetry: ref.watch(telemetryRuntimeProvider),
    serverUrl: session.serverUrl,
    pollInterval: ref.watch(ridePollIntervalProvider),
    onUnauthorized: session.sessionExpired,
    // A ride that just arrived belongs in the list, with its filters, without a pull.
    onRideUploaded: (_) =>
        unawaited(ref.read(ridesViewModelProvider.notifier).refresh()),
  );
  Future.microtask(queue.init);
  ref.onDispose(queue.dispose);
  return queue;
}

/// The upload queue's state as a stream: one subscription for every screen that
/// shows upload progress. Empty on the web, which has no recorder.
@Riverpod(keepAlive: true)
Stream<Map<String, UploadState>> uploadStates(Ref ref) =>
    ref.watch(uploadQueueProvider)?.updates ??
    const Stream<Map<String, UploadState>>.empty();

/// One subscription to the recorder's broadcast stream, shared by the title bar
/// and the Record screen.
@Riverpod(keepAlive: true)
class RecorderSnapshotViewModel extends _$RecorderSnapshotViewModel {
  @override
  RecorderSnapshot build() {
    const idle = RecorderSnapshot(
      state: 'idle',
      elapsedS: 0,
      movingS: 0,
      distanceM: 0,
    );
    final recorder = ref.watch(recorderProvider);
    if (recorder == null) return idle;

    final subscription = recorder.events.listen(
      (snapshot) {
        if (ref.mounted) state = snapshot;
      },
      onError: (Object _) {
        // The recorder is not available on this platform; leave the tab idle.
      },
    );
    ref.onDispose(subscription.cancel);
    // The first snapshot may not have arrived yet.
    Future.microtask(() async {
      if (!ref.mounted) return;
      try {
        state = await recorder.state();
      } on Object {
        // No recorder on this platform, or it cannot answer: stays idle.
      }
    });
    return idle;
  }
}
