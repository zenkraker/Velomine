import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velomine/core/saved_mark_view_model.dart';
import 'package:velomine/core/widgets/bottom_action_bar.dart';
import 'package:velomine/core/widgets/section_card.dart';

import 'fake_server.dart';

/// Whether the app-level "Saved." mark is showing.
bool savedMarkVisible(WidgetTester tester) =>
    containerOf(tester).read(savedMarkViewModelProvider);

/// Leaves whatever field has the focus, the way a rider taps away from it.
Future<void> leaveField(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

/// Goes back from the privacy screen with a field still focused, the way the back action pops the route.
void popPrivacy(WidgetTester tester) {
  Navigator.of(tester.element(find.byKey(const Key('privacy-trim-start'))))
      .pop();
}

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

  testWidgets('PrivacyScreen_ShouldHaveNoSaveButton_WhenItOpens', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await openPrivacy(tester);

    // Each trim saves when its field is left, so there is no bottom save bar.
    expect(find.byType(BottomActionBar), findsNothing);
    expect(find.byKey(const Key('privacy-save')), findsNothing);
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
      // The place says what the radius is, in the mock-up's words.
      expect(find.text('Radius 500 m'), findsOneWidget);
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

  testWidgets(
    'PrivacyScreen_ShouldSaveTheTrimAndShowTheMark_WhenTheMemberLeavesTheField',
    (tester) async {
      final rider = server.add('rider@example.com', clubRole: null);
      server.signInBrowser(rider);
      await openPrivacy(tester);

      await tester.enterText(
        find.byKey(const Key('privacy-trim-start')),
        '500',
      );
      await leaveField(tester);

      expect(server.privacyTrimStartM, 500);
      expect(server.privacyStreams['hidePower'], isFalse);
      expect(savedMarkVisible(tester), isTrue);
      expect(find.text('Saved.'), findsOneWidget);

      // The mark goes on its own once the two seconds have passed.
      await tester.pump(const Duration(seconds: 3));
      expect(savedMarkVisible(tester), isFalse);
    },
  );

  testWidgets('PrivacyScreen_ShouldSaveOnDone_WhenTheMemberPressesDone', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await openPrivacy(tester);

    await tester.enterText(find.byKey(const Key('privacy-trim-end')), '300');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(server.privacyTrimEndM, 300);
    expect(savedMarkVisible(tester), isTrue);
  });

  testWidgets('PrivacyScreen_ShouldSendNothing_WhenTheFieldIsUnchanged', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await openPrivacy(tester);

    await tester.tap(find.byKey(const Key('privacy-trim-start')));
    await leaveField(tester);

    expect(server.requests, isNot(contains('PUT /api/v1/privacy/settings')));
    expect(savedMarkVisible(tester), isFalse);
  });

  testWidgets(
    'PrivacyScreen_ShouldNotResendTheRoundedTrim_WhenUnitsAreImperial',
    (tester) async {
      final rider = server.add(
        'rider@example.com',
        clubRole: null,
        units: 'imperial',
      );
      server.signInBrowser(rider);
      // 500 m is shown as 0.3 mi; leaving that field must not write 483 m instead.
      server.privacyTrimStartM = 500;
      await openPrivacy(tester);

      await tester.tap(find.byKey(const Key('privacy-trim-start')));
      await leaveField(tester);

      expect(server.requests, isNot(contains('PUT /api/v1/privacy/settings')));
      expect(server.privacyTrimStartM, 500);
    },
  );

  testWidgets('PrivacyScreen_ShouldHideTheMark_WhenTheSaveFails', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await openPrivacy(tester);
    server.failing.add('/api/v1/privacy/settings');

    await tester.enterText(find.byKey(const Key('privacy-trim-start')), '500');
    await leaveField(tester);

    expect(savedMarkVisible(tester), isFalse);
    expect(server.privacyTrimStartM, 0);
    // What the member typed stays in the field so they can fix it.
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('privacy-trim-start')))
          .controller!
          .text,
      '500',
    );
  });

  testWidgets('PrivacyScreen_ShouldSaveTheTrim_WhenLeftWhileStillTyping', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await openPrivacy(tester);

    // The field still has the focus when the member goes back: the typed trim is saved on the way out.
    await tester.enterText(find.byKey(const Key('privacy-trim-start')), '500');
    popPrivacy(tester);
    await tester.pumpAndSettle();

    expect(server.privacyTrimStartM, 500);
    expect(
      server.requests.where((r) => r == 'PUT /api/v1/privacy/settings'),
      hasLength(1),
    );
  });

  testWidgets('PrivacyScreen_ShouldSendNothing_WhenUnchangedAndLeft', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await openPrivacy(tester);

    await tester.tap(find.byKey(const Key('privacy-trim-start')));
    popPrivacy(tester);
    await tester.pumpAndSettle();

    expect(server.requests, isNot(contains('PUT /api/v1/privacy/settings')));
  });

  testWidgets(
    'PrivacyScreen_ShouldRefuseAFiveKilometreTrim_WhenLeftWhileStillTyping',
    (tester) async {
      final rider = server.add('rider@example.com', clubRole: null);
      server.signInBrowser(rider);
      await openPrivacy(tester);

      await tester.enterText(
        find.byKey(const Key('privacy-trim-start')),
        '6000',
      );
      popPrivacy(tester);
      await tester.pumpAndSettle();

      // Over five kilometres is never sent, even when the member leaves the screen before the field.
      expect(server.requests, isNot(contains('PUT /api/v1/privacy/settings')));
      expect(server.privacyTrimStartM, 0);
    },
  );

  testWidgets(
    'PrivacyScreen_ShouldSendOnce_WhenFocusLeftBeforeTheScreenCloses',
    (tester) async {
      final rider = server.add('rider@example.com', clubRole: null);
      server.signInBrowser(rider);
      await openPrivacy(tester);

      await tester.enterText(
        find.byKey(const Key('privacy-trim-start')),
        '500',
      );
      await leaveField(tester);
      popPrivacy(tester);
      await tester.pumpAndSettle();

      // The field was saved when it was left; leaving the screen does not send it again.
      expect(
        server.requests.where((r) => r == 'PUT /api/v1/privacy/settings'),
        hasLength(1),
      );
      expect(server.privacyTrimStartM, 500);
    },
  );

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
    // The place says what the radius is, in the mock-up's words.
    expect(find.text('Radius 500 m'), findsOneWidget);

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

  testWidgets('PrivacyScreen_ShouldRefuseAFiveKilometreTrim_WhenLeft', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await openPrivacy(tester);

    await tester.enterText(find.byKey(const Key('privacy-trim-start')), '6000');
    await leaveField(tester);

    // Over five kilometres is refused before the server is asked: nothing is sent and no mark shows.
    expect(find.byKey(const Key('privacy-error')), findsOneWidget);
    expect(server.requests, isNot(contains('PUT /api/v1/privacy/settings')));
    expect(server.privacyTrimStartM, 0);
    expect(savedMarkVisible(tester), isFalse);
  });

  testWidgets('PrivacyScreen_ShouldSaveEachTrimOnItsOwn_WhenLeft', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await openPrivacy(tester);

    await tester.enterText(find.byKey(const Key('privacy-trim-start')), '500');
    await leaveField(tester);
    await tester.enterText(find.byKey(const Key('privacy-trim-end')), '300');
    await leaveField(tester);

    // Each save sends the trim that was edited and the other one as the account holds it.
    expect(server.privacyTrimStartM, 500);
    expect(server.privacyTrimEndM, 300);
    expect(
      server.requests.where((r) => r == 'PUT /api/v1/privacy/settings'),
      hasLength(2),
    );
  });

  testWidgets('PrivacyScreen_ShouldClearTheError_WhenTheTrimIsFixed', (
    tester,
  ) async {
    final rider = server.add('rider@example.com', clubRole: null);
    server.signInBrowser(rider);
    await openPrivacy(tester);

    await tester.enterText(find.byKey(const Key('privacy-trim-start')), '6000');
    await leaveField(tester);
    expect(find.byKey(const Key('privacy-error')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('privacy-trim-start')), '500');
    await leaveField(tester);

    expect(find.byKey(const Key('privacy-error')), findsNothing);
    expect(server.privacyTrimStartM, 500);
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
      expect(savedMarkVisible(tester), isTrue);
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
