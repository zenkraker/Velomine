import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/providers.dart';
import 'package:velomine/core/rider_mode.dart';
import 'package:velomine/core/l10n.dart';
import 'package:velomine/core/widgets/more_details.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';
import 'package:velomine/core/widgets/fact_grid.dart';
import 'package:velomine/features/profile/rider_mode_view_model.dart';
import 'package:velomine/features/rides/detail/effort_word.dart';
import 'package:velomine/features/rides/detail/series_chart.dart';
import 'package:velomine_api/api.dart';

import 'fake_server.dart';

/// An account as `GET /accounts/me` returns it, with only the fields these tests care about set.
MeResponse me({String? riderMode, bool? supported = true}) => MeResponse(
  id: 'id-1',
  email: 'rider@example.com',
  displayName: 'Ada',
  roles: const ['member'],
  language: null,
  telemetryConsentRequired: false,
  telemetryCrash: false,
  telemetryUsage: false,
  units: 'metric',
  riderMode: riderMode,
  riderModeSupported: supported,
);

void main() {
  late FakeServer server;

  setUp(() => server = FakeServer());

  /// Signs in and returns the container, without an app on screen.
  Future<ProviderContainer> signedIn(String email, {String? mode}) async {
    server.signInBrowser(server.add(email, riderMode: mode));
    final session = server.session(useCookies: true);
    await session.restore();
    final container = ProviderContainer(
      overrides: [sessionProvider.overrideWith((ref) => session)],
    );
    addTearDown(container.dispose);
    container.listen(riderModeViewModelProvider, (_, _) {});
    return container;
  }

  group('layout', () {
    test('RiderModeLayout_ShouldHideLoadFacts_WhenModeIsJustRiding', () {
      final layout = RiderModeLayout.of(RiderMode.justRiding);

      expect(layout.rideListFacts, {'distance', 'moving-time'});
      expect(layout.rideChartIds, isEmpty);
      expect(layout.showIntensity, isFalse);
      expect(layout.foldAdvanced, isTrue);
      expect(layout.effortWord, isTrue);
    });

    test(
      'RiderModeLayout_ShouldKeepIntensityAndMainCharts_WhenModeIsWithGoals',
      () {
        final layout = RiderModeLayout.of(RiderMode.withGoals);

        expect(layout.rideListFacts, {
          'distance',
          'moving-time',
          'average-heart-rate',
        });
        expect(layout.rideChartIds, {'elevation', 'speed', 'heartrate'});
        expect(layout.showIntensity, isTrue);
        expect(layout.foldAdvanced, isTrue);
        expect(layout.effortWord, isTrue);
      },
    );

    test('RiderModeLayout_ShouldShowEverything_WhenModeIsTraining', () {
      final layout = RiderModeLayout.of(RiderMode.training);

      expect(layout.foldAdvanced, isFalse);
      expect(layout.rideChartIds, containsAll(['power', 'wprime']));
      expect(layout.rideListFacts, contains('average-power'));
      expect(layout.effortWord, isFalse);
      expect(RiderModeLayout.of(RiderMode.training), RiderModeLayout.full);
    });
  });

  group('situation', () {
    test(
      'RiderModeSituation_ShouldGiveJustRidingAndPrompt_WhenAccountNeverChose',
      () {
        final situation = RiderModeSituation.of(me());

        expect(situation.layout, RiderModeLayout.of(defaultRiderMode));
        expect(situation.prompt, isTrue);
        expect(situation.settings, isTrue);
        expect(situation.mode, isNull);
      },
    );

    test('RiderModeSituation_ShouldGiveFullLayoutAndNoPrompt_WhenServerDoesNotSupportModes', () {
      final situation = RiderModeSituation.of(me(supported: null));

      expect(situation.layout, RiderModeLayout.full);
      expect(situation.prompt, isFalse);
      expect(situation.settings, isFalse);
    });

    test(
      'RiderModeSituation_ShouldGiveFullLayoutAndNoPrompt_WhenMeIsNotLoaded',
      () {
        final situation = RiderModeSituation.of(null);

        expect(situation.layout, RiderModeLayout.full);
        expect(situation.prompt, isFalse);
        expect(situation.settings, isFalse);
      },
    );

    test(
      'RiderModeSituation_ShouldGiveFullLayoutAndNoPrompt_WhenSlugIsUnknown',
      () {
        final situation = RiderModeSituation.of(me(riderMode: 'racing'));

        expect(situation.layout, RiderModeLayout.full);
        expect(situation.prompt, isFalse);
        // The member still changes it from Settings, where nothing is marked.
        expect(situation.settings, isTrue);
        expect(situation.mode, isNull);
      },
    );

    test('RiderModeSituation_ShouldGiveTheChosenMode_WhenTheAccountHasOne', () {
      final situation = RiderModeSituation.of(me(riderMode: 'with_goals'));

      expect(situation.layout, RiderModeLayout.of(RiderMode.withGoals));
      expect(situation.prompt, isFalse);
      expect(situation.mode, RiderMode.withGoals);
    });
  });

  group('view model', () {
    test('RiderModeViewModel_ShouldKeepOldMode_WhenSaveFails', () async {
      final container = await signedIn('rider@example.com', mode: 'training');
      server.unreachable = true;

      final saved = await container
          .read(riderModeViewModelProvider.notifier)
          .choose(RiderMode.justRiding);

      expect(saved, isFalse);
      expect(
        container.read(sessionViewModelProvider).me?.riderMode,
        'training',
      );
      expect(container.read(riderModeViewModelProvider).save.failed, isTrue);
    });

    test('RiderModeViewModel_ShouldStartEmpty_WhenAnotherMemberSignsInAfterSignOut', () async {
      final container = await signedIn('rider@example.com');
      container.read(riderModeViewModelProvider.notifier).promptShown();
      expect(container.read(riderModeViewModelProvider).promptHandled, isTrue);

      await container.read(sessionProvider).signOut();
      server.signInBrowser(server.add('other@example.com', riderMode: null));
      await container.read(sessionProvider).restore();

      expect(container.read(riderModeViewModelProvider).promptHandled, isFalse);
      expect(container.read(riderModeViewModelProvider).save.idle, isTrue);
    });

    test(
      'RiderModeViewModel_ShouldSkipDismissSave_WhenModeWasChosenMeanwhile',
      () async {
        final container = await signedIn('rider@example.com');
        await container
            .read(riderModeViewModelProvider.notifier)
            .choose(RiderMode.withGoals);
        server.requests.clear();

        // The dismissal's save runs after the member chose: it must not write just riding over it.
        final saved = await container
            .read(riderModeViewModelProvider.notifier)
            .choose(defaultRiderMode, onlyIfUnset: true);

        expect(saved, isTrue);
        expect(server.requests, isEmpty);
        expect(
          container.read(sessionViewModelProvider).me?.riderMode,
          'with_goals',
        );
      },
    );
  });

  group('prompt', () {
    /// A registered account has no mode until it chooses, which is what the first sign-in sees.
    Future<void> start(
      WidgetTester tester, {
      String? mode,
      bool old = false,
    }) async {
      server.signInBrowser(server.add('rider@example.com', riderMode: mode));
      if (old) server.riderModeSupported = false;
      await startApp(tester, server.session(useCookies: true));
    }

    testWidgets('RiderModePrompt_ShouldAskOnce_WhenAccountJustRegistered', (
      tester,
    ) async {
      await start(tester);

      expect(find.byKey(const Key('rider-mode-prompt')), findsOneWidget);
      expect(find.byKey(const Key('rider-mode-just_riding')), findsOneWidget);
      expect(find.byKey(const Key('rider-mode-with_goals')), findsOneWidget);
      expect(find.byKey(const Key('rider-mode-training')), findsOneWidget);

      // It stays open until the member answers, and asking again changes nothing.
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('rider-mode-prompt')), findsOneWidget);
    });

    testWidgets(
      'RiderModePrompt_ShouldNotAsk_WhenModeWasChosenOnAnotherDevice',
      (tester) async {
        await start(tester, mode: 'training');

        expect(find.byKey(const Key('rider-mode-prompt')), findsNothing);
      },
    );

    testWidgets('RiderModePrompt_ShouldNotAsk_WhenServerDoesNotSupportModes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await start(tester, old: true);

      expect(find.byKey(const Key('rider-mode-prompt')), findsNothing);

      // Nor does Settings offer the row, so nobody can save a mode the server does not know.
      await openAccount(tester, 'profile');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-rider-mode')), findsNothing);
    });

    testWidgets(
      'RiderModePrompt_ShouldSaveJustRiding_WhenDecideLaterIsTapped',
      (tester) async {
        await start(tester);

        await tester.tap(find.byKey(const Key('rider-mode-later')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('rider-mode-prompt')), findsNothing);
        expect(server.accounts['rider@example.com']!.riderMode, 'just_riding');
      },
    );

    testWidgets('RiderModePrompt_ShouldSaveJustRiding_WhenSheetIsDismissed', (
      tester,
    ) async {
      await start(tester);

      // A tap outside the sheet closes it at once.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rider-mode-prompt')), findsNothing);
      expect(server.accounts['rider@example.com']!.riderMode, 'just_riding');
    });

    testWidgets(
      'RiderModePrompt_ShouldKeepSheetOpenWithError_WhenDecideLaterFails',
      (tester) async {
        await start(tester);
        server.unreachable = true;

        await tester.tap(find.byKey(const Key('rider-mode-later')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('rider-mode-prompt')), findsOneWidget);
        expect(find.byKey(const Key('rider-mode-error')), findsOneWidget);
        expect(server.accounts['rider@example.com']!.riderMode, isNull);

        // Saying it again once the server is back works.
        server.unreachable = false;
        await tester.tap(find.byKey(const Key('rider-mode-later')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('rider-mode-prompt')), findsNothing);
        expect(server.accounts['rider@example.com']!.riderMode, 'just_riding');
      },
    );

    testWidgets(
      'RiderModePrompt_ShouldNotReopenThisSession_WhenDismissSaveFails',
      (tester) async {
        await start(tester);
        server.unreachable = true;

        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();

        // Closed at once; the failed save is invisible and the question stays away for this session.
        expect(find.byKey(const Key('rider-mode-prompt')), findsNothing);
        await goTo(tester, '/progress');
        expect(find.byKey(const Key('rider-mode-prompt')), findsNothing);
        expect(server.accounts['rider@example.com']!.riderMode, isNull);

        // The next app start asks again, because the account still has no mode.
        server.unreachable = false;
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await startApp(tester, server.session(useCookies: true));
        expect(find.byKey(const Key('rider-mode-prompt')), findsOneWidget);
      },
    );
  });

  group('sheet', () {
    /// A wide window, so the account menu is in the rail, and an account that already chose.
    Future<void> openFromSettings(
      WidgetTester tester, {
      String mode = 'training',
    }) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      server.signInBrowser(server.add('rider@example.com', riderMode: mode));
      await startApp(tester, server.session(useCookies: true));
      await openAccount(tester, 'profile');
      await tester.tap(find.byKey(const Key('profile-rider-mode')));
      await tester.pumpAndSettle();
    }

    /// The first-launch question itself.
    Future<void> openPrompt(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      server.signInBrowser(server.add('rider@example.com', riderMode: null));
      await startApp(tester, server.session(useCookies: true));
    }

    testWidgets('ProfileScreen_ShouldMarkCurrentMode_WhenSheetOpens', (
      tester,
    ) async {
      await openFromSettings(tester);

      expect(
        find.descendant(
          of: find.byKey(const Key('rider-mode-training')),
          matching: find.byKey(const Key('rider-mode-selected')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('rider-mode-just_riding')),
          matching: find.byKey(const Key('rider-mode-selected')),
        ),
        findsNothing,
      );
    });

    testWidgets('RiderModeSheet_ShouldShowInlineError_WhenSaveFails', (
      tester,
    ) async {
      await openFromSettings(tester);
      server.unreachable = true;

      await tester.tap(find.byKey(const Key('rider-mode-with_goals')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rider-mode-error')), findsOneWidget);
      // The sheet stays open on the mode the account still holds.
      expect(server.accounts['rider@example.com']!.riderMode, 'training');
    });

    testWidgets(
      'RiderModeSheet_ShouldNotShowOldError_WhenReopenedAfterFailedSave',
      (tester) async {
        await openFromSettings(tester);
        server.unreachable = true;

        await tester.tap(find.byKey(const Key('rider-mode-with_goals')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('rider-mode-error')), findsOneWidget);

        // Closing and opening it again starts clean: the old failure is not shown as if it just happened.
        Navigator.of(tester.element(find.byKey(const Key('rider-mode-later'))))
            .pop();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('profile-rider-mode')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('rider-mode-error')), findsNothing);
      },
    );

    testWidgets(
      'ProfileScreen_ShouldNameNoMode_WhenTheAccountChoseOneThisBuildDoesNotKnow',
      (tester) async {
        await openFromSettings(tester, mode: 'racing');
        final row = find.byKey(const Key('profile-rider-mode'));

        // The mode on the account is not one this build can name, so the row says it neutrally.
        expect(
          find.descendant(
            of: row,
            matching: find.text('Chosen on another device'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: row, matching: find.text('Just riding')),
          findsNothing,
        );
      },
    );

    testWidgets('RiderModeSheet_ShouldHaveTapTargetsOf48_WhenOpened', (
      tester,
    ) async {
      await openPrompt(tester);

      for (final mode in RiderMode.values) {
        final size = tester.getSize(find.byKey(Key('rider-mode-${mode.slug}')));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });
  });

  group('effort', () {
    List<ZoneTime> zones(List<(int, double)> seconds) => [
      for (final (zone, s) in seconds)
        ZoneTime(zone: zone, from: 0, to: null, seconds: s),
    ];

    test('EffortWord_ShouldBeEasy_WhenMostTimeIsInZonesOneToThree', () {
      expect(
        effortWord(zones([(1, 600), (2, 1200), (3, 900), (4, 300), (5, 60)])),
        EffortWord.easy,
      );
    });

    test('EffortWord_ShouldBeHard_WhenTieBetweenModerateAndHard', () {
      expect(effortWord(zones([(4, 500), (5, 500)])), EffortWord.hard);
    });

    test('EffortWord_ShouldBeNull_WhenNoZones', () {
      expect(effortWord(const []), isNull);
    });
  });

  group('progress', () {
    /// The dashboard as the member opens it, in [mode].
    Future<void> openProgress(
      WidgetTester tester, {
      String mode = 'training',
    }) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      server.totals['week'] = [
        totalsJson(
          '2026-11-02',
          '2026-11-08',
          rides: 2,
          distanceM: 42500,
          movingS: 5400,
          elevationGainM: 400,
        ),
      ];
      server.signInBrowser(server.add('rider@example.com', riderMode: mode));
      await startApp(tester, server.session(useCookies: true));
      await goTo(tester, '/progress');
    }

    testWidgets(
      'ProgressScreen_ShouldShowTheSameOverview_WhenTheRiderModeChanges',
      (tester) async {
        await openProgress(tester, mode: 'just_riding');

        // The overview answers one question in every mode: the analysis lives on its own sub-pages.
        for (final key in [
          'metric-readiness',
          'metric-form',
          'metric-period',
          'metric-next-event',
        ]) {
          expect(find.byKey(Key(key)), findsOneWidget, reason: key);
        }
        expect(find.byKey(const Key('more-details')), findsNothing);
        expect(find.byKey(const Key('rider-card')), findsNothing);
        expect(find.byKey(const Key('intensity-card')), findsNothing);
        expect(find.byKey(const Key('wellbeing-card')), findsNothing);
      },
    );

    testWidgets(
      'ProgressScreen_ShouldNotAskForTheAnalysis_WhenTheOverviewOpens',
      (tester) async {
        await openProgress(tester);

        // A card that is not on the page is not fetched either.
        expect(
          server.requests,
          isNot(contains('GET /api/v1/analytics/rider-card')),
        );
        expect(
          server.requests,
          isNot(contains('GET /api/v1/analytics/power-curve')),
        );
      },
    );
  });

  group('more details', () {
    testWidgets('MoreDetails_ShouldFoldAgain_WhenShowLessIsTapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: MoreDetails(
                label: 'More',
                children: const [Text('one card')],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('more-details')));
      await tester.pumpAndSettle();
      expect(find.text('one card'), findsOneWidget);

      await tester.tap(find.byKey(const Key('more-details')));
      await tester.pumpAndSettle();
      expect(find.text('one card'), findsNothing);
    });
  });

  group('ride detail', () {
    Map<String, Object?> ride() => rideJson(
      'r1',
      'ready',
      distanceM: 42300,
      movingS: 5400,
      elevationGainM: 612.4,
      avgSpeedMs: 7.8,
      avgPowerW: 190,
      normalizedPowerW: 205,
      avgHeartRate: 148,
      avgCadence: 87,
      intensityFactor: 0.82,
      tss: 62.4,
      trimp: 48.2,
      heartRateZones: [
        zoneJson(1, 74, 89, 600),
        zoneJson(2, 90, 103, 1200),
        zoneJson(3, 104, 118, 900),
        zoneJson(4, 119, 133, 300),
        zoneJson(5, 134, null, 60),
      ],
      powerZones: [zoneJson(1, 0, 137, 900), zoneJson(2, 138, 187, 1200)],
    );

    Future<void> openRide(
      WidgetTester tester, {
      required String mode,
      Map<String, Object?>? withRide,
    }) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      server.rides.add(withRide ?? ride());
      server.streams['r1'] = streamsJson();
      server.signInBrowser(server.add('rider@example.com', riderMode: mode));
      await startApp(tester, server.session(useCookies: true));
      await goTo(tester, '/rides/r1');
    }

    Future<void> showAllDetails(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const Key('more-details')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('more-details')));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'RideDetailScreen_ShouldShowEffortWordAndHeartRate_WhenModeIsJustRiding',
      (tester) async {
        await openRide(tester, mode: 'just_riding');

        expect(find.byKey(const Key('ride-effort')), findsOneWidget);
        expect(find.text('mostly easy'), findsOneWidget);
        expect(
          find.byKey(const Key('stat-average-heart-rate')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('stat-distance')), findsOneWidget);
      },
    );

    testWidgets('RideDetailScreen_ShouldHideChartsAndLoad_WhenFolded', (
      tester,
    ) async {
      await openRide(tester, mode: 'just_riding');

      expect(find.byKey(const Key('stat-tss')), findsNothing);
      expect(find.byKey(const Key('stat-normalized-power')), findsNothing);
      expect(find.byKey(const Key('stat-average-cadence')), findsNothing);
      expect(find.byKey(const Key('zones')), findsNothing);
      expect(find.byType(SeriesChart), findsNothing);
      expect(find.byKey(const Key('more-details')), findsOneWidget);
    });

    testWidgets(
      'RideDetailScreen_ShouldShowAllMetrics_WhenShowAllDetailsIsTapped',
      (tester) async {
        await openRide(tester, mode: 'just_riding');

        await showAllDetails(tester);

        expect(find.byKey(const Key('stat-tss')), findsOneWidget);
        expect(find.byKey(const Key('stat-normalized-power')), findsOneWidget);
        expect(find.byKey(const Key('zones')), findsOneWidget);
        expect(find.byType(SeriesChart), findsWidgets);
      },
    );

    testWidgets(
      'RideDetailScreen_ShouldNotShowEmptyHeartRate_WhenRideHasNone',
      (tester) async {
        await openRide(
          tester,
          mode: 'just_riding',
          withRide: rideJson(
            'r1',
            'ready',
            distanceM: 42300,
            movingS: 5400,
            elevationGainM: 612.4,
            avgSpeedMs: 7.8,
            avgPowerW: 190,
          ),
        );

        // No heart rate is no effort word and no heart-rate tile, not "easy" by default.
        expect(find.byKey(const Key('ride-effort')), findsNothing);
        expect(find.byKey(const Key('stat-average-heart-rate')), findsNothing);
        expect(find.byKey(const Key('zones')), findsNothing);
      },
    );

    testWidgets(
      'RideDetailScreen_ShouldShowZonesAndMainCharts_WhenModeIsWithGoals',
      (tester) async {
        await openRide(tester, mode: 'with_goals');

        // This mode keeps the zones and the main charts, and folds the power analysis.
        expect(find.byKey(const Key('zones')), findsOneWidget);
        expect(find.text('Heart rate zones'), findsWidgets);
        expect(
          find.byKey(const Key('stat-average-heart-rate')),
          findsOneWidget,
        );
        expect(find.byType(SeriesChart), findsNWidgets(3));
        expect(find.byKey(const Key('more-details')), findsOneWidget);
        expect(find.byKey(const Key('stat-tss')), findsNothing);
      },
    );

    testWidgets(
      'RideDetailScreen_ShouldShowEverythingUnfolded_WhenModeIsTraining',
      (tester) async {
        await openRide(tester, mode: 'training');

        // Training folds nothing and guesses no effort word: every number is on the page.
        expect(find.byKey(const Key('more-details')), findsNothing);
        expect(find.byKey(const Key('ride-effort')), findsNothing);
        expect(find.byKey(const Key('stat-tss')), findsOneWidget);
        expect(find.byKey(const Key('zones')), findsOneWidget);
        expect(find.byType(SeriesChart), findsWidgets);
      },
    );

    testWidgets('RideDetailScreen_ShouldKeepEditAndDelete_WhenModeIsSimple', (
      tester,
    ) async {
      await openRide(tester, mode: 'just_riding');

      await tester.tap(find.byKey(const Key('ride-actions')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit-ride-text')), findsOneWidget);
      expect(find.byKey(const Key('delete')), findsOneWidget);
    });
  });

  group('rides list', () {
    Future<void> openRides(WidgetTester tester, {required String mode}) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      server.rides.add(
        rideJson(
          'r1',
          'ready',
          distanceM: 42300,
          movingS: 5400,
          elevationGainM: 612.4,
          avgSpeedMs: 7.8,
          avgPowerW: 190,
          avgHeartRate: 148,
          avgCadence: 87,
        ),
      );
      server.signInBrowser(server.add('rider@example.com', riderMode: mode));
      await startApp(tester, server.session(useCookies: true));
    }

    testWidgets(
      'RideCard_ShouldShowOnlyDistanceAndTime_WhenLayoutIsJustRiding',
      (tester) async {
        await openRides(tester, mode: 'just_riding');
        final card = find.byKey(const Key('ride-r1'));

        expect(
          tester
              .widget<FactGrid>(
                find.descendant(of: card, matching: find.byType(FactGrid)),
              )
              .facts,
          hasLength(2),
        );
        // The heart rate is not on this card.
        expect(
          find.descendant(of: card, matching: find.text('148 bpm')),
          findsNothing,
        );
      },
    );

    testWidgets('RideCard_ShouldAddHeartRate_WhenLayoutIsWithGoals', (
      tester,
    ) async {
      await openRides(tester, mode: 'with_goals');
      final card = find.byKey(const Key('ride-r1'));

      expect(
        tester
            .widget<FactGrid>(
              find.descendant(of: card, matching: find.byType(FactGrid)),
            )
            .facts,
        hasLength(3),
      );
      expect(
        find.descendant(of: card, matching: find.text('148 bpm')),
        findsOneWidget,
      );
    });

    testWidgets('RideCard_ShouldRebuildWithoutReload_WhenModeChanges', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      server.rides.add(
        rideJson(
          'r1',
          'ready',
          distanceM: 42300,
          movingS: 5400,
          avgHeartRate: 148,
        ),
      );
      server.signInBrowser(
        server.add('rider@example.com', riderMode: 'just_riding'),
      );
      final session = server.session(useCookies: true);
      await startApp(tester, session);
      final card = find.byKey(const Key('ride-r1'));
      expect(
        find.descendant(of: card, matching: find.text('148 bpm')),
        findsNothing,
      );
      final before = server.requests
          .where((r) => r == 'GET /api/v1/rides')
          .length;

      // The account changes its mode elsewhere: /me is read again, the cards follow, the rides are not reloaded.
      server.accounts['rider@example.com']!.riderMode = 'training';
      await session.refreshMe();
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: card, matching: find.text('148 bpm')),
        findsOneWidget,
      );
      expect(
        server.requests.where((r) => r == 'GET /api/v1/rides').length,
        before,
      );
    });
  });
}
