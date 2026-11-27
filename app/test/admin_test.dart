import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/failure.dart';
import 'package:velomine/core/providers.dart';
import 'package:velomine/core/result.dart';
import 'package:velomine/core/session.dart';
import 'package:velomine/core/widgets/badge.dart';
import 'package:velomine/core/widgets/empty_state.dart';
import 'package:velomine/core/widgets/error_state.dart';
import 'package:velomine/core/saved_mark_view_model.dart';
import 'package:velomine/core/widgets/section_card.dart';
import 'package:velomine/features/admin/admin_data.dart';
import 'package:velomine/features/admin/admin_view_models.dart';
import 'package:velomine/features/admin/settings_tab.dart';
import 'package:velomine_api/api.dart';

import 'fake_server.dart';

/// A data source whose two loads fail, so the tabs can show their error state.
class _FailingAdminData extends AdminData {
  _FailingAdminData(Session session) : super(session.admin, session.accounts);

  int overviewCalls = 0;
  int settingsCalls = 0;

  @override
  Future<Result<OverviewResponse?>> overview() async {
    overviewCalls++;
    return const Failed(
      Failure(FailureKind.unreachable, action: FailureAction.loadAdmin),
    );
  }

  @override
  Future<Result<AdminSettingsBundle>> settings() async {
    settingsCalls++;
    return const Failed(
      Failure(FailureKind.unreachable, action: FailureAction.loadAdmin),
    );
  }
}

