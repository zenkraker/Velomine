import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/features/recording/recorder.dart';
import 'package:velomine/features/recording/recorder_settings.dart';
import 'package:velomine/features/recording/recording_screen.dart';

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
  bool permission = true;
  bool? lastAutoPause;
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

  @override
  Future<bool> requestPermissions() async => permission;

  @override
  Future<void> start({bool autoPause = true}) async {
    starts++;
    lastAutoPause = autoPause;
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
  Future<List<LocalRide>> listRides() async => [...rides];

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

  @override
  Future<bool?> readAutoPause() async => autoPause;

  @override
  Future<void> writeAutoPause(bool value) async => autoPause = value;
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    FakeRecorder recorder, {
    RecorderSettingsStore? settings,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RecordingScreen(recorder: recorder, settingsStore: settings),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('starts, pauses, resumes and saves a ride on the phone', (
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
    'auto-pause is on by default, can be turned off and is remembered',
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

  testWidgets('a speed pause is shown as auto-paused', (tester) async {
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

  testWidgets('an interrupted ride can be finished', (tester) async {
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

  testWidgets('a denied permission is explained', (tester) async {
    final recorder = FakeRecorder()..permission = false;
    await pump(tester, recorder);

    await tester.tap(find.byKey(const Key('record-start')));
    await tester.pumpAndSettle();

    expect(recorder.starts, 0);
    expect(find.byKey(const Key('record-error')), findsOneWidget);
    expect(find.textContaining('Allow precise location'), findsOneWidget);
  });

  testWidgets('a local ride can be deleted', (tester) async {
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
}
