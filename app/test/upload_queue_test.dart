import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/features/recording/recorder.dart';
import 'package:velomine/features/recording/ride_uploader.dart';
import 'package:velomine/features/recording/upload_queue.dart';
import 'package:velomine_api/api.dart';

class QueueRecorder implements Recorder {
  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> start({bool autoPause = true}) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<RecorderSnapshot> state() async => const RecorderSnapshot(
    state: 'idle',
    elapsedS: 0,
    movingS: 0,
    distanceM: 0,
  );

  @override
  Stream<RecorderSnapshot> get events => const Stream.empty();

  @override
  Future<List<LocalRide>> listRides() async => const [];

  @override
  Future<Uint8List?> readFit(String id) async => Uint8List.fromList([1, 2, 3]);

  @override
  Future<LocalRide?> finalizeRide(String id) async => null;

  @override
  Future<bool> deleteRide(String id) async => true;

  @override
  Future<void> markUploadState(
    String id,
    String state, {
    String? serverRideId,
    String? error,
    int? attempts,
  }) async {}

  @override
  Future<void> scheduleUpload(String serverUrl) async {}
}

class FakeUploader implements RideUploader {
  final keys = <String>[];
  bool unauthorized = false;
  bool failUpload = false;
  String pollStatus = 'ready';

  @override
  Future<RideUploadResult> upload(
    Uint8List bytes,
    String idempotencyKey,
  ) async {
    if (unauthorized) throw ApiException(401, 'not signed in');
    if (failUpload) throw const RideUploadException('server_failed', 'nope');
    keys.add(idempotencyKey);
    return RideUploadResult(
      serverRideId: 'server-$idempotencyKey',
      status: 'processing',
    );
  }

  @override
  Future<RideStatusResult> status(String serverRideId) async =>
      RideStatusResult(status: pollStatus);
}

class MemoryUploadStore implements UploadStateStore {
  Map<String, UploadState> states = {};

  @override
  Future<Map<String, UploadState>> read() async => {...states};

  @override
  Future<void> write(Map<String, UploadState> states) async =>
      this.states = {...states};
}

LocalRide ready(String id) => LocalRide(
  id: id,
  startedAt: DateTime(2026, 11, 6, 9),
  endedAt: DateTime(2026, 11, 6, 10),
  state: 'ready',
  distanceM: 10000,
  movingS: 1800,
);

Future<void> settle(RideUploadQueue queue, String id) async {
  for (var i = 0; i < 100; i++) {
    final state = queue.stateFor(id);
    if (state != null && !state.isBusy) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('upload for $id did not finish');
}

void main() {
  late FakeUploader uploader;
  late MemoryUploadStore store;
  late RideUploadQueue queue;

  setUp(() {
    uploader = FakeUploader();
    store = MemoryUploadStore();
    queue = RideUploadQueue(
      recorder: QueueRecorder(),
      uploader: uploader,
      store: store,
      pollInterval: Duration.zero,
    );
  });

  test('uploads a ready ride and remembers it', () async {
    await queue.init();
    await queue.resume([ready('r1')]);
    await settle(queue, 'r1');

    expect(uploader.keys, ['r1']);
    expect(queue.stateFor('r1')?.isUploaded, isTrue);
    expect(queue.stateFor('r1')?.serverRideId, 'server-r1');
    expect(store.states['r1']?.isUploaded, isTrue);
  });

  test('a duplicate is treated as uploaded', () async {
    uploader.pollStatus = 'duplicate';
    await queue.init();
    await queue.enqueue('r1');
    await settle(queue, 'r1');

    expect(queue.stateFor('r1')?.isUploaded, isTrue);
  });

  test('a failed upload can be retried', () async {
    uploader.failUpload = true;
    await queue.init();
    await queue.enqueue('r1');
    await settle(queue, 'r1');

    expect(queue.stateFor('r1')?.isFailed, isTrue);
    expect(queue.stateFor('r1')?.error, 'server_failed');

    uploader.failUpload = false;
    await queue.retry('r1');
    await settle(queue, 'r1');
    expect(queue.stateFor('r1')?.isUploaded, isTrue);
    expect(uploader.keys, ['r1']);
  });

  test('an expired session asks the app to sign in again', () async {
    var signedOut = false;
    queue = RideUploadQueue(
      recorder: QueueRecorder(),
      uploader: uploader..unauthorized = true,
      store: store,
      pollInterval: Duration.zero,
      onUnauthorized: () => signedOut = true,
    );
    await queue.init();
    await queue.enqueue('r1');
    await settle(queue, 'r1');

    expect(signedOut, isTrue);
    expect(queue.stateFor('r1')?.error, 'sign_in');
  });

  test('an already uploaded ride is not sent again after a restart', () async {
    store.states = {
      'r1': const UploadState(state: UploadState.uploaded, serverRideId: 'old'),
    };
    await queue.init();
    await queue.resume([ready('r1')]);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(uploader.keys, isEmpty);
    expect(queue.stateFor('r1')?.isUploaded, isTrue);
  });
}
