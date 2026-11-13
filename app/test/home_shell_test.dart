import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late _StateRecorder recorder;

  setUp(() {
    recorder = _StateRecorder(
      const RecorderSnapshot(
        state: 'idle',
        elapsedS: 0,
        movingS: 0,
        distanceM: 0,
      ),
    );
  });

  /// Signs in as an ordinary member (or an admin) and shows [location] inside the shell.
  Future<void> pumpShell(
    WidgetTester tester, {
    String location = '/rides',
    bool admin = false,
    Size size = const Size(400, 900),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final server = FakeServer();
    server.signInBrowser(
      server.add(
        admin ? 'admin@example.com' : 'rider@example.com',
        roles: [if (admin) 'admin' else 'member'],
      ),
    );
    final session = server.session(useCookies: true);
    await tester.runAsync(session.restore);
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
          home: HomeShell(location: location, child: const SizedBox.shrink()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('HomeShell_ShouldMarkTheRecordTab_WhenRecordingIsLive', (
    tester,
  ) async {
    await pumpShell(tester);

    expect(find.text('Record'), findsOneWidget);
    expect(find.byIcon(Icons.fiber_manual_record), findsOneWidget);

    recorder.emit(
      const RecorderSnapshot(
        state: 'recording',
        elapsedS: 5,
        movingS: 5,
        distanceM: 20,
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.fiber_smart_record), findsOneWidget);
    expect(find.text('Record'), findsOneWidget);

    recorder.emit(
      const RecorderSnapshot(
        state: 'paused',
        elapsedS: 10,
        movingS: 8,
        distanceM: 30,
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.pause_circle_outline), findsOneWidget);
  });

  testWidgets('HomeShell_ShouldShowFiveTabs_WhenTheMemberIsAnAdmin', (
    tester,
  ) async {
    await pumpShell(tester, admin: true);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(find.text('Admin'), findsNothing);
    expect(find.text('Bikes'), findsOneWidget);
  });

  testWidgets('HomeShell_ShouldShowARail_WhenTheWindowIsSixHundredWide', (
    tester,
  ) async {
    await pumpShell(tester, size: const Size(800, 1000));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Bikes'), findsOneWidget);
  });

  testWidgets('HomeShell_ShouldNameTheScreen_WhenTheLocationChanges', (
    tester,
  ) async {
    await pumpShell(tester, location: '/progress');

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Progress')),
      findsOneWidget,
    );
  });

  testWidgets('HomeShell_ShouldOfferTheWayBack_WhenTheRouteIsPushed', (
    tester,
  ) async {
    await pumpShell(tester, location: '/profile');

    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('HomeShell_ShouldOfferNoBackArrow_WhenTheRouteIsATab', (
    tester,
  ) async {
    await pumpShell(tester, location: '/club');

    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets(
    'HomeShell_ShouldOpenTheAdminScreen_WhenAnAdminPicksItFromTheAccountMenu',
    (tester) async {
      await pumpShell(tester, admin: true);

      await tester.tap(find.byKey(const Key('account-menu')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('account-admin')), findsOneWidget);
      expect(find.byKey(const Key('account-sign-out')), findsOneWidget);
    },
  );

  testWidgets(
    'HomeShell_ShouldShowTheAvatarAndNoThemeButton_WhenTheWindowIsAPhone',
    (tester) async {
      await pumpShell(tester, location: '/rides');

      final bar = find.byType(AppBar);
      expect(
        find.descendant(
          of: bar,
          matching: find.byKey(const Key('theme-choice')),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: bar, matching: find.byType(CircleAvatar)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: bar,
          matching: find.byKey(const Key('open-notifications')),
        ),
        findsOneWidget,
      );

      // The theme is still reachable, inside the account menu.
      await tester.tap(find.byKey(const Key('account-menu')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('theme-system')), findsOneWidget);
      expect(find.byKey(const Key('theme-dark')), findsOneWidget);
    },
  );

  testWidgets('HomeShell_ShouldNotOverflow_WhenTextIsTwiceItsSize', (
    tester,
  ) async {
    await pumpShell(tester, size: const Size(320, 640), textScale: 2);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'HomeShell_ShouldAskAgainBeforeExiting_WhenBackHasNoPreviousPage',
    (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await pumpShell(tester);

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Press back again to exit'), findsOneWidget);
      expect(
        calls.where((call) => call.method == 'SystemNavigator.pop'),
        isEmpty,
      );

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(
        calls.where((call) => call.method == 'SystemNavigator.pop'),
        isNotEmpty,
      );
    },
  );
}
