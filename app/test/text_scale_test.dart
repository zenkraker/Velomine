import 'package:material_ui/material_ui.dart';
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
    String path = '',
    double textScale = 2,
  }) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await startApp(tester, server.session(useCookies: true));
    if (path.isNotEmpty) await goTo(tester, path);
  }

  for (final (path, name) in [
    ('', 'rides'),
    ('/record', 'record'),
    ('/progress', 'progress'),
    ('/bikes', 'bikes'),
  ]) {
    testWidgets('${name}_ShouldLayOutWithoutClipping_WhenTextIsTwiceTheSize', (
      tester,
    ) async {
      await open(tester, path: path);

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('bikeForm_ShouldLayOutWithoutClipping_WhenTextIsTwiceTheSize', (
    tester,
  ) async {
    await open(tester, path: '/bikes');
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

    expect(find.byKey(const Key('profile-name')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
