import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/providers.dart';
import 'package:velomine/core/tokens.dart';
import 'package:velomine/core/theme_choice.dart';
import 'package:velomine/core/widgets/floating_nav_pill.dart';
import 'package:velomine/core/widgets/page_scaffold.dart';
import 'package:velomine/features/recording/recorder.dart';
import 'package:velomine/features/recording/recording_providers.dart';
import 'package:velomine/home_shell.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';

import 'fake_server.dart';

import 'package:velomine/core/l10n.dart';

/// Answers [state] and [events]; everything else is unused by the shell.
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

String _titleOf(String location) =>
    location.isEmpty ? '' : location.substring(1).split('/').first;

/// A page that names itself like every routed screen, tall enough to scroll.
class _Page extends StatelessWidget {
  const _Page({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: title,
    children: [
      for (var i = 0; i < 40; i++) SizedBox(height: 80, child: Text('row $i')),
    ],
  );
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
    Widget? page,
    bool reduceMotion = false,
    bool withRecorder = true,
    String? clubRole = 'member',
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    if (reduceMotion) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
    }

    final server = FakeServer();
    server.signInBrowser(
      server.add(
        admin ? 'admin@example.com' : 'rider@example.com',
        roles: [if (admin) 'admin' else 'member'],
        clubRole: clubRole,
      ),
    );
    final session = server.session(useCookies: true);
    await tester.runAsync(session.restore);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith((ref) => session),
          recorderProvider.overrideWithValue(withRecorder ? recorder : null),
          themeChoiceStoreProvider.overrideWithValue(MemoryThemeStore()),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeShell(
            location: location,
            child: page ?? _Page(title: _titleOf(location)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('HomeShell_ShouldShowThreeTabs_WhenTheWindowIsAPhone', (
    tester,
  ) async {
    await pumpShell(tester, admin: true);

    expect(find.byType(FloatingNavPill), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byKey(const Key('tab-rides')), findsOneWidget);
    expect(find.byKey(const Key('tab-progress')), findsOneWidget);
    expect(find.byKey(const Key('tab-club')), findsOneWidget);
    expect(find.byKey(const Key('tab-record')), findsNothing);
    expect(find.byKey(const Key('tab-bikes')), findsNothing);
    expect(find.text('Admin'), findsNothing);
  });

  testWidgets(
    'HomeShell_ShouldNotOfferRecordOrBikesAsTabs_WhenTheWindowIsAPhone',
    (tester) async {
      await pumpShell(tester);

      expect(find.text('Record'), findsNothing);
      expect(find.text('Bikes'), findsNothing);
      expect(find.byIcon(Icons.fiber_manual_record), findsNothing);
    },
  );

  testWidgets('HomeShell_ShouldHighlightTheSelectedTab_WhenOnATab', (
    tester,
  ) async {
    await pumpShell(tester, location: '/progress');

    expect(find.byIcon(Icons.insights), findsOneWidget);
    expect(find.byIcon(Icons.insights_outlined), findsNothing);
    expect(find.byIcon(Icons.directions_bike_outlined), findsOneWidget);
    expect(find.byIcon(Icons.directions_bike), findsNothing);
    expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
  });

  testWidgets('HomeShell_ShouldHighlightNoTab_WhenTheRouteIsPushed', (
    tester,
  ) async {
    await pumpShell(tester, location: '/bikes');

    expect(find.byIcon(Icons.directions_bike_outlined), findsOneWidget);
    expect(find.byIcon(Icons.insights_outlined), findsOneWidget);
    expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
    expect(find.byIcon(Icons.insights), findsNothing);
    expect(find.byIcon(Icons.groups), findsNothing);
  });

  for (final width in [800.0, 1300.0]) {
    testWidgets(
      'HomeShell_ShouldShowTheSameThreeDestinations_WhenTheWindowIs${width.toInt()}Wide',
      (tester) async {
        await pumpShell(tester, size: Size(width, 1000));
        await tester.pumpAndSettle();

        expect(find.byType(FloatingNavPill), findsNothing);
        expect(find.byKey(const Key('rail-rides')), findsOneWidget);
        expect(find.byKey(const Key('rail-progress')), findsOneWidget);
        expect(find.byKey(const Key('rail-club')), findsOneWidget);
        expect(find.text('Bikes'), findsNothing);
        expect(find.text('Record'), findsNothing);
        expect(
          find.text('Velomine'),
          width >= 1200 ? findsOneWidget : findsNothing,
        );
      },
    );

    testWidgets(
      'HomeShell_ShouldReachNotificationsAndAccount_WhenTheWindowIs${width.toInt()}Wide',
      (tester) async {
        await pumpShell(tester, size: Size(width, 1000), admin: true);

        final rail = find.byKey(const Key('rail-rides'));
        expect(rail, findsOneWidget);
        expect(find.byKey(const Key('open-notifications')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(PageScaffold),
            matching: find.byKey(const Key('open-notifications')),
          ),
          findsNothing,
        );
        await tester.tap(find.byKey(const Key('account-menu')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('account-admin')), findsOneWidget);
      },
    );

    testWidgets(
      'HomeShell_ShouldHighlightNoDestination_WhenTheRouteIsPushedAt${width.toInt()}',
      (tester) async {
        await pumpShell(tester, location: '/bikes', size: Size(width, 1000));

        expect(find.byIcon(Icons.directions_bike), findsNothing);
        expect(find.byIcon(Icons.insights), findsNothing);
        expect(find.byIcon(Icons.groups), findsNothing);
      },
    );
  }

  testWidgets(
    'HomeShell_ShouldNameTheClub_WhenTheWindowIsExpandedAndTheRiderHasOne',
    (tester) async {
      await pumpShell(tester, size: const Size(1300, 1000));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('rail-club')),
          matching: find.text('Test Club'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'HomeShell_ShouldNotNameAClub_WhenTheWindowIsExpandedAndTheRiderHasNone',
    (tester) async {
      await pumpShell(tester, size: const Size(1300, 1000), clubRole: null);
      await tester.pumpAndSettle();

      expect(find.text('Test Club'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('rail-club')),
          matching: find.text('No club'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('HomeShell_ShouldHideThePill_WhenThePageScrollsDown', (
    tester,
  ) async {
    await pumpShell(tester);
    final pill = find.byKey(const Key('tab-rides'));
    final top = tester.getTopLeft(pill).dy;

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(pill).dy, greaterThan(top + 40));
    expect(
      tester
          .widget<IgnorePointer>(
            find
                .descendant(
                  of: find.byType(FloatingNavPill),
                  matching: find.byType(IgnorePointer),
                )
                .first,
          )
          .ignoring,
      isTrue,
    );
  });

  testWidgets('HomeShell_ShouldShowThePillAgain_WhenThePageScrollsUp', (
    tester,
  ) async {
    await pumpShell(tester);
    final pill = find.byKey(const Key('tab-rides'));
    final top = tester.getTopLeft(pill).dy;
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 150));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(pill).dy, top);
  });

  testWidgets('HomeShell_ShouldKeepThePillInView_WhenMotionIsReduced', (
    tester,
  ) async {
    await pumpShell(tester, reduceMotion: true);
    final pill = find.byKey(const Key('tab-rides'));
    final top = tester.getTopLeft(pill).dy;

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(pill).dy, top);
  });

  testWidgets('HomeShell_ShouldLeaveRoomUnderThePage_WhenThePillFloatsOverIt', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -10000));
    await tester.pumpAndSettle();

    final last = tester.getBottomLeft(find.text('row 39')).dy;
    final bottom = tester.getBottomLeft(find.byType(PageScaffold)).dy;
    expect(bottom - last, greaterThanOrEqualTo(AppNav.pillClearance));
  });

  testWidgets('HomeShell_ShouldNameTheScreen_WhenThePageHasATitle', (
    tester,
  ) async {
    await pumpShell(tester, location: '/progress');

    expect(find.byType(AppBar), findsNothing);
    expect(find.text('progress'), findsOneWidget);
  });

  testWidgets('HomeShell_ShouldOfferTheWayBack_WhenTheRouteIsPushed', (
    tester,
  ) async {
    await pumpShell(tester, location: '/profile');

    expect(
      find.descendant(
        of: find.byType(PageScaffold),
        matching: find.byType(BackButton),
      ),
      findsOneWidget,
    );
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

      final bar = find.byType(PageScaffold);
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

  const live = RecorderSnapshot(
    state: 'recording',
    elapsedS: 125,
    movingS: 120,
    distanceM: 5200,
  );

  testWidgets('HomeShell_ShouldShowLiveRideBanner_WhenARideIsRecording', (
    tester,
  ) async {
    await pumpShell(tester);
    expect(find.byKey(const Key('live-ride-banner')), findsNothing);

    recorder.emit(live);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('live-ride-banner')), findsOneWidget);
    expect(find.text('2:05'), findsOneWidget);
    expect(find.text('5.2 km'), findsOneWidget);
    expect(find.byIcon(Icons.pause_circle_outline), findsNothing);
    expect(find.bySemanticsLabel('Recording, 2:05, 5.2 km'), findsOneWidget);
    // It sits just above the pill and is a comfortable tap target.
    final banner = tester.getRect(find.byKey(const Key('live-ride-banner')));
    final pill = tester.getRect(find.byType(FloatingNavPill));
    expect(banner.bottom, lessThanOrEqualTo(pill.top));
    expect(banner.height, greaterThanOrEqualTo(48));
  });

  testWidgets('HomeShell_ShouldShowPauseIndicator_WhenTheRideIsPaused', (
    tester,
  ) async {
    await pumpShell(tester);

    recorder.emit(
      const RecorderSnapshot(
        state: 'paused',
        elapsedS: 125,
        movingS: 120,
        distanceM: 5200,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('live-ride-banner')), findsOneWidget);
    expect(find.byIcon(Icons.pause_circle_outline), findsOneWidget);
    expect(find.text('Paused'), findsOneWidget);
  });

  testWidgets('HomeShell_ShouldHideLiveRideBanner_WhenTheRideStops', (
    tester,
  ) async {
    await pumpShell(tester);
    recorder.emit(live);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('live-ride-banner')), findsOneWidget);

    recorder.emit(
      const RecorderSnapshot(
        state: 'idle',
        elapsedS: 0,
        movingS: 0,
        distanceM: 0,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('live-ride-banner')), findsNothing);
  });

  testWidgets('HomeShell_ShouldNotShowLiveRideBanner_WhenOnTheRecorder', (
    tester,
  ) async {
    await pumpShell(tester, location: '/record');

    recorder.emit(live);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('live-ride-banner')), findsNothing);
  });

  testWidgets('HomeShell_ShouldNotShowLiveRideBanner_WhenThereIsNoRecorder', (
    tester,
  ) async {
    await pumpShell(tester, withRecorder: false);

    recorder.emit(live);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('live-ride-banner')), findsNothing);
  });

  testWidgets('HomeShell_ShouldKeepLiveRideBanner_WhenThePageScrollsDown', (
    tester,
  ) async {
    await pumpShell(tester);
    recorder.emit(live);
    await tester.pumpAndSettle();

    await tester.drag(find.text('row 1'), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('live-ride-banner')), findsOneWidget);
    final banner = tester.getRect(find.byKey(const Key('live-ride-banner')));
    expect(banner.bottom, lessThanOrEqualTo(900));
    expect(banner.top, greaterThan(0));
  });

  testWidgets('HomeShell_ShouldShowLiveRideBanner_WhenTheWindowIsWide', (
    tester,
  ) async {
    await pumpShell(tester, size: const Size(900, 900));

    recorder.emit(live);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('live-ride-banner')), findsOneWidget);
  });
}
