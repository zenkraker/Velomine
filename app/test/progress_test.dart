import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
    server.totals['week'] = [
      totalsJson(
        '2026-10-26',
        '2026-11-01',
        rides: 1,
        distanceM: 60000,
        movingS: 7200,
        elevationGainM: 500,
      ),
      totalsJson(
        '2026-11-02',
        '2026-11-08',
        rides: 2,
        distanceM: 42500,
        movingS: 5400,
        elevationGainM: 400,
      ),
    ];
    server.totals['month'] = [
      totalsJson('2026-11-01', '2026-11-30', rides: 3, distanceM: 102500),
    ];
  });

  Future<void> openProgress(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
  }

  testWidgets('weekly totals show this week first, with every number', (
    tester,
  ) async {
    await openProgress(tester);

    expect(server.requests, contains('GET /api/v1/analytics/totals'));
    final thisWeek = find.byKey(const Key('total-0'));
    expect(
      find.descendant(of: thisWeek, matching: find.text('This week')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: thisWeek, matching: find.text('42.5 km')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: thisWeek,
        matching: find.text('2 rides · 1 h 30 min · 400 m climbing'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('total-1')), findsOneWidget);
    expect(find.byKey(const Key('no-goals')), findsOneWidget);
  });

  testWidgets('switching to months asks for monthly totals', (tester) async {
    await openProgress(tester);

    await tester.tap(find.text('Months'));
    await tester.pumpAndSettle();

    expect(find.text('This month'), findsOneWidget);
    expect(find.text('103 km'), findsWidgets); // 102.5 km, rounded
  });

  testWidgets('a goal is added in km and sent in metres, with its progress', (
    tester,
  ) async {
    server.goalCurrent['distance'] = 40000;
    await openProgress(tester);

    await tester.tap(find.byKey(const Key('add-goal')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('goal-target')), '100');
    await tester.tap(find.byKey(const Key('goal-save')));
    await tester.pumpAndSettle();

    expect(server.goals.single, {
      'id': 'goal-1',
      'period': 'week',
      'metric': 'distance',
      'target': 100000.0,
    });
    expect(find.text('Weekly distance'), findsOneWidget);
    expect(find.text('40.0 km of 100 km · 40 %'), findsOneWidget);
  });

  testWidgets('a goal target can be changed, and the goal deleted', (
    tester,
  ) async {
    server.goals.add({
      'id': 'goal-1',
      'period': 'month',
      'metric': 'time',
      'target': 36000.0,
    });
    server.goalCurrent['time'] = 36000;
    await openProgress(tester);
    expect(find.text('Reached'), findsOneWidget);

    await tester.tap(find.byKey(const Key('goal-edit-goal-1')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('goal-target')))
          .controller!
          .text,
      '10',
    );
    await tester.enterText(find.byKey(const Key('goal-target')), '20');
    await tester.tap(find.byKey(const Key('goal-save')));
    await tester.pumpAndSettle();
    expect(server.goals.single['target'], 72000.0);
    expect(find.text('10 h 00 min of 20 h 00 min · 50 %'), findsOneWidget);

    await tester.tap(find.byKey(const Key('goal-delete-goal-1')));
    await tester.pumpAndSettle();
    expect(server.goals, isEmpty);
    expect(find.byKey(const Key('no-goals')), findsOneWidget);
  });

  testWidgets('an empty target is not sent', (tester) async {
    await openProgress(tester);

    await tester.tap(find.byKey(const Key('add-goal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('goal-save')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a target above 0.'), findsOneWidget);
    expect(server.goals, isEmpty);
  });
}
