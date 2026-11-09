import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/providers.dart';
import 'package:velomine/features/recording/recorder.dart';
import 'package:velomine/features/recording/recorder_settings.dart';
import 'package:velomine/features/recording/recording_providers.dart';
import 'package:velomine/features/recording/recording_screen.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';

final testAccountProvider = NotifierProvider<_TestAccount, String?>(
  _TestAccount.new,
);

class _TestAccount extends Notifier<String?> {
  @override
  String? build() => 'id-rider';

  void set(String? value) => state = value;
}

class FakeRecorder implements Recorder {
  FakeRecorder();

  final _events = StreamController<RecorderSnapshot>.broadcast();
  RecorderSnapshot snapshot = const RecorderSnapshot(
    state: 'idle',
    elapsedS: 0,
    movingS: 0,
    distanceM: 0,
  );
  final rides = <LocalRide>[];
  final sensors = <SensorInfo>[];
  bool permission = true;
  bool sensorPermission = true;
  bool sensorSupport = true;
  SensorInfo? pairedSensor;
  int sensorScans = 0;
  bool? lastAutoPause;
  String? lastRideType;
  bool? lastEbike;
  String? lastAccountId;
  int starts = 0;
  int pauses = 0;
  int resumes = 0;
  int stops = 0;
  final finalized = <String>[];
  final deleted = <String>[];

  void emit(RecorderSnapshot next) => _emit(next);

  void _emit(RecorderSnapshot next) {
    snapshot = next;
    _events.add(next);
  }

  RecorderSnapshot _copy({
    required String? sensorName,
    required String sensorStatus,
    int? heartRateBpm,
  }) {
    final current = snapshot;
    return RecorderSnapshot(
      state: current.state,
      rideId: current.rideId,
      startedAt: current.startedAt,
      elapsedS: current.elapsedS,
      movingS: current.movingS,
      distanceM: current.distanceM,
      speedMs: current.speedMs,
      accuracyM: current.accuracyM,
      error: current.error,
      autoPaused: current.autoPaused,
      sensorName: sensorName,
      sensorStatus: sensorStatus,
      heartRateBpm: heartRateBpm ?? current.heartRateBpm,
    );
  }

  @override
  bool get sensorsSupported => sensorSupport;

  @override
  Future<bool> requestPermissions() async => permission;

  @override
  Future<bool> requestSensorPermissions() async => sensorPermission;

  @override
  Future<List<SensorInfo>> scanSensors() async {
    sensorScans++;
    return [...sensors];
  }

  @override
  Future<void> pairSensor(SensorInfo sensor) async {
    pairedSensor = sensor;
    _emit(
      _copy(
        sensorName: sensor.name,
        sensorStatus: 'paired',
        heartRateBpm: null,
      ),
    );
  }

  @override
  Future<void> forgetSensor() async {
    pairedSensor = null;
    _emit(_copy(sensorName: null, sensorStatus: 'none', heartRateBpm: null));
  }

  @override
  Future<void> start({
    bool autoPause = true,
    String rideType = 'road',
    bool ebike = false,
    String? accountId,
  }) async {
    starts++;
    lastAutoPause = autoPause;
    lastRideType = rideType;
    lastEbike = ebike;
    lastAccountId = accountId;
    _emit(
      RecorderSnapshot(
        state: 'recording',
        rideId: 'ride-live',
        startedAt: DateTime(2026, 11, 6, 9),
        elapsedS: 1,
        movingS: 1,
        distanceM: 12,
        speedMs: 4,
        accuracyM: 5,
      ),
    );
  }

  @override
  Future<void> pause() async {
    pauses++;
    _emit(
      RecorderSnapshot(
        state: 'paused',
        rideId: 'ride-live',
        elapsedS: 10,
        movingS: 8,
        distanceM: 12,
        accuracyM: 5,
      ),
    );
  }

  @override
  Future<void> resume() async {
    resumes++;
    _emit(
      RecorderSnapshot(
        state: 'recording',
        rideId: 'ride-live',
        elapsedS: 12,
        movingS: 10,
        distanceM: 12,
        accuracyM: 5,
      ),
    );
  }

