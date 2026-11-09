import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/providers.dart';
import 'package:velomine/core/theme_choice.dart';
import 'package:velomine/features/recording/recorder.dart';
import 'package:velomine/features/recording/recording_providers.dart';
import 'package:velomine/home_shell.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';

import 'fake_server.dart';

/// Answers [state] and [events]; everything else is unused by the title bar.
class _StateRecorder extends Fake implements Recorder {
  _StateRecorder(this.snapshot);

  RecorderSnapshot snapshot;
  final _events = StreamController<RecorderSnapshot>.broadcast(sync: true);

  void emit(RecorderSnapshot next) {
    snapshot = next;
    _events.add(next);
  }

  @override
  Future<RecorderSnapshot> state() async => snapshot;

  @override
  Stream<RecorderSnapshot> get events => _events.stream;
}

void main() {
  testWidgets(
    'HomeShell_ShouldShowTheRecordingStateInTheNavBar_WhenItChanges',
    (tester) async {
      final server = FakeServer();
      server.signInBrowser(server.add('rider@example.com'));
      final session = server.session(useCookies: true);
      await tester.runAsync(session.restore);

      final recorder = _StateRecorder(
        const RecorderSnapshot(
          state: 'idle',
          elapsedS: 0,
          movingS: 0,
          distanceM: 0,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWith((ref) => session),
            recorderProvider.overrideWithValue(recorder),
            themeChoiceStoreProvider.overrideWithValue(MemoryThemeStore()),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeShell(location: '/rides', child: const SizedBox.shrink()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Record'), findsOneWidget);

      recorder.emit(
        const RecorderSnapshot(
          state: 'recording',
          elapsedS: 5,
          movingS: 5,
          distanceM: 20,
        ),
      );
      await tester.pump();

      expect(find.text('Recording'), findsOneWidget);
      expect(find.text('Record'), findsNothing);

      recorder.emit(
        const RecorderSnapshot(
          state: 'paused',
          elapsedS: 10,
          movingS: 8,
          distanceM: 30,
        ),
      );
      await tester.pump();

      expect(find.text('Paused'), findsOneWidget);
    },
  );
}
