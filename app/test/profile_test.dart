import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velomine/core/units.dart';
import 'package:velomine/core/widgets/section_card.dart';
import 'package:velomine/core/widgets/source_note.dart';
import 'package:velomine/features/rides/detail/ride_detail_screen.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com', name: 'Ada'));
  });

  Future<void> openProfile(
    WidgetTester tester, {
    Size size = const Size(1000, 1600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await openAccount(tester, 'profile');
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
    String? hint(String key) =>
        tester.widget<TextField>(find.byKey(Key(key))).decoration!.hintText;
    expect(field('profile-name'), 'Ada');
    expect(field('profile-ftp'), '250');
    expect(field('profile-weight'), '64.5');
    expect(field('profile-birth-year'), '1990');
    // Born 1990: 208 − 0.7 × 36 = 183, and 89 % of it. An estimate is the field's hint, not its value.
    expect(field('profile-max-hr'), '');
    expect(hint('profile-max-hr'), '183');
    expect(field('profile-threshold-hr'), '');
    expect(hint('profile-threshold-hr'), '163');
    expect(field('profile-zone'), 'Europe/Rome');
    expect(find.text('Sunday'), findsOneWidget);
  });

  testWidgets('ProfileScreen_ShouldExplainTheMaxHeartRate_WhenItIsEstimated', (
    tester,
  ) async {
    server.profiles['rider@example.com'] = {
      'displayName': 'Ada',
      'ftpW': null,
      'weightKg': null,
      'birthYear': 1990,
      'timeZone': null,
      'firstDayOfWeek': 'monday',
      'emailNotifications': true,
      'emailAccountNotifications': true,
      'emailTrainingNotifications': false,
      'hasPassword': true,
    };
    await openProfile(tester);

    final note = tester.widget<SourceNote>(
      find.byKey(const Key('profile-max-hr-source')),
    );
    expect(note.text, 'Estimated from your age (208 − 0.7 × age)');
    final threshold = tester.widget<SourceNote>(
      find.byKey(const Key('profile-threshold-hr-source')),
    );
    expect(threshold.text, 'Estimated as 89 % of your maximum');
    // An estimated threshold is always below the maximum, so nothing is said about it.
    expect(
      find.byKey(const Key('profile-threshold-hr-above-max')),
      findsNothing,
    );
    expect(
      find.text('The highest heart rate you can hold for about an hour.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'ProfileScreen_ShouldSuggestAddingWeight_WhenRidesHaveNoPowerAndNoWeight',
    (tester) async {
      server.profiles['rider@example.com'] = {
        'displayName': 'Ada',
        'ftpW': null,
        'weightKg': null,
        'birthYear': 1990,
        'timeZone': null,
        'firstDayOfWeek': 'monday',
        'emailNotifications': true,
        'emailAccountNotifications': true,
        'emailTrainingNotifications': false,
        'hasPassword': true,
        'hasRidesWithoutPower': true,
      };
      await openProfile(tester);

      final weight = tester.widget<TextField>(
        find.byKey(const Key('profile-weight')),
      );
      expect(
        weight.decoration!.helperText,
        'Add your weight to estimate watts on rides without a power meter.',
      );
    },
  );

  testWidgets('ProfileScreen_ShouldOpenTheRide_WhenAMeasuredHeartRateIsTapped', (
    tester,
  ) async {
    server.rides.add(
      rideJson(
        'r1',
        'ready',
        startTime: '2026-11-12T23:30:00Z',
        utcOffsetMinutes: 60,
      ),
    );
    server.profiles['rider@example.com'] = {
      'displayName': 'Ada',
      'ftpW': null,
      'weightKg': null,
      'birthYear': 1990,
      'timeZone': 'Europe/Rome',
      'firstDayOfWeek': 'monday',
      'emailNotifications': true,
      'emailAccountNotifications': true,
      'emailTrainingNotifications': false,
      'hasPassword': true,
      'maxHeartRate': 192,
      'maxHeartRateSource': 'measured',
      'maxHeartRateRideId': 'r1',
    };
    await openProfile(tester);

    // The ride's own local date: 23:30 UTC on the 12th is early on the 13th where it was ridden.
    expect(
      find.text(
        'Measured on your ride of ${DateFormat.yMMMd().format(DateTime(2026, 11, 13))}',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('profile-max-hr-source')));
    await tester.pumpAndSettle();
    expect(find.byType(RideDetailScreen), findsOneWidget);
  });

  testWidgets('ProfileScreen_ShouldShowNoLink_WhenTheMeasuringRideWasDeleted', (
    tester,
  ) async {
    server.profiles['rider@example.com'] = {
      'displayName': 'Ada',
      'ftpW': null,
      'weightKg': null,
      'birthYear': 1990,
      'timeZone': 'Europe/Rome',
      'firstDayOfWeek': 'monday',
      'emailNotifications': true,
      'emailAccountNotifications': true,
      'emailTrainingNotifications': false,
      'hasPassword': true,
      'maxHeartRate': 192,
      'maxHeartRateSource': 'measured',
      'maxHeartRateRideId': null,
    };
    await openProfile(tester);

    expect(find.text('Measured on a ride you deleted'), findsOneWidget);
    final note = tester.widget<SourceNote>(
      find.byKey(const Key('profile-max-hr-source')),
    );
    expect(note.onTap, isNull);
  });

  testWidgets(
    'ProfileScreen_ShouldNotSave_WhenAnEstimatedFieldIsLeftUntouched',
    (tester) async {
      // Born 1990: an estimated maximum and threshold, both shown as hints; leaving them alone writes nothing.
      server.profiles['rider@example.com'] = {
        'displayName': 'Ada',
        'ftpW': null,
        'weightKg': null,
        'birthYear': 1990,
        'timeZone': null,
        'firstDayOfWeek': 'monday',
        'emailNotifications': true,
        'emailAccountNotifications': true,
        'emailTrainingNotifications': false,
        'hasPassword': true,
      };
      await openProfile(tester);

      await tester.enterText(find.byKey(const Key('profile-max-hr')), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('profile-threshold-hr')), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(
        server.requests.where((r) => r.contains('/accounts/me/heart-rate')),
        isEmpty,
      );
    },
  );

  testWidgets('ProfileScreen_ShouldSaveAsManual_WhenTheRiderTypesANumber', (
    tester,
  ) async {
    await openProfile(tester);

    await tester.enterText(find.byKey(const Key('profile-max-hr')), '190');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(server.requests, contains('PUT /api/v1/accounts/me/heart-rate/max'));
    expect(server.profiles['rider@example.com']!['maxHeartRate'], 190);
    expect(
      server.profiles['rider@example.com']!['maxHeartRateSource'],
      'manual',
    );
  });

  testWidgets(
    'ProfileScreen_ShouldSaveAsManual_WhenTheRiderTypesTheEstimatedMaximum',
    (tester) async {
      // Born 1990: the maximum is an estimate, so it is only the field's hint. Typing that very number is the
      // rider's own, not the server's value in use.
      server.profiles['rider@example.com'] = {
        'displayName': 'Ada',
        'ftpW': null,
        'weightKg': null,
        'birthYear': 1990,
        'timeZone': null,
        'firstDayOfWeek': 'monday',
        'emailNotifications': true,
        'emailAccountNotifications': true,
        'emailTrainingNotifications': false,
        'hasPassword': true,
      };
      await openProfile(tester);
      final estimate = tester
          .widget<TextField>(find.byKey(const Key('profile-max-hr')))
          .decoration!
          .hintText!;

      await tester.enterText(find.byKey(const Key('profile-max-hr')), estimate);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(
        server.requests,
        contains('PUT /api/v1/accounts/me/heart-rate/max'),
      );
      expect(
        server.profiles['rider@example.com']!['maxHeartRateSource'],
        'manual',
      );
      expect(
        server.profiles['rider@example.com']!['maxHeartRate'],
        int.parse(estimate),
      );
    },
  );

  testWidgets(
    'ProfileScreen_ShouldSaveAsManual_WhenTheRiderTypesTheEstimatedThreshold',
    (tester) async {
      server.profiles['rider@example.com'] = {
        'displayName': 'Ada',
        'ftpW': null,
        'weightKg': null,
        'birthYear': 1990,
        'timeZone': null,
        'firstDayOfWeek': 'monday',
        'emailNotifications': true,
        'emailAccountNotifications': true,
        'emailTrainingNotifications': false,
        'hasPassword': true,
      };
      await openProfile(tester);
      final estimate = tester
          .widget<TextField>(find.byKey(const Key('profile-threshold-hr')))
          .decoration!
          .hintText!;

      await tester.enterText(
        find.byKey(const Key('profile-threshold-hr')),
        estimate,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(
        server.requests,
        contains('PUT /api/v1/accounts/me/heart-rate/threshold'),
      );
      expect(
        server.profiles['rider@example.com']!['thresholdHeartRateSource'],
        'manual',
      );
      expect(
        server.profiles['rider@example.com']!['thresholdHeartRate'],
        int.parse(estimate),
      );
    },
  );

  testWidgets(
    'ProfileScreen_ShouldGoBackToTheEstimate_WhenATypedValueIsEmptied',
    (tester) async {
      server.profiles['rider@example.com'] = {
        'displayName': 'Ada',
        'ftpW': null,
        'weightKg': null,
        'birthYear': 1990,
        'timeZone': null,
        'firstDayOfWeek': 'monday',
        'emailNotifications': true,
        'emailAccountNotifications': true,
        'emailTrainingNotifications': false,
        'hasPassword': true,
        'maxHeartRate': 195,
        'maxHeartRateSource': 'manual',
        'maxHeartRateSetAt': '2026-11-12T09:00:00Z',
      };
      await openProfile(tester);

      // The field holds the typed 195, and emptying it goes back to the estimate.
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('profile-max-hr')))
            .controller!
            .text,
        '195',
      );
      await tester.enterText(find.byKey(const Key('profile-max-hr')), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(
        server.requests,
        contains('DELETE /api/v1/accounts/me/heart-rate/max'),
      );
      expect(server.profiles['rider@example.com']!['maxHeartRate'], isNull);
    },
  );

  testWidgets(
    'ProfileScreen_ShouldSayTheThresholdIsAboveTheMaximum_WhenTheMaximumWasLowered',
    (tester) async {
      server.profiles['rider@example.com'] = {
        'displayName': 'Ada',
        'ftpW': null,
        'weightKg': null,
        'birthYear': 1990,
        'timeZone': null,
        'firstDayOfWeek': 'monday',
        'emailNotifications': true,
        'emailAccountNotifications': true,
        'emailTrainingNotifications': false,
        'hasPassword': true,
        'maxHeartRate': 150,
        'maxHeartRateSource': 'manual',
        'thresholdHeartRate': 170,
        'thresholdHeartRateSource': 'manual',
      };
      await openProfile(tester);

      final note = tester.widget<SourceNote>(
        find.byKey(const Key('profile-threshold-hr-above-max')),
      );
      expect(
        note.text,
        'Above the maximum in use (150 bpm). Your zones still follow the maximum.',
      );
    },
  );

  testWidgets(
    'ProfileScreen_ShouldSaveImperialUnits_WhenTheMemberChoosesThem',
    (tester) async {
      await openProfile(tester);

      // Units are a segmented control, and the choice is saved as it is made.
      await tester.ensureVisible(find.byKey(const Key('profile-units')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Imperial (miles, lb)'));
      await tester.pumpAndSettle();

      expect(server.requests, contains('PUT /api/v1/accounts/me/units'));
      expect(server.accounts['rider@example.com']!.units, 'imperial');
    },
  );

  testWidgets('ProfileScreen_ShouldShowAndSendPounds_WhenUnitsAreImperial', (
    tester,
  ) async {
    server.accounts['rider@example.com']!.units = 'imperial';
    server.profiles['rider@example.com'] = {
      'displayName': 'Ada',
      'ftpW': 250,
      'weightKg': 64.5,
      'birthYear': 1990,
      'timeZone': 'Europe/Rome',
      'firstDayOfWeek': 'monday',
      'emailNotifications': true,
      'emailAccountNotifications': true,
      'emailTrainingNotifications': false,
      'hasPassword': true,
    };
    await openProfile(tester);

    // 64.5 kg reads as 142.2 lb, and is sent back to the server in kilograms.
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('profile-weight')))
          .controller!
          .text,
      '142.2',
    );
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();

    expect(
      server.profiles['rider@example.com']!['weightKg'],
      closeTo(64.5, 0.05),
    );
  });

  testWidgets(
    'ProfileScreen_ShouldAcceptTheLightestWeight_WhenUnitsAreImperial',
    (tester) async {
      server.accounts['rider@example.com']!.units = 'imperial';
      await openProfile(tester);

      // 44 lb is exactly 20 kg, the lightest the server takes. It must not be refused here.
      await tester.enterText(find.byKey(const Key('profile-weight')), '44');
      await tester.tap(find.byKey(const Key('profile-save')));
      await tester.pumpAndSettle();

      expect(server.requests, contains('PUT /api/v1/accounts/me/profile'));
      expect(
        server.profiles['rider@example.com']!['weightKg'],
        closeTo(19.96, 0.01),
      );
    },
  );

  testWidgets('ProfileScreen_ShouldSaveTelemetryChoice_WhenSwitched', (
    tester,
  ) async {
    server.telemetryEnabled = true;
    server.sentryDsn = 'https://key@example.invalid/1';
    await openProfile(tester);

    expect(find.byKey(const Key('telemetry-crash')), findsOneWidget);
    // The two heart-rate fields pushed the switch below the first screen.
    await tester.ensureVisible(find.byKey(const Key('telemetry-crash')));
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
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

    // The preferences card, above, pushes the notifications below the first screen.
    await tester.ensureVisible(find.byKey(const Key('profile-email')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-email')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profile-save')));
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
    await openAccount(tester, 'profile');
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

  testWidgets(
    'ProfileScreen_ShouldOpenPasswordFormAsSheet_WhenChangingPassword',
    (tester) async {
      await openProfile(tester);

      await tapVisible(tester, 'change-password');

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byKey(const Key('confirm-change-password')), findsOneWidget);
    },
  );

  testWidgets('ProfileScreen_ShouldKeepDeleteLastAndRedInMenu_WhenMenuOpens', (
    tester,
  ) async {
    await openProfile(tester);

    // Not a visible button on the page any more.
    expect(find.byKey(const Key('delete-account')), findsNothing);
    await tester.tap(find.byKey(const Key('profile-actions')));
    await tester.pumpAndSettle();

    final delete = find.byKey(const Key('delete-account'));
    expect(delete, findsOneWidget);
    final style = tester.widget<MenuItemButton>(delete).style!;
    expect(
      style.foregroundColor!.resolve({}),
      Theme.of(tester.element(delete)).colorScheme.error,
    );
    final items = find.byType(MenuItemButton);
    expect(tester.getTopLeft(delete).dy, tester.getTopLeft(items.last).dy);

    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('delete-confirm')), findsOneWidget);
    expect(find.text('Your password'), findsOneWidget);
  });

  group('deleting the account', () {
    Future<void> chooseDelete(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('profile-actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('delete-account')));
      await tester.pumpAndSettle();
    }

    Future<void> openDelete(WidgetTester tester) async {
      await openProfile(tester);
      await chooseDelete(tester);
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
        find.byKey(const Key('account-menu')),
        findsOneWidget,
      ); // still signed in
    });

    testWidgets('DeleteAccountDialog_ShouldDeleteNothing_WhenCancelled', (
      tester,
    ) async {
      await openDelete(tester);

      // The sheet has no Cancel: dragging it down is the cancel.
      await tester.drag(find.byType(BottomSheet), const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('confirm-delete-account')), findsNothing);

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
      expect(find.byKey(const Key('account-menu')), findsNothing);
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
      await chooseDelete(tester);
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

  Map<String, Object?> bike(String id, {int due = 0}) => {
    'id': id,
    'name': 'Bike $id',
    'kind': 'road',
    'wheelCircumferenceMm': 2105,
    'initialDistanceM': 0.0,
    'isDefault': false,
    'serviceDueCount': due,
  };

  testWidgets('ProfileScreen_ShouldOpenBikesAndReturn_WhenMyBikesIsTapped', (
    tester,
  ) async {
    server.bikes.add(bike('bike-1'));
    await openProfile(tester);

    await tester.tap(find.byKey(const Key('profile-my-bikes')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bike-bike-1')), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-my-bikes')), findsOneWidget);
    expect(find.byKey(const Key('profile-name')), findsOneWidget);
  });

  testWidgets('ProfileScreen_ShouldShowCountAndDueMarker_WhenABikeHasAJobDue', (
    tester,
  ) async {
    server.bikes.addAll([bike('bike-1'), bike('bike-2', due: 1)]);
    await openProfile(tester);

    expect(find.text('2 bikes'), findsOneWidget);
    expect(find.byKey(const Key('service-due')), findsOneWidget);
  });

  testWidgets('ProfileScreen_ShouldShowNoMarker_WhenNoBikeNeedsService', (
    tester,
  ) async {
    server.bikes.add(bike('bike-1'));
    await openProfile(tester);

    expect(find.text('1 bike'), findsOneWidget);
    expect(find.byKey(const Key('service-due')), findsNothing);
  });

  testWidgets('BikeDetailScreen_ShouldOpen_WhenAnOldBikeLinkIsFollowed', (
    tester,
  ) async {
    server.bikes.add(bike('bike-1'));
    await openProfile(tester);

    await goTo(tester, '/bikes/bike-1');
    expect(find.text('Bike bike-1'), findsWidgets);
    expect(find.byKey(const Key('bike-actions')), findsOneWidget);
  });

  /// The title of the card a widget sits in: the design's sections are cards of their own.
  String cardTitleOf(WidgetTester tester, String key) => tester
      .widget<SectionCard>(
        find
            .ancestor(
              of: find.byKey(Key(key)),
              matching: find.byType(SectionCard),
            )
            .first,
      )
      .title;

  testWidgets(
    'ProfileScreen_ShouldKeepThePreferencesInTheirOwnCard_WhenOpened',
    (tester) async {
      await openProfile(tester, size: const Size(1000, 4000));

      // The athlete card holds the numbers; how the app behaves lives in Preferences.
      expect(cardTitleOf(tester, 'profile-name'), 'Athlete');
      expect(cardTitleOf(tester, 'profile-birth-year'), 'Athlete');
      expect(cardTitleOf(tester, 'profile-zone'), 'Preferences');
      expect(cardTitleOf(tester, 'profile-language'), 'Preferences');
      expect(cardTitleOf(tester, 'profile-units'), 'Preferences');
    },
  );

  testWidgets('ProfileScreen_ShouldDrawLanguageAndUnitsAsSegments_WhenOpened', (
    tester,
  ) async {
    await openProfile(tester, size: const Size(1000, 4000));

    // Both choices are one tap, never a menu.
    expect(
      tester.widget<SegmentedButton<String>>(
        find.byKey(const Key('profile-language')),
      ),
      isA<SegmentedButton<String>>(),
    );
    expect(
      tester.widget<SegmentedButton<Units>>(
        find.byKey(const Key('profile-units')),
      ),
      isA<SegmentedButton<Units>>(),
    );
  });

  testWidgets('ProfileScreen_ShouldAskTheBirthYearBeforeTheFtp_WhenOpened', (
    tester,
  ) async {
    await openProfile(tester);

    // The athlete fields read in the design's order: name, year of birth, FTP, weight.
    expect(
      tester.getTopLeft(find.byKey(const Key('profile-birth-year'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('profile-ftp'))).dy),
    );
  });

  testWidgets(
    'ProfileScreen_ShouldKeepBikesAndPrivacyInTheRidingCard_WhenOpened',
    (tester) async {
      server.bikes.add(bike('bike-1'));
      await openProfile(tester, size: const Size(1000, 4000));

      expect(cardTitleOf(tester, 'profile-my-bikes'), 'Riding');
      expect(cardTitleOf(tester, 'profile-ride-privacy'), 'Riding');
    },
  );

  testWidgets(
    'ProfileScreen_ShouldKeepTelemetryInItsOwnCard_WhenTheServerCollectsIt',
    (tester) async {
      server.telemetryEnabled = true;
      server.sentryDsn = 'https://key@example.invalid/1';
      await openProfile(tester, size: const Size(1000, 4000));

      // The opt-in is its own card, never a row of the privacy settings.
      expect(cardTitleOf(tester, 'telemetry-crash'), 'Help improve Velomine');
      expect(cardTitleOf(tester, 'telemetry-usage'), 'Help improve Velomine');
    },
  );

  testWidgets('ProfileScreen_ShouldDrawEveryEmailChoiceAsASwitch_WhenOpened', (
    tester,
  ) async {
    await openProfile(tester, size: const Size(1000, 4000));

    for (final key in [
      'profile-email',
      'profile-email-account',
      'profile-email-training',
    ]) {
      expect(tester.widget<SwitchListTile>(find.byKey(Key(key))), isNotNull);
    }
    expect(find.byType(CheckboxListTile), findsNothing);
  });

  testWidgets(
    'ProfileScreen_ShouldDownloadFromAButton_WhenTheDataCardIsShown',
    (tester) async {
      await openProfile(tester, size: const Size(1000, 4000));

      // A quiet button under the sentence, not a settings row with a chevron.
      expect(
        find.widgetWithText(OutlinedButton, 'Download my data'),
        findsOneWidget,
      );
    },
  );

  for (final width in [390.0, 1300.0]) {
    testWidgets('ProfileScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}', (
      tester,
    ) async {
      server.bikes.add(bike('bike-1', due: 1));
      await openProfile(tester, size: Size(width, 2400));

      // The segmented choices are the widest thing on the page, so they are laid out before the check.
      await tester.ensureVisible(find.byKey(const Key('profile-units')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
