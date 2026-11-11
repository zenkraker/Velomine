import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:velomine_api/api.dart';
import 'package:velomine/features/notifications/notifications_text.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() => server = FakeServer());

  void widen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> openClub(WidgetTester tester) async {
    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();
  }

  void ask(FakeAccount rider) => server.joinRequests.add({
    'id': 'join-1',
    'clubId': 'club-1',
    'userId': rider.id,
    'displayName': rider.name,
    'note': null,
    'createdAt': '2026-11-09T10:00:00Z',
  });

  testWidgets('ClubScreen_ShouldShowRoomAndPaidUntil_WhenOwnerHasAPlan', (
    tester,
  ) async {
    widen(tester);
    final owner = server.add('owner@example.com', clubRole: 'owner');
    server.add('rider@example.com');
    server.clubMemberLimit = 25;
    server.clubPaidUntil = '2099-03-31';
    server.signInBrowser(owner);

    await openClub(tester);

    expect(find.byKey(const Key('club-plan-card')), findsOneWidget);
    expect(find.text('2 of 25 members'), findsOneWidget);
    expect(find.byKey(const Key('club-plan-bar')), findsOneWidget);
    expect(find.textContaining('Paid until'), findsOneWidget);
    expect(find.byKey(const Key('club-plan-notice')), findsNothing);
  });

  testWidgets('ClubScreen_ShouldShowNothingAboutThePlan_WhenAnOrdinaryMember', (
    tester,
  ) async {
    widen(tester);
    server.add('owner@example.com', clubRole: 'owner');
    final rider = server.add('rider@example.com');
    server.clubMemberLimit = 25;
    server.clubPaidUntil = '2099-03-31';
    server.signInBrowser(rider);

    await openClub(tester);

    expect(find.byKey(const Key('club-plan-card')), findsNothing);
    expect(find.textContaining('Paid until'), findsNothing);
    expect(find.textContaining('of 25'), findsNothing);
  });

  testWidgets('ClubScreen_ShouldShowNoPlan_WhenTheClubHasNoLimitAndNoDate', (
    tester,
  ) async {
    widen(tester);
    final owner = server.add('owner@example.com', clubRole: 'owner');
    server.signInBrowser(owner);

    await openClub(tester);

    expect(find.byKey(const Key('club-plan-card')), findsNothing);
  });

  testWidgets('ClubScreen_ShouldExplainAndDisableApprove_WhenTheClubIsFull', (
    tester,
  ) async {
    widen(tester);
    final owner = server.add('owner@example.com', clubRole: 'owner');
    final asker = server.add(
      'asker@example.com',
      name: 'Asker',
      clubRole: null,
    );
    ask(asker);
    server.clubMemberLimit = 1;
    server.clubPaidUntil = '2099-03-31';
    server.signInBrowser(owner);

    await openClub(tester);

    expect(find.byKey(const Key('club-plan-notice')), findsOneWidget);
    expect(find.textContaining('The club is full'), findsWidgets);
    expect(find.byKey(const Key('join-requests-blocked')), findsOneWidget);
    final approve = tester.widget<FilledButton>(
      find.byKey(const Key('approve-join-1')),
    );
    expect(approve.onPressed, isNull);
    final decline = tester.widget<TextButton>(
      find.byKey(const Key('decline-join-1')),
    );
    expect(decline.onPressed, isNotNull);
  });

  testWidgets('ClubScreen_ShouldSayThePlanEnded_WhenThePaidUntilDayHasPassed', (
    tester,
  ) async {
    widen(tester);
    final owner = server.add('owner@example.com', clubRole: 'owner');
    final asker = server.add('asker@example.com', clubRole: null);
    ask(asker);
    server.clubPaidUntil = '2020-01-31';
    server.signInBrowser(owner);

    await openClub(tester);

    expect(find.textContaining('plan ended on'), findsOneWidget);
    expect(find.text('Get in touch to renew it.'), findsNothing);
    expect(find.textContaining('Get in touch to renew it'), findsOneWidget);
    expect(find.byKey(const Key('join-requests-blocked')), findsOneWidget);
    final approve = tester.widget<FilledButton>(
      find.byKey(const Key('approve-join-1')),
    );
    expect(approve.onPressed, isNull);
    // Everyone is still in the club.
    expect(server.clubRoles, hasLength(1));
  });

  testWidgets('ClubScreen_ShouldAllowApprove_WhenThereIsRoom', (tester) async {
    widen(tester);
    final owner = server.add('owner@example.com', clubRole: 'owner');
    final asker = server.add('asker@example.com', clubRole: null);
    ask(asker);
    server.clubMemberLimit = 25;
    server.clubPaidUntil = '2099-03-31';
    server.signInBrowser(owner);

    await openClub(tester);

    final approve = tester.widget<FilledButton>(
      find.byKey(const Key('approve-join-1')),
    );
    expect(approve.onPressed, isNotNull);
    expect(find.byKey(const Key('join-requests-blocked')), findsNothing);
  });

  testWidgets('JoinClubScreen_ShouldShowWhyItFailed_WhenTheClubIsFull', (
    tester,
  ) async {
    widen(tester);
    server.add('owner@example.com', clubRole: 'owner');
    server.clubMemberLimit = 1;
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await openClub(tester);

    await tester.tap(find.byKey(const Key('go-join-club')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('join-code')), server.joinCode);
    await tester.tap(find.byKey(const Key('join-club')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('join-error')), findsOneWidget);
    expect(find.textContaining('full'), findsOneWidget);
    expect(find.text('Your account is already in a club.'), findsNothing);
    expect(server.clubRoles.containsKey(rider.email), isFalse);
  });

  testWidgets('ClubScreen_ShouldOfferStartAClub_WhenTheOperatorAllowsIt', (
    tester,
  ) async {
    widen(tester);
    server.adminSettings['clubCreationEnabled'] = true;
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);

    await openClub(tester);
    expect(find.byKey(const Key('go-start-club')), findsOneWidget);

    await tester.tap(find.byKey(const Key('go-start-club')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-club')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('start-club-name-error')), findsOneWidget);
    expect(server.clubRoles.containsKey(rider.email), isFalse);

    await tester.enterText(
      find.byKey(const Key('start-club-name')),
      'Friday Riders',
    );
    await tester.tap(find.byKey(const Key('start-club')));
    await tester.pumpAndSettle();

    expect(server.clubRoles[rider.email], 'owner');
    expect(server.clubName, 'Friday Riders');
    expect(find.text('Friday Riders'), findsOneWidget);
    expect(find.byKey(const Key('club-plan-card')), findsOneWidget);
    expect(find.text('1 of 25 members'), findsOneWidget);
    expect(find.byKey(const Key('go-start-club')), findsNothing);
  });

  testWidgets('ClubScreen_ShouldNotOfferStartAClub_WhenTheSettingIsOff', (
    tester,
  ) async {
    widen(tester);
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);

    await openClub(tester);

    expect(find.byKey(const Key('go-join-club')), findsOneWidget);
    expect(find.byKey(const Key('go-start-club')), findsNothing);
  });

  testWidgets('ClubsTab_ShouldRecordTheBand_WhenTheOperatorSavesAPlan', (
    tester,
  ) async {
    widen(tester);
    final admin = server.add(
      'admin@example.com',
      roles: ['admin', 'member'],
      name: 'Boss',
      clubRole: 'owner',
    );
    server.clubMemberLimit = 25;
    server.clubPaidUntil = '2099-03-31';
    server.signInBrowser(admin);
    await startApp(tester, server.session(useCookies: true));
    await openAccount(tester, 'admin');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab-clubs')));
    await tester.pumpAndSettle();

    expect(find.text('1 of 25 members'), findsOneWidget);
    expect(find.byKey(const Key('club-paid-until-club-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-plan-club-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('plan-limit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Up to 75 members').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('plan-clear-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-plan')));
    await tester.pumpAndSettle();

    expect(server.clubMemberLimit, 75);
    expect(server.clubPaidUntil, isNull);
    expect(server.lastPlanBody!['memberLimit'], 75);
    expect(find.text('1 of 75 members'), findsOneWidget);
    expect(find.byKey(const Key('club-paid-until-club-1')), findsNothing);
  });

  testWidgets('SettingsTab_ShouldSaveClubCreation_WhenSwitchedOn', (
    tester,
  ) async {
    widen(tester);
    final admin = server.add(
      'admin@example.com',
      roles: ['admin', 'member'],
      name: 'Boss',
    );
    server.signInBrowser(admin);
    await startApp(tester, server.session(useCookies: true));
    await openAccount(tester, 'admin');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab-settings')));
    await tester.pumpAndSettle();

    expect(server.adminSettings['clubCreationEnabled'], isFalse);
    await tester.ensureVisible(find.byKey(const Key('setting-club-creation')));
    await tester.tap(find.byKey(const Key('setting-club-creation')));
    await tester.ensureVisible(find.byKey(const Key('setting-save')));
    await tester.tap(find.byKey(const Key('setting-save')));
    await tester.pumpAndSettle();

    expect(server.adminSettings['clubCreationEnabled'], isTrue);
  });

  test('NotificationText_ShouldNameTheDay_WhenAPlanIsEndingInEachLanguage', () async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('it');
    NotificationResponse note(String type) => NotificationResponse(
      id: 'n1',
      type: type,
      subject: '2027-03-31',
      rideId: null,
      bikeId: null,
      componentId: null,
      aboutUserId: null,
      createdAt: DateTime.utc(2027, 3, 17),
      isRead: false,
    );

    Intl.defaultLocale = 'en';
    final en = lookupAppLocalizations(const Locale('en'));
    expect(
      notificationText(en, note('club_plan_ending')),
      "Your club's plan ends on ${DateFormat.yMMMd('en').format(DateTime.utc(2027, 3, 31))}. Get in touch to renew it.",
    );
    expect(
      notificationText(en, note('club_plan_ended')),
      contains('cannot join until it is renewed'),
    );
    expect(notificationTarget(note('club_plan_ending')), '/club');
    expect(notificationTarget(note('club_plan_ended')), '/club');

    Intl.defaultLocale = 'it';
    final it = lookupAppLocalizations(const Locale('it'));
    expect(
      notificationText(it, note('club_plan_ending')),
      startsWith('Il piano del tuo club scade il '),
    );
    expect(notificationText(it, note('club_plan_ending')), contains('2027'));
    Intl.defaultLocale = null;
  });
}
