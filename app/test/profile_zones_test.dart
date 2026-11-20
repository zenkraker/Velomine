import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

/// Story 4: the profile lists the zones in use and lets the rider move their limits by hand, or go back to
/// automatic. The list shows power and the heart-rate set in use; the sheet edits the top of each zone in watts or
/// bpm and the app sends fractions of the reference.
void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com', name: 'Ada'));
  });

  /// An FTP of 250 W and a typed maximum and threshold: the zones come from the threshold, and power is listed too.
  void withZones({String language = 'en'}) {
    server.accounts['rider@example.com']!.language = language;
    server.profiles['rider@example.com'] = {
      'displayName': 'Ada',
      'ftpW': 250,
      'weightKg': null,
      'birthYear': null,
      'timeZone': null,
      'firstDayOfWeek': 'monday',
      'emailNotifications': true,
      'emailAccountNotifications': true,
      'emailTrainingNotifications': false,
      'hasPassword': true,
      'maxHeartRate': 185,
      'maxHeartRateSource': 'manual',
      'thresholdHeartRate': 160,
      'thresholdHeartRateSource': 'manual',
    };
  }

  Future<void> openProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await openAccount(tester, 'profile');
    await tester.pumpAndSettle();
  }

  Future<void> openSheet(WidgetTester tester) async {
    final edit = find.byKey(const Key('zones-edit'));
    await tester.ensureVisible(edit);
    await tester.pumpAndSettle();
    await tester.tap(edit);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'ProfileScreen_ShouldListTheZones_WhenTheRiderHasPowerAndAThreshold',
    (tester) async {
      withZones();
      await openProfile(tester);

      expect(find.text('Zones'), findsOneWidget);
      expect(find.text('Power zones'), findsOneWidget);
      expect(find.text('Heart rate zones'), findsOneWidget);
      // The power zones, from the standard bounds of an FTP of 250 W.
      expect(find.text('0–137 W'), findsOneWidget);
      expect(find.text('≥ 375 W'), findsOneWidget);
      // The heart-rate zones come from the typed threshold, and the card says so.
      expect(
        find.text('Zones from your threshold heart rate (160 bpm)'),
        findsOneWidget,
      );
      expect(find.text('0–129 bpm'), findsOneWidget);
      expect(find.byKey(const Key('zones-edit')), findsOneWidget);
    },
  );

  testWidgets('ProfileScreen_ShouldShowNoZones_WhenTheRiderHasNeitherNumber', (
    tester,
  ) async {
    server.profiles['rider@example.com'] = {
      'displayName': 'Ada',
      'ftpW': null,
      'weightKg': null,
      'birthYear': null,
      'timeZone': null,
      'firstDayOfWeek': 'monday',
      'emailNotifications': true,
      'emailAccountNotifications': true,
      'emailTrainingNotifications': false,
      'hasPassword': true,
    };
    await openProfile(tester);

    expect(find.text('Zones'), findsNothing);
  });

  testWidgets('ZonesSheet_ShouldSendFractions_WhenTheRiderEditsALimit', (
    tester,
  ) async {
    withZones();
    await openProfile(tester);
    await openSheet(tester);

    final first = find.byKey(const Key('zone-limit-power-1'));
    expect(tester.widget<TextField>(first).controller!.text, '138');
    await tester.enterText(first, '150');
    await tester.tap(find.byKey(const Key('zones-save')));
    await tester.pumpAndSettle();

    // 150 W of 250 is 0.60, and the sheet then shows the value the server kept.
    expect(server.zoneBounds['rider@example.com']?['power']?.first, 0.6);
    expect(tester.widget<TextField>(first).controller!.text, '150');
  });

  testWidgets(
    'ZonesSheet_ShouldRefuseToSave_WhenALimitIsNotHigherThanTheOneBefore',
    (tester) async {
      withZones();
      await openProfile(tester);
      await openSheet(tester);

      await tester.enterText(
        find.byKey(const Key('zone-limit-power-2')),
        '100',
      );
      await tester.tap(find.byKey(const Key('zones-save')));
      await tester.pumpAndSettle();

      expect(
        find.text('Each zone\'s limit must be higher than the one before it.'),
        findsOneWidget,
      );
      expect(server.zoneBounds['rider@example.com'], isNull);
    },
  );

  testWidgets('ProfileScreen_ShouldResetEverySet_WhenBackToAutomaticIsChosen', (
    tester,
  ) async {
    withZones();
    server.zoneBounds['rider@example.com'] = {
      'power': [0.6, 0.9, 1.05, 1.2, 1.4, 1.7],
    };
    await openProfile(tester);

    await tester.tap(find.byKey(const Key('zones-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('zones-reset')));
    await tester.pumpAndSettle();
    expect(find.text('Use the standard zones?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-zones-reset')));
    await tester.pumpAndSettle();

    expect(server.zoneBounds['rider@example.com'], isEmpty);
    expect(
      server.requests.where(
        (r) => r.startsWith('DELETE') && r.contains('/zones/'),
      ),
      hasLength(3),
    );
    expect(find.text('0–137 W'), findsOneWidget);
  });

  testWidgets('ZonesSheet_ShouldSpeakItalian_WhenTheLanguageIsItalian', (
    tester,
  ) async {
    withZones(language: 'it');
    await openProfile(tester);
    await openSheet(tester);

    expect(find.text('Le tue zone'), findsOneWidget);
    // Both sets are listed: power and the heart-rate model in use, so zone 1 appears twice.
    expect(find.text('Zona 1 fino a'), findsNWidgets(2));
    expect(find.text('Salva'), findsWidgets);

    await tester.enterText(
      find.byKey(const Key('zone-limit-heart-rate-threshold-1')),
      '120',
    );
    await tester.tap(find.byKey(const Key('zones-save')));
    await tester.pumpAndSettle();

    // 120 of a threshold of 160 is 0.75.
    expect(
      server.zoneBounds['rider@example.com']?['heart-rate-threshold']?.first,
      0.75,
    );
  });
}
