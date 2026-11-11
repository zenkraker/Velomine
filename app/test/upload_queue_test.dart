import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/features/recording/recorder.dart';
import 'package:velomine/features/recording/ride_uploader.dart';
import 'package:velomine/features/recording/upload_queue.dart';
import 'package:velomine_api/api.dart';

import 'fake_telemetry.dart';

class QueueRecorder implements Recorder {
  final rides = <LocalRide>[];

  @override
  bool get sensorsSupported => false;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<bool> requestSensorPermissions() async => false;

  @override
  Future<List<SensorInfo>> scanSensors() async => const [];

  @override
  Future<void> pairSensor(SensorInfo sensor) async {}

  @override
  Future<void> forgetSensor() async {}

  @override
  Future<void> start({
    bool autoPause = true,
    String rideType = 'road',
    bool ebike = false,
    String? accountId,
  }) async {}

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
  Future<List<LocalRide>> listRides({String? accountId}) async {
    final result = <LocalRide>[];
    for (var i = 0; i < rides.length; i++) {
      var ride = rides[i];
      if (accountId != null && ride.accountId == null) {
        ride = LocalRide(
          id: ride.id,
          startedAt: ride.startedAt,
          endedAt: ride.endedAt,
          state: ride.state,
          distanceM: ride.distanceM,
          movingS: ride.movingS,
          accountId: accountId,
          error: ride.error,
          uploadState: ride.uploadState,
          serverRideId: ride.serverRideId,
          uploadError: ride.uploadError,
          uploadAttempts: ride.uploadAttempts,
        );
        rides[i] = ride;
      }
      if (accountId == null || ride.accountId == accountId) result.add(ride);
    }
    return result;
  }

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
  int? failCode;
  String pollStatus = 'ready';

