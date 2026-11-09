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

  testWidgets('ProfileScreen_ShouldShowFilledFields_WhenOpenedFromTitleBar', (
    tester,
  ) async {
    server.profiles['rider@example.com'] = {
      'displayName': 'Ada',
      'ftpW': 250,
      'weightKg': 64.5,
      'birthYear': 1990,
      'timeZone': 'Europe/Rome',
      'firstDayOfWeek': 'sunday',
      'emailNotifications': true,
      'emailAccountNotifications': true,
      'emailTrainingNotifications': false,
      'hasPassword': true,
    };
    await openProfile(tester);

    String field(String key) =>
        tester.widget<TextField>(find.byKey(Key(key))).controller!.text;
    expect(field('profile-name'), 'Ada');
    expect(field('profile-ftp'), '250');
    expect(field('profile-weight'), '64.5');
    expect(field('profile-birth-year'), '1990');
    expect(find.textContaining('Estimated maximum heart rate'), findsOneWidget);
    expect(field('profile-zone'), 'Europe/Rome');
    expect(find.text('Sunday'), findsOneWidget);
  });

  testWidgets('ProfileScreen_ShouldSaveTelemetryChoice_WhenSwitched', (
    tester,
  ) async {
    server.telemetryEnabled = true;
    server.sentryDsn = 'https://key@example.invalid/1';
    await openProfile(tester);

    expect(find.byKey(const Key('telemetry-crash')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('telemetry-crash')));
    await tester.tap(find.byKey(const Key('telemetry-crash')));
    await tester.pumpAndSettle();

    expect(server.requests, contains('PUT /api/v1/accounts/me/telemetry'));
    expect(server.accounts['rider@example.com']!.telemetryCrash, isTrue);
    expect(find.byKey(const Key('telemetry-saved')), findsOneWidget);
  });

  testWidgets(
    'ProfileScreen_ShouldExplainTelemetryUnavailable_WhenServerHasNoDsn',
    (tester) async {
      await openProfile(tester);

      expect(
        find.text('This server does not collect telemetry.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('telemetry-crash')), findsNothing);
    },
  );

  testWidgets('ProfileScreen_ShouldSendEveryField_WhenSomeAreEmpty', (
    tester,
  ) async {
    await openProfile(tester);

    await tester.enterText(find.byKey(const Key('profile-name')), 'Ada L');
    await tester.enterText(find.byKey(const Key('profile-ftp')), '265');
    await tester.enterText(find.byKey(const Key('profile-weight')), '68,5');
    await tester.enterText(find.byKey(const Key('profile-birth-year')), '1985');
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
      'birthYear': 1985,
      'timeZone': 'Europe/Rome',
      'firstDayOfWeek': 'saturday',
      'emailNotifications': true,
      'emailAccountNotifications': true,
      'emailTrainingNotifications': false,
      'hasPassword': true,
    });
    expect(find.byKey(const Key('profile-saved')), findsOneWidget);
    expect(server.requests, contains('PUT /api/v1/accounts/me/profile'));
  });

  testWidgets('ProfileScreen_ShouldRejectOutOfRangeValue_WhenSaving', (
    tester,
  ) async {
    await openProfile(tester);

    await tester.enterText(find.byKey(const Key('profile-birth-year')), '1800');
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter a year of birth between 1900 and ten years ago.'),
      findsOneWidget,
    );
    expect(server.requests, isNot(contains('PUT /api/v1/accounts/me/profile')));
  });

  testWidgets(
    'ProfileScreen_ShouldDisableEmailSwitchAndExplain_WhenServerHasNoEmail',
    (tester) async {
      await openProfile(tester);

      final tile = tester.widget<SwitchListTile>(
        find.byKey(const Key('profile-email')),
      );
      expect(tile.onChanged, isNull);
      expect(find.textContaining('not set up to send email'), findsOneWidget);
    },
  );

  testWidgets('ProfileScreen_ShouldSendEmailSwitch_WhenServerHasEmail', (
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

  testWidgets('ProfileScreen_ShouldSendEmailCategories_WhenChanged', (
    tester,
  ) async {
    server.smtpConfigured = true;
    await openProfile(tester);

    await tester.ensureVisible(find.byKey(const Key('profile-email-training')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-email-training')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();

    expect(
      server.profiles['rider@example.com']!['emailTrainingNotifications'],
      true,
    );
    expect(
      server.profiles['rider@example.com']!['emailAccountNotifications'],
      true,
    );
  });

  Future<void> tapVisible(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('ProfileScreen_ShouldOpenDownloadLink_WhenExportingData', (
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

  testWidgets('ProfileScreen_ShouldSignOut_WhenThePasswordIsChanged', (
    tester,
  ) async {
    await openProfile(tester);

    await tapVisible(tester, 'change-password');
    await tester.enterText(
      find.byKey(const Key('current-password')),
      'Rider-pass-123',
    );
    await tester.enterText(
      find.byKey(const Key('new-password')),
      'New-password-1',
    );
    await tester.enterText(
      find.byKey(const Key('confirm-password')),
      'New-password-1',
    );
    await tester.tap(find.byKey(const Key('confirm-change-password')));
    await tester.pumpAndSettle();

    expect(server.accounts['rider@example.com']!.password, 'New-password-1');
    expect(find.byKey(const Key('sign-in')), findsOneWidget);
  });

  group('deleting the account', () {
    Future<void> openDelete(WidgetTester tester) async {
      await openProfile(tester);
      await tapVisible(tester, 'delete-account');
    }

    testWidgets('DeleteAccountDialog_ShouldAskPasswordAndWarn_WhenOpened', (
      tester,
    ) async {
      await openDelete(tester);

      expect(find.text('Delete your account?'), findsOneWidget);
      expect(find.textContaining('Download your data first'), findsOneWidget);
      expect(find.text('Your password'), findsOneWidget);
    });

    testWidgets('DeleteAccountDialog_ShouldDeleteNothing_WhenPasswordIsWrong', (
      tester,
    ) async {
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

    testWidgets('DeleteAccountDialog_ShouldDeleteNothing_WhenCancelled', (
      tester,
    ) async {
      await openDelete(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(server.accounts, contains('rider@example.com'));
      expect(
        server.requests,
        isNot(contains('POST /api/v1/accounts/me/delete')),
      );
    });

    testWidgets('DeleteAccountDialog_ShouldDeleteAccount_WhenPasswordIsRight', (
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

    testWidgets('DeleteAccountDialog_ShouldConfirmWithEmail_WhenNoPassword', (
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

      // Let the "does not match" message go away before reaching for the button behind it.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tapVisible(tester, 'delete-account');
      await tester.enterText(
        find.byKey(const Key('delete-confirm')),
        'sso@example.com',
      );
      await tester.tap(find.byKey(const Key('confirm-delete-account')));
      await tester.pumpAndSettle();
      expect(server.accounts, isNot(contains('sso@example.com')));
    });

    testWidgets('DeleteAccountDialog_ShouldRefuseDeletion_WhenOnlyAdmin', (
      tester,
    ) async {
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

  test('FakeServer_ShouldKeepNumbersAsIntegers_WhenDecodingProfileJson', () {
    // Guards the test helper: the app sends numbers, not strings.
    expect(jsonDecode('{"ftpW":265}')['ftpW'], isA<int>());
  });
}
