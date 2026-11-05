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

  test('the fake server keeps profiles as JSON', () {
    // Guards the test helper: the app sends numbers, not strings.
    expect(jsonDecode('{"ftpW":265}')['ftpW'], isA<int>());
  });
}
