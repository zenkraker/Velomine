import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/result.dart';
import 'package:velomine/core/session.dart';
import 'package:velomine/core/tokens.dart';
import 'package:velomine/core/widgets/app_card.dart';
import 'package:velomine/core/widgets/loading_state.dart';
import 'package:velomine/core/widgets/page_scaffold.dart';
import 'package:velomine/core/widgets/section_heading.dart';
import 'package:velomine/features/notifications/notifications_data.dart';
import 'package:velomine_api/api.dart';

import 'fake_server.dart';

/// A data source whose first read never finishes, so the screen's first load can be seen.
class _HeldNotificationsData extends NotificationsData {
  _HeldNotificationsData(Session session) : super(session.notifications);

  @override
  Future<Result<ListNotificationsResponse?>> list() =>
      Completer<Result<ListNotificationsResponse?>>().future;
}

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
    // The page's one action keeps its place, with nothing left to do.
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('notifications-read-all')))
          .onPressed,
      isNull,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('open-notifications')),
        matching: find.text('2'),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'NotificationsScreen_ShouldOfferMarkAllRead_WhenTheScreenIsAPhone',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));
      await tester.tap(find.byKey(const Key('open-notifications')));
      await tester.pumpAndSettle();

      // The page header shows on a phone too, so the action is under it.
      await tester.tap(find.byKey(const Key('notifications-read-all')));
      await tester.pumpAndSettle();

      expect(server.notifications.every((n) => n['isRead'] == true), isTrue);
      expect(find.byKey(const Key('notifications-read-all')), findsOneWidget);
    },
  );

  testWidgets(
    'NotificationsScreen_ShouldPutMarkAllReadInTheHeader_WhenThereAreUnread',
    (tester) async {
      await openNotifications(tester);

      final action = tester.getTopLeft(
        find.byKey(const Key('notifications-read-all')),
      );
      final firstTile = tester.getTopLeft(
        find.byKey(Key('notification-${server.notifications.first['id']}')),
      );
      expect(find.byType(FilledButton), findsWidgets);
      expect(action.dy, lessThan(firstTile.dy));
    },
  );

  testWidgets('NotificationsScreen_ShouldShowEmptyMessage_WhenThereAreNone', (
    tester,
  ) async {
    server.notifications.clear();
    await openNotifications(tester);

    expect(find.byKey(const Key('no-notifications')), findsOneWidget);
  });

  testWidgets(
    'NotificationsScreen_ShouldShowTheUnreadGroupFirst_WhenSomeAreUnread',
    (tester) async {
      await openNotifications(tester);

      final unreadGroup = find.byKey(const Key('notification-group-unread'));
      expect(unreadGroup, findsOneWidget);
      // Every unread row is in it, and every read row is not.
      expect(
        find.descendant(
          of: unreadGroup,
          matching: find.byKey(const Key('notification-n-3')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: unreadGroup,
          matching: find.byKey(const Key('notification-n-2')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: unreadGroup,
          matching: find.byKey(const Key('notification-n-1')),
        ),
        findsNothing,
      );
      // Above every area group of the read ones.
      expect(
        tester.getTopLeft(unreadGroup).dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const Key('notification-group-rides')))
              .dy,
        ),
      );
      // An unread row says so in words.
      expect(find.text('Unread'), findsWidgets);
    },
  );

  testWidgets(
    'NotificationsScreen_ShouldDrawOneCardPerGroup_WhenAGroupHasRows',
    (tester) async {
      server.notifications
        ..clear()
        ..addAll([
          notificationJson(
            'n-1',
            'ride_ready',
            'a.fit',
            rideId: 'ride-1',
            isRead: true,
          ),
          notificationJson('n-2', 'ride_failed', 'b.fit', isRead: true),
        ]);
      await openNotifications(tester);

      // One card titled with the area, holding its rows, not one card per row.
      final group = find.byKey(const Key('notification-group-rides'));
      expect(group, findsOneWidget);
      expect(find.widgetWithText(AppCard, 'Rides'), findsOneWidget);
      expect(
        find.descendant(
          of: group,
          matching: find.byKey(const Key('notification-n-1')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: group,
          matching: find.byKey(const Key('notification-n-2')),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'NotificationsScreen_ShouldGroupByArea_WhenNotificationsSpanTwoAreas',
    (tester) async {
      // Everything read, so the area groups are what the page shows.
      for (final n in server.notifications) {
        n['isRead'] = true;
      }
      await openNotifications(tester);

      // Each area has its own card, and its rows sit inside it.
      final bikes = find.byKey(const Key('notification-group-bikes'));
      final rides = find.byKey(const Key('notification-group-rides'));
      expect(bikes, findsOneWidget);
      expect(rides, findsOneWidget);
      expect(find.byKey(const Key('notification-group-unread')), findsNothing);
      expect(
        find.descendant(
          of: bikes,
          matching: find.byKey(const Key('notification-n-3')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: rides,
          matching: find.byKey(const Key('notification-n-2')),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('NotificationsScreen_ShouldOpenTheTarget_WhenARowIsTapped', (
    tester,
  ) async {
    await openNotifications(tester);

    await tester.tap(find.byKey(const Key('notification-n-3')));
    await tester.pumpAndSettle();

    // A bike warning opens that bike.
    expect(find.byKey(const Key('bike-title')), findsOneWidget);
    expect(server.requests, contains('POST /api/v1/notifications/n-3/read'));
  });

  testWidgets('NotificationsScreen_ShouldShowALoadingState_WhenFirstOpened', (
    tester,
  ) async {
    final session = server.session(useCookies: true);
    final data = _HeldNotificationsData(session);
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(
      tester,
      session,
      overrides: [notificationsDataProvider.overrideWithValue(data)],
    );

    await tester.tap(find.byKey(const Key('open-notifications')));
    await tester.pump();
    await tester.pump(AppMotion.standard);

    // The first frame is a loading state, not a blank page and not "nothing here".
    expect(find.byType(LoadingState), findsOneWidget);
    expect(find.byKey(const Key('no-notifications')), findsNothing);
  });

  testWidgets('NotificationsScreen_ShouldUseTheSectionHeading_WhenGrouping', (
    tester,
  ) async {
    await openNotifications(tester);

    expect(
      find.descendant(
        of: find.byKey(const Key('notification-group-rides')),
        matching: find.byType(SectionHeading),
      ),
      findsOneWidget,
    );
  });

  testWidgets('NotificationsScreen_ShouldKeepTheNarrowMeasure_WhenOpened', (
    tester,
  ) async {
    await openNotifications(tester);

    expect(
      tester.widget<PageScaffold>(find.byType(PageScaffold)).maxWidth,
      AppLayout.contentNarrow,
    );
  });

  testWidgets(
    'CalendarFeedScreen_ShouldPutCreateInTheHeader_WhenThereIsNoAddress',
    (tester) async {
      server.clubRoles['rider@example.com'] = 'owner';
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));

      await goTo(tester, '/club/calendar');

      final create = find.byKey(const Key('create-calendar-address'));
      expect(create, findsOneWidget);
      // In the title row, above the card it acts on, never inside it.
      expect(
        find.descendant(
          of: find.byKey(const Key('calendar-address-card')),
          matching: create,
        ),
        findsNothing,
      );
      expect(
        tester.getTopLeft(create).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('calendar-address-card'))).dy,
        ),
      );
    },
  );

  for (final width in [390.0, 600.0, 1300.0]) {
    testWidgets(
      'NotificationsScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
        tester.view.physicalSize = Size(width, 2000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await startApp(tester, server.session(useCookies: true));
        await tester.tap(find.byKey(const Key('open-notifications')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('notification-n-3')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
