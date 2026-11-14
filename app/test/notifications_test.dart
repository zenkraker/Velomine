import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
    server.rides.add(
      rideJson('ride-1', 'ready', fileName: 'morning.fit', distanceM: 24500),
    );
    server.bikes.add({
      'id': 'bike-1',
      'name': 'Road bike',
      'kind': 'road',
      'wheelCircumferenceMm': 2105,
      'initialDistanceM': 0.0,
    });
    server.notifications.addAll([
      notificationJson(
        'n-3',
        'part_worn',
        'Chain on Road bike',
        bikeId: 'bike-1',
      ),
      notificationJson('n-2', 'ride_failed', 'broken.fit'),
      notificationJson(
        'n-1',
        'ride_ready',
        'morning.fit',
        rideId: 'ride-1',
        isRead: true,
      ),
    ]);
  });

  Future<void> openNotifications(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.byKey(const Key('open-notifications')));
    await tester.pumpAndSettle();
  }

  testWidgets('NotificationsScreen_ShouldShowUnreadCount_WhenSomeAreUnread', (
    tester,
  ) async {
    await startApp(tester, server.session(useCookies: true));

    expect(
      find.descendant(
        of: find.byKey(const Key('open-notifications')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('NotificationsScreen_ShouldShowSentencesNewestFirst_WhenOpened', (
    tester,
  ) async {
    await openNotifications(tester);

    expect(
      find.text('Chain on Road bike is worn out. Time to replace it.'),
      findsOneWidget,
    );
    expect(find.text('broken.fit could not be read.'), findsOneWidget);
    expect(find.text('Your ride morning.fit is ready.'), findsOneWidget);
    expect(find.byKey(const Key('no-notifications')), findsNothing);
  });

  testWidgets('NotificationsScreen_ShouldMarkReadAndOpenTarget_WhenTapped', (
    tester,
  ) async {
    await openNotifications(tester);

    await tester.tap(
      find.text('Chain on Road bike is worn out. Time to replace it.'),
    );
    await tester.pumpAndSettle();

    expect(server.requests, contains('POST /api/v1/notifications/n-3/read'));
    expect(server.notifications.first['isRead'], isTrue);
    expect(find.text('Road bike'), findsWidgets); // the bike's screen
    // Back to a tab: the title bar keeps its actions there, not on a pushed screen.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('open-notifications')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('NotificationsScreen_ShouldClearUnreadCount_WhenMarkingAllRead', (
    tester,
  ) async {
    await openNotifications(tester);

    await tester.tap(find.byKey(const Key('notifications-read-all')));
    await tester.pumpAndSettle();

    expect(server.notifications.every((n) => n['isRead'] == true), isTrue);
    expect(find.byKey(const Key('notifications-read-all')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('open-notifications')),
        matching: find.text('2'),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'NotificationsScreen_ShouldPutMarkAllReadInTheTitleBar_WhenTheScreenIsAPhone',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));
      await tester.tap(find.byKey(const Key('open-notifications')));
      await tester.pumpAndSettle();

      // No page header on a phone, so the action is a title-bar control.
      await tester.tap(find.byKey(const Key('notifications-read-all')));
      await tester.pumpAndSettle();

      expect(server.notifications.every((n) => n['isRead'] == true), isTrue);
      expect(find.byKey(const Key('notifications-read-all')), findsNothing);
    },
  );

  testWidgets('NotificationsScreen_ShouldShowEmptyMessage_WhenThereAreNone', (
    tester,
  ) async {
    server.notifications.clear();
    await openNotifications(tester);

    expect(find.byKey(const Key('no-notifications')), findsOneWidget);
  });
}
