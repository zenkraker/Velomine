import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/theme.dart';
import 'package:velomine/core/widgets/bar_chart.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
    server.training = trainingJson();
  });

  Future<void> openFitness(
    WidgetTester tester, {
    Size size = const Size(1000, 2400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/progress/fitness');
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('FitnessScreen_ShouldShowTheTrainingTotals_WhenTheRangeChanges', (
    tester,
  ) async {
    await openFitness(tester);

    await reveal(tester, find.byKey(const Key('training-tss')));
    expect(server.trainingRequests, [90]);
    expect(
      tester.widget<Text>(find.byKey(const Key('training-tss'))).data,
      '240',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('training-trimp'))).data,
      '180',
    );
    expect(find.byKey(const Key('fitness-chart')), findsOneWidget);
    expect(find.byKey(const Key('tss-chart')), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('training-range')),
        matching: find.text('30 d'),
      ),
    );
    await tester.pumpAndSettle();

    expect(server.trainingRequests, [90, 30]);
  });

  testWidgets(
    'FitnessScreen_ShouldDrawDashedFatigueAndFormBars_WhenTrainingHasDays',
    (tester) async {
      server.training = {
        ...trainingJson(),
        'days': [
          for (var i = 0; i < 14; i++)
            {
              'date': '2026-11-${(1 + i).toString().padLeft(2, '0')}',
              'rides': 1,
              'distanceM': 20000.0,
              'movingS': 3600.0,
              'elevationGainM': 200.0,
              'tss': 40.0 + i,
              'trimp': 30.0 + i,
              'load': 40.0 + i,
              'fitness': 18.0 + i,
              'fatigue': 22.0 + i,
              'form': i.isEven ? 4.0 : -4.0,
            },
        ],
      };
      await openFitness(tester);

      // One chart draws all three series, and the sentence says which way it goes.
      final chart = find.byKey(const Key('fitness-chart'));
      expect(chart, findsOneWidget);
      expect(find.byKey(const Key('fitness-trend')), findsOneWidget);
      expect(find.text('Your fitness is rising.'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp(r'Fitness \d+, fatigue \d+, form -?\d+\.'),
        ),
        findsOneWidget,
      );
      // The range control is the chart's only setting.
      expect(find.byKey(const Key('training-range')), findsOneWidget);
    },
  );

  testWidgets(
    'FitnessScreen_ShouldSayHowTheRangeSplits_WhenThereIsIntensityData',
    (tester) async {
      server.training = {
        ...trainingJson(),
        'intensity': {
          'easyS': 6000.0,
          'moderateS': 3000.0,
          'hardS': 1000.0,
          'easyPct': 60.0,
          'moderatePct': 30.0,
          'hardPct': 10.0,
          'polarisationIndex': 1.3,
          'label': 'pyramidal',
          'rides': 3,
        },
        'intensityWeeks': [
          {
            'weekStart': '2026-11-02',
            'easyS': 6000.0,
            'moderateS': 3000.0,
            'hardS': 1000.0,
          },
        ],
      };
      await openFitness(tester);

      await reveal(tester, find.byKey(const Key('intensity-card')));

      expect(
        find.text('Pyramidal: most easy, less moderate, least hard'),
        findsOneWidget,
      );
      // Three labelled rows, each with its own share, as the design draws them.
      void row(String label, String share) {
        final card = find.byKey(const Key('intensity-card'));
        expect(
          find.descendant(of: card, matching: find.text(label)),
          findsOneWidget,
          reason: label,
        );
        expect(
          find.descendant(of: card, matching: find.text(share)),
          findsOneWidget,
          reason: share,
        );
      }

      row('Easy', '60 %');
      row('Moderate', '30 %');
      row('Hard', '10 %');
      // Each bar is the shared one, in the design's three colours.
      final colors = VelomineColors.of(
        tester.element(find.byKey(const Key('intensity-card'))),
      );
      final ink = Theme.of(
        tester.element(find.byKey(const Key('intensity-card'))),
      ).colorScheme.onSurfaceVariant;
      final bars = tester.widgetList<ShareBar>(find.byType(ShareBar)).toList();
      expect(
        [for (final bar in bars) bar.color],
        [ink, colors.barMuted, colors.accentStrong],
      );
      expect(
        find.text('From power where you have it, otherwise heart rate.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'FitnessScreen_ShouldHideTheIntensityCard_WhenNoRideHadPowerOrHeartRate',
    (tester) async {
      await openFitness(tester);

      expect(find.byKey(const Key('intensity-card')), findsNothing);
    },
  );

  testWidgets(
    'FitnessScreen_ShouldShowTheAerobicEfficiency_WhenThereAreWeeks',
    (tester) async {
      server.training = {
        ...trainingJson(),
        'efficiency': [
          {'weekStart': '2026-10-26', 'efficiencyFactor': 1.32, 'rides': 1},
          {'weekStart': '2026-11-02', 'efficiencyFactor': 1.38, 'rides': 2},
        ],
      };
      await openFitness(tester);

      await reveal(tester, find.byKey(const Key('efficiency-chart')));
      expect(find.byKey(const Key('efficiency-card')), findsOneWidget);
    },
  );

  for (final width in [390.0, 600.0, 820.0, 1300.0]) {
    testWidgets('FitnessScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}', (
      tester,
    ) async {
      server.training = {
        ...trainingJson(),
        'intensity': {
          'easyS': 6000.0,
          'moderateS': 3000.0,
          'hardS': 1000.0,
          'easyPct': 60.0,
          'moderatePct': 30.0,
          'hardPct': 10.0,
          'polarisationIndex': 1.3,
          'label': 'pyramidal',
          'rides': 3,
        },
        'efficiency': [
          {'weekStart': '2026-11-02', 'efficiencyFactor': 1.38, 'rides': 2},
        ],
      };
      await openFitness(tester, size: Size(width, 2400));

      expect(find.byKey(const Key('fitness-chart')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('FitnessScreen_ShouldNotOverflow_WhenTextIsTwiceItsSize', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openFitness(tester, size: const Size(390, 2600));

    expect(tester.takeException(), isNull);
  });
}
