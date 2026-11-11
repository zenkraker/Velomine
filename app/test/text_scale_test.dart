import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

/// The five screens a member keeps open, at the largest text the system offers on a phone.
void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
    server.rides.add(rideJson('r1', 'ready', distanceM: 42300, movingS: 5400));
    server.notifications.add({
      'id': 'n1',
      'kind': 'ride',
      'body': 'Your ride was read.',
      'isRead': false,
      'createdAt': '2026-11-09T10:00:00Z',
    });
  });

  Future<void> open(
    WidgetTester tester, {
    String tab = '',
    double textScale = 2,
  }) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await startApp(tester, server.session(useCookies: true));
    if (tab.isNotEmpty) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
    }
  }

  for (final (tab, name) in [
    ('', 'rides'),
    ('Record', 'record'),
    ('Progress', 'progress'),
    ('Bikes', 'bikes'),
  ]) {
    testWidgets('${name}_ShouldLayOutWithoutClipping_WhenTextIsTwiceTheSize', (
      tester,
    ) async {
      await open(tester, tab: tab);

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('bikeForm_ShouldLayOutWithoutClipping_WhenTextIsTwiceTheSize', (
    tester,
  ) async {
    await open(tester, tab: 'Bikes');
    await tester.tap(find.byKey(const Key('add-bike')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bike-name')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile_ShouldLayOutWithoutClipping_WhenTextIsTwiceTheSize', (
    tester,
  ) async {
    await open(tester);
    await openAccount(tester, 'profile');

    expect(find.byKey(const Key('profile-save')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
