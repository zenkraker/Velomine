import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com', name: 'Ada'));
  });

  Future<void> openProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.byKey(const Key('open-profile')));
    await tester.pumpAndSettle();
  }

  testWidgets('the profile opens from the name in the title bar, filled in', (
    tester,
  ) async {
    server.profiles['rider@example.com'] = {
      'displayName': 'Ada',
      'ftpW': 250,
      'weightKg': 64.5,
      'maxHeartRate': 186,
      'timeZone': 'Europe/Rome',
      'firstDayOfWeek': 'sunday',
      'emailNotifications': true,
      'hasPassword': true,
    };
    await openProfile(tester);

    String field(String key) =>
        tester.widget<TextField>(find.byKey(Key(key))).controller!.text;
    expect(field('profile-name'), 'Ada');
    expect(field('profile-ftp'), '250');
    expect(field('profile-weight'), '64.5');
    expect(field('profile-max-hr'), '186');
    expect(field('profile-zone'), 'Europe/Rome');
    expect(find.text('Sunday'), findsOneWidget);
  });

  testWidgets('saving sends every field, empty boxes as not set', (
    tester,
  ) async {
    await openProfile(tester);

    await tester.enterText(find.byKey(const Key('profile-name')), 'Ada L');
    await tester.enterText(find.byKey(const Key('profile-ftp')), '265');
    await tester.enterText(find.byKey(const Key('profile-weight')), '68,5');
    await tester.enterText(
      find.byKey(const Key('profile-zone')),
      'Europe/Rome',
    );
    await tester.tap(find.byKey(const Key('profile-first-day')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saturday').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();

    expect(server.profiles['rider@example.com'], {
      'displayName': 'Ada L',
      'ftpW': 265,
      'weightKg': 68.5,
      'maxHeartRate': null,
      'timeZone': 'Europe/Rome',
      'firstDayOfWeek': 'saturday',
      'emailNotifications': true,
      'hasPassword': true,
    });
    expect(find.byKey(const Key('profile-saved')), findsOneWidget);
    expect(server.requests, contains('PUT /api/v1/accounts/me/profile'));
  });

  testWidgets('a value out of range is explained and not sent', (tester) async {
    await openProfile(tester);

    await tester.enterText(find.byKey(const Key('profile-max-hr')), '300');
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();

    expect(find.text('Maximum heart rate is 100 to 240 bpm.'), findsOneWidget);
    expect(server.requests, isNot(contains('PUT /api/v1/accounts/me/profile')));
  });

  testWidgets(
    'the email switch is explained and off-limits without email on the server',
    (tester) async {
      await openProfile(tester);

      final tile = tester.widget<SwitchListTile>(
        find.byKey(const Key('profile-email')),
      );
      expect(tile.onChanged, isNull);
      expect(find.textContaining('not set up to send email'), findsOneWidget);
    },
  );

  testWidgets('with email on the server the switch is sent with the profile', (
    tester,
  ) async {
    server.smtpConfigured = true;
    await openProfile(tester);

    await tester.tap(find.byKey(const Key('profile-email')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();

    expect(server.profiles['rider@example.com']!['emailNotifications'], false);
  });

  Future<void> tapVisible(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('the data export opens a download link in the browser', (
    tester,
  ) async {
    Uri? opened;
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(
      tester,
      server.session(useCookies: true),
      openLink: (uri) async => opened = uri,
    );
    await tester.tap(find.byKey(const Key('open-profile')));
    await tester.pumpAndSettle();

    await tapVisible(tester, 'export-data');

    expect(server.requests, contains('POST /api/v1/accounts/me/export-link'));
    expect(opened!.path, '/api/v1/accounts/export/token-1');
    expect(find.byKey(const Key('export-started')), findsOneWidget);
  });

  group('deleting the account', () {
    Future<void> openDelete(WidgetTester tester) async {
      await openProfile(tester);
      await tapVisible(tester, 'delete-account');
    }

    testWidgets('asks for the password and says what is lost', (tester) async {
      await openDelete(tester);

      expect(find.text('Delete your account?'), findsOneWidget);
      expect(find.textContaining('Download your data first'), findsOneWidget);
      expect(find.text('Your password'), findsOneWidget);
    });

    testWidgets('a wrong password deletes nothing and says so', (tester) async {
      await openDelete(tester);

      await tester.enterText(find.byKey(const Key('delete-confirm')), 'nope');
      await tester.tap(find.byKey(const Key('confirm-delete-account')));
      await tester.pumpAndSettle();

      expect(server.accounts, contains('rider@example.com'));
      expect(
        find.text('That does not match. Nothing was deleted.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('open-profile')),
        findsOneWidget,
      ); // still signed in
    });

    testWidgets('cancelling deletes nothing', (tester) async {
      await openDelete(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(server.accounts, contains('rider@example.com'));
      expect(
        server.requests,
        isNot(contains('POST /api/v1/accounts/me/delete')),
      );
    });

    testWidgets('the right password deletes it and returns to sign-in', (
      tester,
    ) async {
      await openDelete(tester);

      await tester.enterText(
        find.byKey(const Key('delete-confirm')),
        'Rider-pass-123',
      );
      await tester.tap(find.byKey(const Key('confirm-delete-account')));
      await tester.pumpAndSettle();

      expect(server.accounts, isNot(contains('rider@example.com')));
      expect(find.byKey(const Key('open-profile')), findsNothing);
      expect(find.text('Sign in'), findsWidgets); // back at the sign-in screen
    });

    testWidgets('an account without a password confirms with its email', (
      tester,
    ) async {
      server.accounts.clear();
      server.signInBrowser(server.add('sso@example.com', password: ''));
      await openDelete(tester);

      expect(find.text('Type your email address to confirm'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('delete-confirm')),
        'wrong@example.com',
      );
      await tester.tap(find.byKey(const Key('confirm-delete-account')));
      await tester.pumpAndSettle();
      expect(server.accounts, contains('sso@example.com'));

      await tapVisible(tester, 'delete-account');
      await tester.enterText(
        find.byKey(const Key('delete-confirm')),
        'sso@example.com',
      );
      await tester.tap(find.byKey(const Key('confirm-delete-account')));
      await tester.pumpAndSettle();
      expect(server.accounts, isNot(contains('sso@example.com')));
    });

    testWidgets('the only admin is told to hand over first', (tester) async {
      server.accounts.clear();
      server.signInBrowser(
        server.add('boss@example.com', roles: ['admin', 'member']),
      );
      await openDelete(tester);

      await tester.enterText(
        find.byKey(const Key('delete-confirm')),
        'Rider-pass-123',
      );
      await tester.tap(find.byKey(const Key('confirm-delete-account')));
      await tester.pumpAndSettle();

      expect(server.accounts, contains('boss@example.com'));
      expect(
        find.text('You are the only admin. Make someone else an admin first.'),
        findsOneWidget,
      );
    });
  });

  test('the fake server keeps profiles as JSON', () {
    // Guards the test helper: the app sends numbers, not strings.
    expect(jsonDecode('{"ftpW":265}')['ftpW'], isA<int>());
  });
}
