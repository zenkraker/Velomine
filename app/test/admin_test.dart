import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

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
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();
  }

  Future<void> menu(WidgetTester tester, FakeAccount a, String item) async {
    await tester.tap(find.byKey(Key('user-menu-${a.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('$item-${a.id}')));
    await tester.pumpAndSettle();
  }

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

  testWidgets(
    'AccountsTab_ShouldAskBeforeDeletingAndKeepAccount_WhenCancelled',
    (tester) async {
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
    },
  );

  testWidgets('SettingsTab_ShouldSaveSettings_WhenSaved', (tester) async {
    await openAdmin(tester);
    await tester.tap(find.byKey(const Key('tab-settings')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('setting-approval')));
    await tester.ensureVisible(find.byKey(const Key('setting-save')));
    await tester.tap(find.byKey(const Key('setting-save')));
    await tester.pumpAndSettle();

    expect(server.adminSettings, {
      'signUpEnabled': true,
      'requireAdminApproval': false,
    });
    expect(find.byKey(const Key('settings-saved')), findsOneWidget);
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

    expect(find.text('Email (SMTP): on'), findsOneWidget);
    expect(
      find.text(
        'smtp.club.example:587 · starttls · from velomine@club.example',
      ),
      findsOneWidget,
    );
    expect(find.text('Single sign-on: off'), findsOneWidget);
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
    expect(find.text('Email (SMTP): off'), findsOneWidget);
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
  });

  testWidgets('AdminScreen_ShouldBeHidden_WhenNotAdmin', (tester) async {
    server.signInBrowser(server.add('rider@example.com'));
    await startApp(tester, server.session(useCookies: true));

    expect(find.text('Admin'), findsNothing);
    expect(find.text('Bikes'), findsOneWidget);
  });
}
