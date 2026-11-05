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

  testWidgets('an admin sees the accounts waiting and approves one', (
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

  testWidgets('every account is listed, and your own has no actions', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', name: 'Rider');
    await openAdmin(tester);

    expect(find.text('Admin'), findsWidgets);
    expect(find.text('You'), findsOneWidget);
    expect(find.byKey(Key('user-menu-${admin.id}')), findsNothing);
    expect(find.byKey(Key('user-menu-${rider.id}')), findsOneWidget);
  });

  testWidgets('roles are changed from a dialog, and member stays', (
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

  testWidgets('an account is locked and unlocked', (tester) async {
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
    'deleting an account asks first, and cancelling deletes nothing',
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

  testWidgets('settings show what is in effect and are saved', (tester) async {
    await openAdmin(tester);
    await tester.tap(find.byKey(const Key('tab-settings')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('setting-approval')));
    await tester.enterText(
      find.byKey(const Key('setting-tile')),
      'https://tiles.example/{z}/{x}/{y}.png',
    );
    await tester.enterText(
      find.byKey(const Key('setting-credit')),
      '© Example',
    );
    await tester.ensureVisible(find.byKey(const Key('setting-save')));
    await tester.tap(find.byKey(const Key('setting-save')));
    await tester.pumpAndSettle();

    expect(server.adminSettings, {
      'signUpEnabled': true,
      'requireAdminApproval': false,
      'mapTileUrl': 'https://tiles.example/{z}/{x}/{y}.png',
      'mapAttribution': '© Example',
    });
    expect(find.byKey(const Key('settings-saved')), findsOneWidget);
  });

  testWidgets('email and single sign-on are shown read-only', (tester) async {
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
    // Nothing to edit: no field for a password, user name, client id or secret.
    expect(
      find.byType(TextField),
      findsNWidgets(2),
    ); // tile address and credit only
  });

  testWidgets('a test email goes to the admin, and the outcome is shown', (
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

  testWidgets('without email set up there is no test button', (tester) async {
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

  testWidgets('the overview shows server totals', (tester) async {
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

  testWidgets('a member has no admin screen', (tester) async {
    server.signInBrowser(server.add('rider@example.com'));
    await startApp(tester, server.session(useCookies: true));

    expect(find.text('Admin'), findsNothing);
    expect(find.text('Bikes'), findsOneWidget);
  });
}