  @override
  Future<void> stop() async {
    stops++;
    rides.insert(
      0,
      LocalRide(
        id: 'ride-live',
        startedAt: DateTime(2026, 11, 6, 9),
        endedAt: DateTime(2026, 11, 6, 9, 1),
        state: 'ready',
        distanceM: 500,
        movingS: 60,
        accountId: lastAccountId,
      ),
    );
    _emit(
      const RecorderSnapshot(
        state: 'idle',
        elapsedS: 0,
        movingS: 0,
        distanceM: 0,
      ),
    );
  }

  @override
  Future<RecorderSnapshot> state() async => snapshot;

  @override
  Stream<RecorderSnapshot> get events => _events.stream;

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
  Future<LocalRide?> finalizeRide(String id) async {
    finalized.add(id);
    final index = rides.indexWhere((r) => r.id == id);
    if (index < 0) return null;
    rides[index] = LocalRide(
      id: id,
      startedAt: rides[index].startedAt,
      endedAt: rides[index].endedAt,
      state: 'ready',
      distanceM: rides[index].distanceM,
      movingS: rides[index].movingS,
      accountId: rides[index].accountId,
    );
    return rides[index];
  }

  @override
  Future<bool> deleteRide(String id) async {
    deleted.add(id);
    rides.removeWhere((r) => r.id == id);
    return true;
  }

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

class MemoryRecorderSettings implements RecorderSettingsStore {
  MemoryRecorderSettings([this.autoPause]);

  bool? autoPause;
  String? rideType;
  bool? ebike;

  @override
  Future<bool?> readAutoPause() async => autoPause;

  @override
  Future<void> writeAutoPause(bool value) async => autoPause = value;

  @override
  Future<String?> readRideType() async => rideType;

  @override
  Future<void> writeRideType(String value) async => rideType = value;

  @override
  Future<bool?> readEbike() async => ebike;