void main() {
  late FakeServer server;
  late FakeAccount admin;
  setUp(() {
    server = FakeServer();
    admin = server.add(
      'admin@example.com',
      roles: ['admin', 'member'],
      name: 'Boss',
    );
    server.signInBrowser(admin);
  });

  Future<void> openAdmin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await openAccount(tester, 'admin');
    await tester.pumpAndSettle();
    // Admin opens on the overview; most of these tests are about the accounts.
    await tester.tap(find.byKey(const Key('tab-accounts')));
    await tester.pumpAndSettle();
  }

  Future<void> menu(WidgetTester tester, FakeAccount a, String item) async {
    await tester.tap(find.byKey(Key('user-menu-${a.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('$item-${a.id}')));
    await tester.pumpAndSettle();
  }

  testWidgets('AccountsTab_ShouldShowOnlyMatchingAccounts_WhenSearched', (
    tester,
  ) async {
    final ada = server.add('ada@example.com', name: 'Ada');
    final bob = server.add('bob@example.com', name: 'Bob');
    await openAdmin(tester);
    await tester.tap(find.byKey(const Key('tab-accounts')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('account-search')), 'ada');
    await tester.pumpAndSettle();

    expect(find.byKey(Key('user-${ada.id}')), findsOneWidget);
    expect(find.byKey(Key('user-${bob.id}')), findsNothing);
  });

  testWidgets('AccountsTab_ShouldApproveWaitingAccount_WhenApproved', (
    tester,
  ) async {
    final waiting = server.add(
      'new@example.com',
      approved: false,
      name: 'Newcomer',
    );
    await openAdmin(tester);
    expect(find.text('Newcomer'), findsOneWidget);
    expect(find.byKey(const Key('none-pending')), findsNothing);

    await tester.tap(find.byKey(Key('approve-${waiting.id}')));
    await tester.pumpAndSettle();

    expect(waiting.approved, isTrue);
    expect(find.text('Newcomer'), findsOneWidget); // now among the accounts
    expect(find.byKey(const Key('none-pending')), findsOneWidget);
    expect(find.byKey(Key('approve-${waiting.id}')), findsNothing);
  });

  testWidgets('AccountsTab_ShouldListAccountsWithoutOwnActions_WhenOpened', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', name: 'Rider');
    await openAdmin(tester);

    expect(find.text('Admin'), findsWidgets);
    expect(find.text('You'), findsOneWidget);
    expect(find.byKey(Key('user-menu-${admin.id}')), findsNothing);
    expect(find.byKey(Key('user-menu-${rider.id}')), findsOneWidget);
  });

  testWidgets('AccountsTab_ShouldChangeRolesAndKeepMember_WhenSaved', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', name: 'Rider');
    await openAdmin(tester);

    await menu(tester, rider, 'roles');
    await tester.tap(find.byKey(const Key('role-coach')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('roles-save')));
    await tester.pumpAndSettle();

    expect(rider.roles, containsAll(['member', 'coach']));
    expect(find.text('Coach'), findsOneWidget);
  });

  testWidgets('AccountsTab_ShouldShowOneTimeResetLink_WhenAnAdminAsks', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', name: 'Rider');
    await openAdmin(tester);

    await menu(tester, rider, 'reset-password');

    expect(find.byKey(const Key('reset-link')), findsOneWidget);
    expect(find.textContaining('token=good'), findsOneWidget);
    expect(find.textContaining('30 minutes'), findsOneWidget);
  });

  testWidgets('AccountsTab_ShouldLockAndUnlock_WhenUsed', (tester) async {
    final rider = server.add('rider@example.com', name: 'Rider');
    await openAdmin(tester);

    await menu(tester, rider, 'lock');
    expect(rider.locked, isTrue);
    expect(find.text('Locked'), findsOneWidget);

    await menu(tester, rider, 'unlock');
    expect(rider.locked, isFalse);
    expect(find.text('Locked'), findsNothing);
  });

  testWidgets('AccountsTab_ShouldConfirmBeforeDeleting_WhenDeleteIsPicked', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', name: 'Rider');
    await openAdmin(tester);

    await menu(tester, rider, 'delete');
    expect(find.text('Delete Rider?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(server.accounts, contains('rider@example.com'));

    await menu(tester, rider, 'delete');
    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();

    expect(server.accounts, isNot(contains('rider@example.com')));
    expect(find.text('Rider'), findsNothing);
  });

  testWidgets('AccountsTab_ShouldListDeleteLastAndInRed_WhenRowMenuOpens', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', name: 'Rider');
    await openAdmin(tester);

    await tester.tap(find.byKey(Key('user-menu-${rider.id}')));
    await tester.pumpAndSettle();

    final delete = find.byKey(Key('delete-${rider.id}'));
    final others = [
      for (final k in ['roles', 'lock', 'reset-password', 'reset-two-factor'])
        tester.getTopLeft(find.byKey(Key('$k-${rider.id}'))).dy,
    ];
    expect(
      tester.getTopLeft(delete).dy,
      greaterThan(others.reduce((a, b) => a > b ? a : b)),
    );
    final style = tester.widget<MenuItemButton>(delete).style!;
    expect(
      style.foregroundColor!.resolve({}),
      Theme.of(tester.element(delete)).colorScheme.error,
    );

    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(find.text('Delete Rider?'), findsOneWidget);
    expect(server.accounts, contains('rider@example.com'));
  });

  testWidgets('ClubsTab_ShouldOpenCreateClubAsSheet_WhenTapped', (
    tester,
  ) async {
    await openAdmin(tester);
    await tester.tap(find.byKey(const Key('tab-clubs')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create-club')));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byKey(const Key('save-club')), findsOneWidget);
  });

  bool savedMarkVisible(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(SettingsTab)))
          .read(savedMarkViewModelProvider);

  testWidgets('SettingsTab_ShouldSaveAndShowTheMark_WhenASwitchChanges', (
    tester,
  ) async {
    await openAdmin(tester);
    await tester.tap(find.byKey(const Key('tab-settings')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('setting-approval')));
    await tester.pumpAndSettle();

    expect(server.adminSettings, {
      'signUpEnabled': true,
      'requireAdminApproval': false,
      'clubCreationEnabled': false,
    });
    expect(savedMarkVisible(tester), isTrue);
    await tester.pump(const Duration(seconds: 3));
    expect(savedMarkVisible(tester), isFalse);
  });

  test('SettingsTab_ShouldNotSend_WhenSwitchIsAlreadyItsSavedValue', () async {
    final session = server.session(useCookies: true);
    await session.restore();
    final container = ProviderContainer(
      overrides: [sessionProvider.overrideWith((ref) => session)],
    );
    addTearDown(container.dispose);
    container.listen(adminSettingsViewModelProvider, (_, _) {});
    await pumpEventQueue();
    final notifier = container.read(adminSettingsViewModelProvider.notifier);

    expect(await notifier.setSignUpEnabled(true), isFalse);
    expect(server.requests, isNot(contains('PUT /api/v1/admin/settings')));
  });

  testWidgets('SettingsTab_ShouldHideTheMark_WhenTheSaveFails', (tester) async {
    await openAdmin(tester);
    await tester.tap(find.byKey(const Key('tab-settings')));
    await tester.pumpAndSettle();
    server.failing.add('/api/v1/admin/settings');

    await tester.tap(find.byKey(const Key('setting-approval')));
    await tester.pumpAndSettle();

    expect(savedMarkVisible(tester), isFalse);
    // The switch goes back to the value the server holds, under the error.
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('setting-approval')))
          .value,
      isTrue,
    );
  });

  testWidgets('SettingsTab_ShouldShowSsoReadOnly_WhenOpened', (tester) async {
    server.smtpConfigured = true;
    await openAdmin(tester);
    await tester.tap(find.byKey(const Key('tab-settings')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('sso-status')),
      200,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('Email (SMTP)'), findsOneWidget);
    expect(
      find.text(
        'smtp.club.example:587 · starttls · from velomine@club.example',
      ),
      findsOneWidget,
    );
    expect(find.text('Single sign-on'), findsOneWidget);
    expect(
      find.textContaining('Not set up. Set VELOMINE__SSO__AUTHORITY'),
      findsOneWidget,
    );
    // Nothing to edit: no field for a password, user name, client id, secret or map.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('SettingsTab_ShouldSendTestEmailAndShowOutcome_WhenTapped', (
    tester,
  ) async {
    server.smtpConfigured = true;
    await openAdmin(tester);
    await tester.tap(find.byKey(const Key('tab-settings')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('send-test-email')),
      200,
      scrollable: find.byType(Scrollable).last,
    );

    await tester.tap(find.byKey(const Key('send-test-email')));
    await tester.pumpAndSettle();
    expect(server.testEmails, ['admin@example.com']);
    expect(find.text('Test email sent to your own address.'), findsOneWidget);

    server.testEmailStatus = 502;
    await tester.tap(find.byKey(const Key('send-test-email')));
    await tester.pumpAndSettle();
    expect(
      find.text('The mail server did not accept it. Check the email settings.'),
      findsOneWidget,
    );
  });

  testWidgets('SettingsTab_ShouldHideTestEmail_WhenNoEmail', (tester) async {
    await openAdmin(tester);
    await tester.tap(find.byKey(const Key('tab-settings')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('sso-status')),
      200,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.byKey(const Key('send-test-email')), findsNothing);
    expect(
      find.text(
        'Not set up. Set VELOMINE__SMTP__HOST and VELOMINE__SMTP__FROM.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('OverviewTab_ShouldShowTotals_WhenOpened', (tester) async {
    server.add('rider@example.com', approved: false);
    await openAdmin(tester);
    await tester.tap(find.byKey(const Key('tab-overview')));
    await tester.pumpAndSettle();

    String value(String key) =>
        (tester.widget<ListTile>(find.byKey(Key(key))).trailing! as Text).data!;
    expect(value('overview-accounts'), '2');
    expect(value('overview-waiting'), '1');
    expect(value('overview-storage'), '1.2 MB');
    expect(value('overview-version'), '0.1.0');
    expect(value('overview-parser-version'), '3');
    expect(value('overview-reread'), '12');
    expect(value('overview-not-reread'), '2');
  });

  testWidgets('AdminScreen_ShouldRefuse_WhenTheRiderIsNotAnAdmin', (
    tester,
  ) async {
    server.signInBrowser(server.add('rider@example.com'));
    await startApp(tester, server.session(useCookies: true));

    await goTo(tester, '/admin');

    expect(find.byKey(const Key('tab-overview')), findsNothing);
    expect(find.byKey(const Key('rides-actions')), findsOneWidget);
  });

  testWidgets('AdminScreen_ShouldBeHidden_WhenNotAdmin', (tester) async {
    server.signInBrowser(server.add('rider@example.com'));
    await startApp(tester, server.session(useCookies: true));

    await openAccountMenu(tester);
    expect(find.byKey(const Key('account-admin')), findsNothing);
  });

  testWidgets('AdminScreen_ShouldKeepTheFourTabs_WhenOpenedByAnAdmin', (
    tester,
  ) async {
    await openAdmin(tester);

    for (final key in ['overview', 'accounts', 'clubs', 'settings']) {
      expect(find.byKey(Key('tab-$key')), findsOneWidget);
    }

    await tester.tap(find.byKey(const Key('tab-overview')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('overview-accounts')), findsOneWidget);
  });

  testWidgets('AccountsTab_ShouldTitleItsLists_WhenOpened', (tester) async {
    await openAdmin(tester);

    expect(
      find.widgetWithText(SectionCard, 'Waiting for approval'),
      findsOneWidget,
    );
    expect(find.widgetWithText(SectionCard, 'Accounts'), findsOneWidget);
  });

  testWidgets('AccountsTab_ShouldShowAnEmptyState_WhenNobodyIsWaiting', (
    tester,
  ) async {
    await openAdmin(tester);

    expect(
      tester.widget(find.byKey(const Key('none-pending'))),
      isA<EmptyState>(),
    );
  });

  testWidgets('ClubsTab_ShouldShowAStateBadge_WhenTheClubIsRunning', (
    tester,
  ) async {
    await openAdmin(tester);
    await tester.tap(find.byKey(const Key('tab-clubs')));
    await tester.pumpAndSettle();

    final badge = tester.widget<AppBadge>(
      find.byKey(const Key('club-state-club-1')),
    );
    expect(badge.label, 'Active');
    expect(badge.tone, AppBadgeTone.good);
    expect(find.byType(SwitchListTile), findsNothing);
  });

  testWidgets('ClubsTab_ShouldShowPlanEnded_WhenThePlanHasEnded', (
    tester,
  ) async {
    server.clubPaidUntil = '2026-11-01';
    await openAdmin(tester);
    await tester.tap(find.byKey(const Key('tab-clubs')));
    await tester.pumpAndSettle();

    final badge = tester.widget<AppBadge>(
      find.byKey(const Key('club-state-club-1')),
    );
    expect(badge.label, 'Plan ended');
    expect(badge.tone, AppBadgeTone.care);
  });

  testWidgets('ClubsTab_ShouldAskBeforeTurningTheClubOff_WhenChosen', (
    tester,
  ) async {
    await openAdmin(tester);
    await tester.tap(find.byKey(const Key('tab-clubs')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('club-menu-club-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('club-active-club-1')));
    await tester.pumpAndSettle();
    expect(find.text('Deactivate club'), findsWidgets);
    expect(server.clubActive, isTrue);

    await tester.tap(find.byKey(const Key('confirm-club-active-club-1')));
    await tester.pumpAndSettle();
    expect(server.clubActive, isFalse);
    expect(
      tester.widget<AppBadge>(find.byKey(const Key('club-state-club-1'))).label,
      'Inactive',
    );
  });

  testWidgets('OverviewTab_ShouldTitleItsTwoCards_WhenOpened', (tester) async {
    await openAdmin(tester);
    await tester.tap(find.byKey(const Key('tab-overview')));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(SectionCard, 'People and rides'),
      findsOneWidget,
    );
    expect(find.widgetWithText(SectionCard, 'Server'), findsOneWidget);
  });

  testWidgets('OverviewTab_ShouldOfferARetry_WhenTheLoadFails', (tester) async {
    final session = server.session(useCookies: true);
    final data = _FailingAdminData(session);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(
      tester,
      session,
      overrides: [adminDataProvider.overrideWithValue(data)],
    );
    await openAccount(tester, 'admin');
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(data.overviewCalls, 1);

    await tester.tap(find.byKey(const Key('overview-retry')));
    await tester.pumpAndSettle();
    expect(data.overviewCalls, 2);
  });

  testWidgets('SettingsTab_ShouldTitleItsCards_WhenOpened', (tester) async {
    await openAdmin(tester);
    await tester.tap(find.byKey(const Key('tab-settings')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(SectionCard, 'Sign-up'), findsOneWidget);
    expect(
      find.widgetWithText(SectionCard, 'Set with environment variables'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(SectionCard, 'Shared parts catalogue'),
      findsOneWidget,
    );
  });

  testWidgets('SettingsTab_ShouldOfferARetry_WhenTheLoadFails', (tester) async {
    final session = server.session(useCookies: true);
    final data = _FailingAdminData(session);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(
      tester,
      session,
      overrides: [adminDataProvider.overrideWithValue(data)],
    );
    await openAccount(tester, 'admin');
    await tester.tap(find.byKey(const Key('tab-settings')));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(data.settingsCalls, 1);

    await tester.tap(find.byKey(const Key('settings-retry')));
    await tester.pumpAndSettle();
    expect(data.settingsCalls, 2);
  });

  testWidgets('AdminScreen_ShouldShowTheFourAreasAsChips_WhenOpened', (
    tester,
  ) async {
    await openAdmin(tester);

    // The admin pages draw their areas as chips in a row (`.vm-chips`), not a segmented track.
    final tabs = find.byKey(const Key('admin-tabs'));
    expect(tabs, findsOneWidget);
    expect(
      find.descendant(of: tabs, matching: find.byType(ChoiceChip)),
      findsNWidgets(4),
    );
    expect(find.byType(SegmentedButton<int>), findsNothing);
  });

  testWidgets('AccountsTab_ShouldSayMember_WhenTheAccountHasNoOtherRole', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', name: 'Rider');
    await openAdmin(tester);

    expect(
      find.descendant(
        of: find.byKey(Key('user-${rider.id}')),
        matching: find.text('Member'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('AccountsTab_ShouldOfferTheRowMenu_WhenTheAccountIsWaiting', (
    tester,
  ) async {
    final waiting = server.add(
      'new@example.com',
      approved: false,
      name: 'Newcomer',
    );
    await openAdmin(tester);

    expect(find.byKey(Key('approve-${waiting.id}')), findsOneWidget);
    expect(find.byKey(Key('user-menu-${waiting.id}')), findsOneWidget);
  });

  testWidgets('AccountsTab_ShouldSayHowLongAgo_WhenTheAccountIsWaiting', (
    tester,
  ) async {
    final waiting = server.add(
      'new@example.com',
      approved: false,
      name: 'Newcomer',
    );
    await openAdmin(tester);

    String subtitle(String id) {
      final tile = tester.widget<ListTile>(find.byKey(Key('user-$id')));
      return (tile.subtitle! as Text).data!;
    }

    // A waiting account says when it asked (hours, days, then the day alone); an approved one shows
    // the moment itself. Neither is a clock time on the waiting row, whichever way its age falls.
    expect(subtitle(waiting.id), contains('new@example.com'));
    expect(subtitle(waiting.id), isNot(contains(':')));
    expect(subtitle(admin.id), contains(':'));
  });

  testWidgets('ClubsTab_ShouldShowOneCaption_WhenTheClubIsListed', (
    tester,
  ) async {
    server.clubPaidUntil = '2099-03-31';
    await openAdmin(tester);
    await tester.tap(find.byKey(const Key('tab-clubs')));
    await tester.pumpAndSettle();

    // Members and the plan share one caption line instead of four stacked lines, and the owner's
    // address is not on the page.
    final members = tester.getTopLeft(
      find.byKey(const Key('club-members-club-1')),
    );
    final paid = tester.getTopLeft(
      find.byKey(const Key('club-paid-until-club-1')),
    );
    expect(paid.dy, members.dy);
    expect(paid.dx, greaterThan(members.dx));
    expect(find.textContaining('@'), findsNothing);
  });

  for (final width in [390.0, 1300.0]) {
    testWidgets('AdminScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}', (
      tester,
    ) async {
      server.clubRoles['admin@example.com'] = 'owner';
      server.clubMemberLimit = 25;
      server.clubPaidUntil = '2026-11-01';
      server.add('waiting@example.com', approved: false, name: 'Waiting Rina');
      tester.view.physicalSize = Size(width, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));
      await openAccount(tester, 'admin');
      await tester.pumpAndSettle();

      for (final tab in ['overview', 'accounts', 'clubs', 'settings']) {
        final chip = find.byKey(Key('tab-$tab'));
        // The chips scroll sideways: on a phone the last one starts off-screen.
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        await tester.tap(chip);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
