import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velomine/core/widgets/bottom_action_bar.dart';
import 'package:velomine/core/widgets/section_card.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() => server = FakeServer());

  Future<void> openPrivacy(
    WidgetTester tester, {
    Size size = const Size(1000, 2400),
  }) async {
    tester.view.physicalSize = size;
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

  testWidgets('PrivacyScreen_ShouldKeepSaveInTheBottomBar_WhenItOpens', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await openPrivacy(tester);

    // One save for both cards, pinned under the content instead of inside the first card.
    expect(
      find.descendant(
        of: find.byType(BottomActionBar),
        matching: find.byKey(const Key('privacy-save')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('PrivacyScreen_ShouldDrawBothGroupsAsCards_WhenItOpens', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await openPrivacy(tester);

    String cardTitleOf(String key) => tester
        .widget<SectionCard>(
          find
              .ancestor(
                of: find.byKey(Key(key)),
                matching: find.byType(SectionCard),
              )
              .first,
        )
        .title;

    expect(cardTitleOf('privacy-trim-start'), 'Hide the start and end');
    expect(cardTitleOf('privacy-add-zone'), 'Saved places');
  });

  for (final width in [390.0, 1300.0]) {
    testWidgets('PrivacyScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}', (
      tester,
    ) async {
      final rider = server.add('rider@example.com', clubRole: null);
      server.signInBrowser(rider);
      server.privacyZones.add({
        'id': 'zone-home',
        'name': 'Home',
        'latitude': 46.0,
        'longitude': 11.0,
        'radiusM': 500,
      });
      await openPrivacy(tester, size: Size(width, 2400));

      expect(find.byKey(const Key('privacy-zone-zone-home')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('PrivacyScreen_ShouldNotShowStreamSwitches_WhenItOpens', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await openPrivacy(tester);

    // A coach sees every number of what the rider shares, so there is no switch to hide one; only the route
    // keeps its trim and its saved places.
    expect(find.text('Ride privacy'), findsWidgets);
    expect(find.byKey(const Key('privacy-hide-power')), findsNothing);
    expect(find.byKey(const Key('privacy-hide-heart-rate')), findsNothing);
    expect(find.text('What others see of each ride'), findsNothing);
    expect(find.byKey(const Key('privacy-trim-start')), findsOneWidget);
    expect(find.byKey(const Key('privacy-add-zone')), findsOneWidget);
  });

  testWidgets('PrivacyScreen_ShouldSaveTheTrimWithoutTheSwitches_WhenSaved', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await openPrivacy(tester);

    await tester.enterText(find.byKey(const Key('privacy-trim-start')), '500');
    await tester.ensureVisible(find.byKey(const Key('privacy-save')));
    await tester.tap(find.byKey(const Key('privacy-save')));
    await tester.pumpAndSettle();

    expect(server.privacyTrimStartM, 500);
    expect(server.privacyStreams['hidePower'], isFalse);
  });

  testWidgets('PrivacyScreen_ShouldAskAndRemoveAZone_WhenTheMemberDeletesIt', (
    tester,
  ) async {
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

    expect(find.byKey(const Key('privacy-zone-zone-home')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('privacy-zone-actions-zone-home')),
    );
    await tester.tap(find.byKey(const Key('privacy-zone-actions-zone-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('privacy-zone-delete-zone-home')));
    await tester.pumpAndSettle();
    // It asks first: nothing is removed until the red action is chosen.
    expect(server.privacyZones, isNotEmpty);
    await tester.tap(find.byKey(const Key('confirm-privacy-zone-delete')));
    await tester.pumpAndSettle();

    expect(server.privacyZones, isEmpty);
  });

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
      expect(find.byKey(const Key('form-error')), findsOneWidget);
      expect(server.privacyZones, isEmpty);

      // 2 mi is 3219 m, over the 1609 m ceiling, so it is refused too.
      await typeRadius('2');
      expect(find.byKey(const Key('form-error')), findsOneWidget);
      expect(server.privacyZones, isEmpty);

      // 0.2 mi is 322 m: inside the range, and stored in metres.
      await typeRadius('0.2');
      expect(server.privacyZones.single['radiusM'], 322);
    },
  );

  testWidgets(
    'PrivacyScreen_ShouldConfirmBeforeRemovingAZone_WhenRemoveIsTapped',
    (tester) async {
      final rider = server.add('other@example.com', clubRole: null);
      server.signInBrowser(rider);
      server.privacyZones.add({
        'id': 'zone-work',
        'name': 'Work',
        'latitude': 46.0,
        'longitude': 11.0,
        'radiusM': 500,
      });
      await openPrivacy(tester);

      await tester.ensureVisible(
        find.byKey(const Key('privacy-zone-actions-zone-work')),
      );
      await tester.tap(find.byKey(const Key('privacy-zone-actions-zone-work')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('privacy-zone-delete-zone-work')));
      await tester.pumpAndSettle();

      // The zone is still there, behind the question, and the button names the action.
      expect(server.privacyZones, isNotEmpty);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(server.privacyZones, isNotEmpty);
    },
  );
}