  @override
  Future<void> writeEbike(bool value) async => ebike = value;
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    FakeRecorder recorder, {
    RecorderSettingsStore? settings,
  }) async {
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recorderProvider.overrideWithValue(recorder),
          recorderSettingsStoreProvider.overrideWithValue(
            settings ?? MemoryRecorderSettings(),
          ),
          uploadQueueProvider.overrideWithValue(null),
          signedInUserIdProvider.overrideWith(
            (ref) => ref.watch(testAccountProvider),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RecordingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('RecordingScreen_ShouldStartPauseResumeAndSave_WhenRiding', (
    tester,
  ) async {
    final recorder = FakeRecorder();
    await pump(tester, recorder);

    expect(find.byKey(const Key('record-start')), findsOneWidget);
    expect(find.byKey(const Key('no-local-rides')), findsOneWidget);

    await tester.tap(find.byKey(const Key('record-start')));
    await tester.pumpAndSettle();

    expect(recorder.starts, 1);
    expect(find.byKey(const Key('record-clock')), findsOneWidget);
    expect(find.text('Recording'), findsOneWidget);

    await tester.tap(find.byKey(const Key('record-pause')));
    await tester.pumpAndSettle();
    expect(recorder.pauses, 1);
    expect(find.text('Paused'), findsOneWidget);

    await tester.tap(find.byKey(const Key('record-resume')));
    await tester.pumpAndSettle();
    expect(recorder.resumes, 1);

    await tester.tap(find.byKey(const Key('record-stop')));
    await tester.pumpAndSettle();

    expect(recorder.stops, 1);
    expect(find.byKey(const Key('local-ride-ride-live')), findsOneWidget);
    expect(find.textContaining('Ready to upload'), findsOneWidget);
  });

  testWidgets(
    'RecordingScreen_ShouldDefaultAutoPauseOnAndRememberOff_WhenToggled',
    (tester) async {
      final recorder = FakeRecorder();
      final settings = MemoryRecorderSettings();
      await pump(tester, recorder, settings: settings);

      final toggle = find.byKey(const Key('auto-pause-switch'));
      expect(toggle, findsOneWidget);
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(settings.autoPause, isFalse);

      await tester.tap(find.byKey(const Key('record-start')));
      await tester.pumpAndSettle();
      expect(recorder.lastAutoPause, isFalse);
    },
  );

  testWidgets('RecordingScreen_ShouldShowAutoPause_WhenPaused', (tester) async {
    final recorder = FakeRecorder();
    await pump(tester, recorder);

    recorder.emit(
      const RecorderSnapshot(
        state: 'paused',
        rideId: 'ride-live',
        elapsedS: 10,
        movingS: 8,
        distanceM: 12,
        autoPaused: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Auto-paused'), findsOneWidget);
    expect(find.byKey(const Key('record-resume')), findsOneWidget);
  });

  testWidgets('RecordingScreen_ShouldFinishRide_WhenInterrupted', (
    tester,
  ) async {
    final recorder = FakeRecorder();
    recorder.rides.add(
      LocalRide(
        id: 'ride-1',
        startedAt: DateTime(2026, 11, 5, 8),
        state: 'interrupted',
        distanceM: 1200,
        movingS: 300,
      ),
    );
    await pump(tester, recorder);

    expect(find.textContaining('Interrupted'), findsOneWidget);
    await tester.tap(find.byKey(const Key('finalize-ride-1')));
    await tester.pumpAndSettle();

    expect(recorder.finalized, ['ride-1']);
    expect(find.textContaining('Ready to upload'), findsOneWidget);
  });

  testWidgets('RecordingScreen_ShouldExplainDenial_WhenLocationDenied', (
    tester,
  ) async {
    final recorder = FakeRecorder()..permission = false;
    await pump(tester, recorder);

    await tester.tap(find.byKey(const Key('record-start')));
    await tester.pumpAndSettle();

    expect(recorder.starts, 0);
    expect(find.byKey(const Key('record-error')), findsOneWidget);
    expect(find.textContaining('Allow precise location'), findsOneWidget);
  });

  testWidgets(
    'RecordingScreen_ShouldHideAnotherAccountsLocalRides_WhenTheAccountChanges',
    (tester) async {
      final recorder = FakeRecorder()
        ..rides.add(
          LocalRide(
            id: 'alice-ride',
            startedAt: DateTime(2026, 11, 5, 8),
            state: 'ready',
            distanceM: 1200,
            movingS: 300,
            accountId: 'id-rider',
          ),
        )
        ..rides.add(
          LocalRide(
            id: 'bob-ride',
            startedAt: DateTime(2026, 11, 5, 9),
            state: 'ready',
            distanceM: 2200,
            movingS: 400,
            accountId: 'id-other',
          ),
        );
      await pump(tester, recorder);

      expect(find.byKey(const Key('local-ride-alice-ride')), findsOneWidget);
      expect(find.byKey(const Key('local-ride-bob-ride')), findsNothing);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(RecordingScreen)),
        listen: false,
      );
      container.read(testAccountProvider.notifier).set('id-other');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('local-ride-alice-ride')), findsNothing);
      expect(find.byKey(const Key('local-ride-bob-ride')), findsOneWidget);
    },
  );

  testWidgets('RecordingScreen_ShouldDeleteRide_WhenTapped', (tester) async {
    final recorder = FakeRecorder();
    recorder.rides.add(
      LocalRide(
        id: 'ride-1',
        startedAt: DateTime(2026, 11, 5, 8),
        state: 'ready',
        distanceM: 1200,
        movingS: 300,
      ),
    );
    await pump(tester, recorder);

    await tester.tap(find.byKey(const Key('delete-ride-1')));
    await tester.pumpAndSettle();

    expect(recorder.deleted, ['ride-1']);
    expect(find.byKey(const Key('local-ride-ride-1')), findsNothing);
  });

