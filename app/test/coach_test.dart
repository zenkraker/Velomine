import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.rides.add(
      rideJson('r1', 'ready', distanceM: 24500, movingS: 3720, avgPowerW: 190),
    );
    server.streams['r1'] = {
      'time': [0.0, 1.0, 2.0],
      'latitude': [46.0, 46.001, 46.002],
      'longitude': [11.0, 11.0, 11.0],
      'altitude': [300.0, 301.0, 302.0],
      'speed': [8.0, 8.0, 8.0],
      'distance': [0.0, 8.0, 16.0],
      'heartRate': [150, 151, 152],
      'power': [190, 195, 200],
      'cadence': [90, 90, 90],
      'temperature': null,
    };
  });

  testWidgets('a member chooses who sees what in the Club tab', (tester) async {
    final rider = server.add('rider@example.com');
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));

    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('share-rides')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My coaches').last);
    await tester.pumpAndSettle();

    expect(server.sharingChoices['rides'], 'coaches');
    expect(server.sharingChoices['analytics'], 'none');
    expect(server.sharingChoices['routes'], 'none');
  });

  testWidgets('the roster shows only the kinds of data shared', (tester) async {
    final owner = server.add(
      'owner@example.com',
      name: 'Owner Rina',
      clubRole: 'owner',
    );
    final athlete = server.add('athlete@example.com', name: 'Athlete Luca');
    server.sharingChoices['rides'] = 'coaches';
    server.sharingChoices['analytics'] = 'none';
    server.signInBrowser(owner);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-athletes')));
    await tester.pumpAndSettle();

    final card = find.byKey(Key('athlete-${athlete.id}'));
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.textContaining('TSS')),
      findsNothing,
    );

    // Training only: no ride date on the roster, but the load is there.
    server.sharingChoices['rides'] = 'none';
    server.sharingChoices['analytics'] = 'coaches';
    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-athletes')));
    await tester.pumpAndSettle();

    final refreshed = find.byKey(Key('athlete-${athlete.id}'));
    expect(
      find.descendant(of: refreshed, matching: find.textContaining('TSS')),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: refreshed,
        matching: find.textContaining('Last ride'),
      ),
      findsNothing,
    );
  });

  testWidgets('a coach sees shared training and rides, and no route yet', (
    tester,
  ) async {
    final owner = server.add(
      'owner@example.com',
      name: 'Owner Rina',
      clubRole: 'owner',
    );
    final athlete = server.add('athlete@example.com', name: 'Athlete Luca');
    server.sharingChoices['rides'] = 'coaches';
    server.sharingChoices['analytics'] = 'coaches';
    server.signInBrowser(owner);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-athletes')));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('athlete-${athlete.id}')), findsOneWidget);
    expect(find.text('Athlete Luca'), findsOneWidget);

    await tester.tap(find.byKey(Key('athlete-${athlete.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('training-tss')), findsOneWidget);
    expect(find.byKey(const Key('coach-ride-r1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('coach-ride-r1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('coach-ride-not-found')), findsNothing);
    expect(find.byKey(const Key('route-not-shared')), findsOneWidget);
    expect(find.byKey(const Key('chart-power')), findsOneWidget);

    // The athlete shares routes too: the same ride now has its map.
    server.sharingChoices['routes'] = 'coaches';
    await tester.tap(find.byKey(const Key('coach-ride-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('coach-ride-r1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('route-map')), findsOneWidget);
    expect(find.byKey(const Key('route-not-shared')), findsNothing);
  });
}