  @override
  Future<RideUploadResult> upload(
    Uint8List bytes,
    String idempotencyKey,
  ) async {
    if (unauthorized) throw ApiException(401, 'not signed in');
    if (failCode != null) throw ApiException(failCode!, 'server error');
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

LocalRide ready(String id, {String accountId = 'id-rider'}) => LocalRide(
  id: id,
  startedAt: DateTime(2026, 11, 6, 9),
  endedAt: DateTime(2026, 11, 6, 10),
  state: 'ready',
  distanceM: 10000,
  movingS: 1800,
  accountId: accountId,
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
  late QueueRecorder recorder;
  late RideUploadQueue queue;
  late FakeTelemetryRuntime telemetry;

  setUp(() {
    uploader = FakeUploader();
    store = MemoryUploadStore();
    recorder = QueueRecorder()..rides.add(ready('r1'));
    telemetry = FakeTelemetryRuntime();
    queue = RideUploadQueue(
      recorder: recorder,
      uploader: uploader,
      store: store,
      accountId: 'id-rider',
      pollInterval: Duration.zero,
      telemetry: telemetry,
    );
  });

  test('UploadQueue_ShouldUploadAndRememberRide_WhenRideIsReady', () async {
    await queue.init();
    await queue.resume([ready('r1')]);
    await settle(queue, 'r1');

    expect(uploader.keys, ['r1']);
    expect(queue.stateFor('r1')?.isUploaded, isTrue);
    expect(queue.stateFor('r1')?.serverRideId, 'server-r1');
    expect(store.states['r1']?.isUploaded, isTrue);
  });

  test('UploadQueue_ShouldForgetTheOldestFinished_WhenTheListIsLong', () async {
    final bounded = RideUploadQueue(
      recorder: recorder,
      uploader: uploader,
      store: store,
      accountId: 'id-rider',
      pollInterval: Duration.zero,
      maxRemembered: 2,
      telemetry: telemetry,
    );
    await bounded.init();
    for (final id in ['r1', 'r2', 'r3']) {
      if (!recorder.rides.any((ride) => ride.id == id)) {
        recorder.rides.add(ready(id));
      }
      await bounded.enqueue(id);
      await settle(bounded, id);
    }

    expect(bounded.states.length, 2);
    expect(bounded.states.containsKey('r1'), isFalse);
  });

  test('UploadQueue_ShouldReportTheServerRide_WhenTheUploadIsDone', () async {
    final uploaded = <String>[];
    queue = RideUploadQueue(
      recorder: recorder,
      uploader: uploader,
      store: store,
      accountId: 'id-rider',
      pollInterval: Duration.zero,
      telemetry: telemetry,
      onRideUploaded: uploaded.add,
    );
    await queue.init();
    await queue.resume([ready('r1')]);
    await settle(queue, 'r1');

    expect(uploaded, ['server-r1']);
  });

  test('UploadQueue_ShouldTreatAsUploaded_WhenServerSaysDuplicate', () async {
    uploader.pollStatus = 'duplicate';
    await queue.init();
    await queue.enqueue('r1');
    await settle(queue, 'r1');

    expect(queue.stateFor('r1')?.isUploaded, isTrue);
  });

  test('UploadQueue_ShouldRetryUpload_WhenUploadFailed', () async {
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

  test('UploadQueue_ShouldMarkTheRideFailed_WhenTheSessionEnded', () async {
    queue = RideUploadQueue(
      recorder: recorder,
      uploader: uploader..unauthorized = true,
      store: store,
      accountId: 'id-rider',
      pollInterval: Duration.zero,
      telemetry: FakeTelemetryRuntime(),
    );
    await queue.init();
    await queue.enqueue('r1');
    await settle(queue, 'r1');

    expect(queue.stateFor('r1')?.error, 'sign_in');
  });

  test('UploadQueue_ShouldNotResendRide_WhenAlreadyUploaded', () async {
    store.states = {
      'r1': const UploadState(state: UploadState.uploaded, serverRideId: 'old'),
    };
    await queue.init();
    await queue.resume([ready('r1')]);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(uploader.keys, isEmpty);
    expect(queue.stateFor('r1')?.isUploaded, isTrue);
  });

  test(
    'UploadQueue_ShouldNotUpload_WhenTheLocalRideBelongsToAnotherAccount',
    () async {
      recorder.rides
        ..clear()
        ..add(ready('r1', accountId: 'id-other'));

      await queue.init();
      await queue.resume([ready('r1', accountId: 'id-other')]);
      await queue.enqueue('r1');
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(uploader.keys, isEmpty);
      expect(queue.stateFor('r1'), isNull);
    },
  );

  test('UploadQueue_ShouldRetry_WhenTheServerAnswers5xx', () async {
    uploader.failCode = 503;
    await queue.init();
    await queue.enqueue('r1');
    await settle(queue, 'r1');
    expect(queue.stateFor('r1')?.error, 'http_503');

    uploader.failCode = null;
    await queue.resume([ready('r1')]);
    await settle(queue, 'r1');
    expect(queue.stateFor('r1')?.isUploaded, isTrue);
  });

  test('UploadQueue_ShouldReportSuccess_WhenTheUploadFinishes', () async {
    await queue.init();
    await queue.enqueue('r1');
    await settle(queue, 'r1');

    final success = telemetry.counts.firstWhere(
      (entry) => entry.name == 'ride_upload_succeeded',
    );
    expect(success.attributes['attempts'], '1');
    expect(
      telemetry.distributions.any(
        (entry) => entry.name == 'ride_upload_duration',
      ),
      isTrue,
    );
    expect(
      telemetry.logs.any((entry) => entry.message == 'ride upload succeeded'),
      isTrue,
    );
  });

  test('UploadQueue_ShouldReportFailureReason_WhenTheUploadFails', () async {
    uploader.failUpload = true;
    await queue.init();
    await queue.enqueue('r1');
    await settle(queue, 'r1');

    final failure = telemetry.counts.firstWhere(
      (entry) => entry.name == 'ride_upload_failures',
    );
    expect(failure.attributes['reason'], 'server_failed');
    expect(failure.attributes['attempts'], '1');
    expect(
      telemetry.logs.any((entry) => entry.message == 'ride upload failed'),
      isTrue,
    );
  });
}