  testWidgets('SensorPairing_ShouldPairAndKeepStrap_WhenFound', (tester) async {
    final recorder = FakeRecorder()
      ..sensors.add(
        const SensorInfo(
          address: 'AA:BB:CC:DD:EE:FF',
          name: 'Polar H10 1A2B3C',
          rssi: -52,
        ),
      );
    await pump(tester, recorder);

    expect(find.byKey(const Key('pair-sensor')), findsOneWidget);
    await tester.tap(find.byKey(const Key('pair-sensor')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sensor-sheet')), findsOneWidget);
    expect(recorder.sensorScans, 1);
    expect(find.text('Polar H10 1A2B3C'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sensor-AA:BB:CC:DD:EE:FF')));
    await tester.pumpAndSettle();

    expect(recorder.pairedSensor?.name, 'Polar H10 1A2B3C');
    expect(find.byKey(const Key('sensor-sheet')), findsNothing);
    expect(find.byKey(const Key('forget-sensor')), findsOneWidget);
    expect(find.text('Polar H10 1A2B3C'), findsOneWidget);
  });

  testWidgets('SensorPairing_ShouldForgetStrap_WhenTapped', (tester) async {
    final recorder = FakeRecorder()
      ..snapshot = const RecorderSnapshot(
        state: 'idle',
        elapsedS: 0,
        movingS: 0,
        distanceM: 0,
        sensorName: 'Polar H10 1A2B3C',
        sensorStatus: 'paired',
      );
    await pump(tester, recorder);

    await tester.tap(find.byKey(const Key('forget-sensor')));
    await tester.pumpAndSettle();

    expect(recorder.pairedSensor, isNull);
    expect(find.byKey(const Key('pair-sensor')), findsOneWidget);
  });

  testWidgets('SensorPairing_ShouldHideSensorRow_WhenUnsupported', (
    tester,
  ) async {
    final recorder = FakeRecorder()..sensorSupport = false;
    await pump(tester, recorder);

    expect(find.byKey(const Key('pair-sensor')), findsNothing);
    expect(find.text('Heart-rate strap'), findsNothing);
  });

  testWidgets('SensorPairing_ShouldExplainRefusal_WhenNearbyDenied', (
    tester,
  ) async {
    final recorder = FakeRecorder()..sensorPermission = false;
    await pump(tester, recorder);

    await tester.tap(find.byKey(const Key('pair-sensor')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sensor-sheet-error')), findsOneWidget);
    expect(find.textContaining('Allow nearby devices'), findsOneWidget);
    expect(recorder.sensorScans, 0);
  });

  testWidgets('RecordingScreen_ShouldShowHeartRateAndStrap_WhenLive', (
    tester,
  ) async {
    final recorder = FakeRecorder();
    await pump(tester, recorder);

    recorder.emit(
      const RecorderSnapshot(
        state: 'recording',
        rideId: 'ride-live',
        elapsedS: 12,
        movingS: 10,
        distanceM: 80,
        sensorName: 'Polar H10',
        sensorStatus: 'connected',
        heartRateBpm: 148,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('readout-heartrate'))).data,
      '148 bpm',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('sensor-status'))).data,
      'Connected',
    );
  });

  test('RecorderSnapshot_ShouldReadPairedStrap_WhenBuiltFromMap', () {
    final snapshot = RecorderSnapshot.fromMap({
      'state': 'recording',
      'elapsedS': 3,
      'movingS': 2,
      'distanceM': 10,
      'sensorName': 'Polar H10 1A2B3C',
      'sensorStatus': 'connected',
      'heartRateBpm': 141,
    });

    expect(snapshot.sensorName, 'Polar H10 1A2B3C');
    expect(snapshot.sensorConnected, isTrue);
    expect(snapshot.heartRateBpm, 141);
  });

  testWidgets('RecordingScreen_ShouldSendTheRideTypeAndEbike_WhenStarting', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final recorder = FakeRecorder();
    final settings = MemoryRecorderSettings();
    await pump(tester, recorder, settings: settings);

    await tester.tap(find.byKey(const Key('record-ride-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gravel').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('record-ebike-switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('record-start')));
    await tester.pumpAndSettle();

    expect(recorder.lastRideType, 'gravel');
    expect(recorder.lastEbike, isTrue);
    expect(settings.rideType, 'gravel');
    expect(settings.ebike, isTrue);
  });
}
