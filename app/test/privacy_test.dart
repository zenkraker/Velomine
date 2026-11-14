import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() => server = FakeServer());

  Future<void> openPrivacy(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(
      tester,
      server.session(useCookies: true),
      locationService: FakeLocationService((latitude: 46.0, longitude: 11.0)),
    );
    await openAccount(tester, 'profile');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profile-ride-privacy')));
    await tester.tap(find.byKey(const Key('profile-ride-privacy')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'PrivacyScreen_ShouldSaveStreamSwitchesAndRemoveAZone_WhenTheMemberChangesThem',
    (tester) async {
      final rider = server.add('rider@example.com', clubRole: null);
      server.signInBrowser(rider);
      server.privacyZones.add({
        'id': 'zone-home',
        'name': 'Home',
        'latitude': 46.0,
        'longitude': 11.0,
        'radiusM': 500,
      });
      await openPrivacy(tester);

      expect(find.text('Ride privacy'), findsWidgets);
      expect(find.byKey(const Key('privacy-zone-zone-home')), findsOneWidget);
      expect(server.privacyStreams['hidePower'], isFalse);

      // Sharing starts fully visible; turning power off hides it for every non-owner.
      await tester.ensureVisible(find.byKey(const Key('privacy-hide-power')));
      await tester.tap(find.byKey(const Key('privacy-hide-power')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('privacy-save')));
      await tester.tap(find.byKey(const Key('privacy-save')));
      await tester.pumpAndSettle();

      expect(server.privacyStreams['hidePower'], isTrue);
      expect(server.privacyStreams['hideHeartRate'], isFalse);

      await tester.ensureVisible(
        find.byKey(const Key('privacy-zone-delete-zone-home')),
      );
      await tester.tap(find.byKey(const Key('privacy-zone-delete-zone-home')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-privacy-zone-delete')));
      await tester.pumpAndSettle();

      expect(server.privacyZones, isEmpty);
    },
  );

  testWidgets('PrivacyScreen_ShouldSaveTrims_WhenTheMemberEntersMetres', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await openPrivacy(tester);

    await tester.enterText(find.byKey(const Key('privacy-trim-start')), '6000');
    await tester.ensureVisible(find.byKey(const Key('privacy-save')));
    await tester.tap(find.byKey(const Key('privacy-save')));
    await tester.pumpAndSettle();

    // Over five kilometres is refused before the server is asked.
    expect(find.byKey(const Key('privacy-error')), findsOneWidget);
    expect(server.privacyTrimStartM, 0);

    await tester.enterText(find.byKey(const Key('privacy-trim-start')), '500');
    await tester.enterText(find.byKey(const Key('privacy-trim-end')), '300');
    await tester.tap(find.byKey(const Key('privacy-save')));
    await tester.pumpAndSettle();

    expect(server.privacyTrimStartM, 500);
    expect(server.privacyTrimEndM, 300);
  });

  testWidgets(
    'PrivacyZoneDialog_ShouldTurnMilesIntoSafeMetres_WhenUnitsAreImperial',
    (tester) async {
      final rider = server.add(
        'rider@example.com',
        clubRole: null,
        units: 'imperial',
      );
      server.signInBrowser(rider);
      await openPrivacy(tester);

      Future<void> openDialog() async {
        await tester.ensureVisible(find.byKey(const Key('privacy-add-zone')));
        await tester.tap(find.byKey(const Key('privacy-add-zone')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('location-use')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('privacy-zone-name')),
          'Home',
        );
      }

      Future<void> typeRadius(String value) async {
        await tester.enterText(
          find.byKey(const Key('privacy-zone-radius')),
          value,
        );
        await tester.tap(find.byKey(const Key('privacy-zone-save')));
        await tester.pumpAndSettle();
      }

      await openDialog();

      // 0.12 mi is 193 m, under the legal 200 m floor, so it is refused and nothing is saved.
      await typeRadius('0.12');
      expect(find.byKey(const Key('privacy-zone-error')), findsOneWidget);
      expect(server.privacyZones, isEmpty);

      // 2 mi is 3219 m, over the 1609 m ceiling, so it is refused too.
      await typeRadius('2');
      expect(find.byKey(const Key('privacy-zone-error')), findsOneWidget);
      expect(server.privacyZones, isEmpty);

      // 0.2 mi is 322 m: inside the range, and stored in metres.
      await typeRadius('0.2');
      expect(server.privacyZones.single['radiusM'], 322);
    },
  );
}
