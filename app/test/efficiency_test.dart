import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
  });

  Future<void> openFitness(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/progress/fitness');
  }

  Future<void> openRide(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.byKey(const Key('ride-r1')));
    await tester.pumpAndSettle();
  }

  void addRide({
    double? efficiencyFactor,
    double? decouplingPct,
    bool? steady,
  }) {
    server.rides.add(
      rideJson(
        'r1',
        'ready',
        distanceM: 60000,
        movingS: 5400,
        avgPowerW: 190,
        normalizedPowerW: 205,
        avgHeartRate: 143,
        efficiencyFactor: efficiencyFactor,
        decouplingPct: decouplingPct,
        steady: steady,
      ),
    );
    server.streams['r1'] = streamsJson();
  }

  testWidgets('RideStats_ShouldSaySteadyHeartRate_WhenDecouplingIsBelowFive', (
    tester,
  ) async {
    addRide(efficiencyFactor: 1.39, decouplingPct: 4.8, steady: true);

    await openRide(tester);

    expect(
      find.descendant(
        of: find.byKey(const Key('stat-efficiency')),
        matching: find.text('1.39'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('stat-decoupling')),
        matching: find.text('4.8 %'),
      ),
      findsOneWidget,
    );
    expect(find.text('Decoupling 4.8 % · Steady heart rate'), findsOneWidget);
    expect(
      find.text('From steady pedalling after a 15-minute warm-up'),
      findsOneWidget,
    );
  });

  testWidgets(
    'RideStats_ShouldSaySomeDrift_WhenDecouplingIsBetweenFiveAndTen',
    (tester) async {
      addRide(efficiencyFactor: 1.35, decouplingPct: 7.4, steady: true);

      await openRide(tester);

      expect(find.text('Decoupling 7.4 % · Some drift'), findsOneWidget);
    },
  );

  testWidgets('RideStats_ShouldSayLargeDrift_WhenDecouplingIsAboveTen', (
    tester,
  ) async {
    addRide(efficiencyFactor: 1.30, decouplingPct: 12.5, steady: true);

    await openRide(tester);

    expect(find.text('Decoupling 12.5 % · Large drift'), findsOneWidget);
  });

  testWidgets(
    'RideStats_ShouldShowEfficiencyWithoutDecoupling_WhenTheRideIsNotSteady',
    (tester) async {
      addRide(efficiencyFactor: 1.4, decouplingPct: null, steady: false);

      await openRide(tester);

      expect(find.byKey(const Key('stat-efficiency')), findsOneWidget);
      expect(find.byKey(const Key('stat-decoupling')), findsNothing);
      expect(find.byKey(const Key('decoupling')), findsNothing);
    },
  );

  testWidgets(
    'FitnessScreen_ShouldShowEfficiencyInWords_WhenSteadyRidesExist',
    (tester) async {
      server.training = {
        ...trainingJson(),
        'efficiency': [
          {'weekStart': '2026-10-26', 'efficiencyFactor': 1.32, 'rides': 1},
          {'weekStart': '2026-11-02', 'efficiencyFactor': 1.38, 'rides': 2},
        ],
      };

      await openFitness(tester);

      await tester.scrollUntilVisible(
        find.byKey(const Key('efficiency-card')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('efficiency-chart')), findsOneWidget);
      expect(
        find.text('Higher is better: more power for the same heart rate.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('FitnessScreen_ShouldSayWhatIsMissing_WhenThereIsNoSteadyRide', (
    tester,
  ) async {
    await openFitness(tester);

    await tester.scrollUntilVisible(
      find.byKey(const Key('efficiency-card')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('efficiency-chart')), findsNothing);
    expect(
      find.text(
        'Needs steady rides of about an hour with power and heart rate.',
      ),
      findsOneWidget,
    );
  });
}
