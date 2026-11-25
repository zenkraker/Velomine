import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.rides.add(
      rideJson('r1', 'ready', distanceM: 24500, movingS: 3720, avgPowerW: 190),
    );
    server.streams['r1'] = {
      'time': [0.0, 1.0, 2.0],
      'latitude': [46.0, 46.001, 46.002],
      'longitude': [11.0, 11.0, 11.0],
      'altitude': [300.0, 301.0, 302.0],
      'speed': [8.0, 8.0, 8.0],
      'distance': [0.0, 8.0, 16.0],
      'heartRate': [150, 151, 152],
      'power': [190, 195, 200],
      'cadence': [90, 90, 90],
      'temperature': null,
    };
  });

  testWidgets('ClubScreen_ShouldSaveSharing_WhenChosen', (tester) async {
    final rider = server.add('rider@example.com');
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));

    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('share-rides')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('share-rides')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My coaches').last);
    await tester.pumpAndSettle();
    // Sharing with a coach is told before it happens, so the rider agrees first.
    await tester.tap(find.byKey(const Key('share-rides-confirm')));
    await tester.pumpAndSettle();

    // The training comes with the rides; the route stays a choice of its own.
    expect(server.sharingChoices['rides'], 'coaches');
    expect(server.sharingChoices['analytics'], 'coaches');
    expect(server.sharingChoices['routes'], 'none');
  });

  testWidgets('CoachAthletesScreen_ShouldShowOnlySharedData_WhenOpened', (
    tester,
  ) async {
    final owner = server.add(
      'owner@example.com',
      name: 'Owner Rina',
      clubRole: 'owner',
    );
    final athlete = server.add('athlete@example.com', name: 'Athlete Luca');
    server.sharingChoices['rides'] = 'coaches';
    server.sharingChoices['analytics'] = 'none';
    server.signInBrowser(owner);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-athletes')));
    await tester.pumpAndSettle();

    final card = find.byKey(Key('athlete-${athlete.id}'));
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.textContaining('TSS')),
      findsNothing,
    );

    // Training only: no ride date on the roster, but the load is there.
    server.sharingChoices['rides'] = 'none';
    server.sharingChoices['analytics'] = 'coaches';
    // The Athletes page carries "Club" as its caption, so the destination is found by its key.
    await tester.tap(find.byKey(const Key('rail-club')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-athletes')));
    await tester.pumpAndSettle();

    final refreshed = find.byKey(Key('athlete-${athlete.id}'));
    expect(
      find.descendant(of: refreshed, matching: find.textContaining('TSS')),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: refreshed,
        matching: find.textContaining('Last ride'),
      ),
      findsNothing,
    );
  });

  testWidgets('CoachAthletesScreen_ShouldRespectSharedRoutes_WhenOpened', (
    tester,
  ) async {
    final owner = server.add(
      'owner@example.com',
      name: 'Owner Rina',
      clubRole: 'owner',
    );
    final athlete = server.add('athlete@example.com', name: 'Athlete Luca');
    server.sharingChoices['rides'] = 'coaches';
    server.sharingChoices['analytics'] = 'coaches';
    server.signInBrowser(owner);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-athletes')));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('athlete-${athlete.id}')), findsOneWidget);
    expect(find.text('Athlete Luca'), findsOneWidget);

    await tester.tap(find.byKey(Key('athlete-${athlete.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('training-tss')), findsOneWidget);
    expect(find.byKey(const Key('coach-ride-r1')), findsOneWidget);
    // The row leads with the ride's name, its day in the detail, as the mock-up draws it.
    expect(
      find.descendant(
        of: find.byKey(const Key('coach-ride-r1')),
        matching: find.text('Morning ride'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('coach-ride-r1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('coach-ride-not-found')), findsNothing);
    expect(find.byKey(const Key('route-not-shared')), findsOneWidget);
    expect(find.byKey(const Key('chart-power')), findsOneWidget);

    // The athlete shares routes too: the same ride now has its map.
    server.sharingChoices['routes'] = 'coaches';
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('coach-ride-r1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('route-map')), findsOneWidget);
    expect(find.byKey(const Key('route-not-shared')), findsNothing);
  });

  testWidgets('CoachAthleteScreen_ShouldShowPowerAndWellbeing_WhenShared', (
    tester,
  ) async {
    final owner = server.add(
      'owner@example.com',
      name: 'Owner Rina',
      clubRole: 'owner',
    );
    final athlete = server.add('athlete@example.com', name: 'Athlete Luca');
    server.sharingChoices['analytics'] = 'coaches';
    server.sharingChoices['wellbeing'] = 'coaches';
    server.wellbeingConsent = true;
    server.checkIns.add({
      'date': '2026-11-08',
      'fatigue': 4,
      'soreness': 2,
      'mood': 4,
      'stress': 2,
      'motivation': 5,
    });
    server.rideFeels['r1'] = {'rpe': 7, 'notes': 'A private note'};
    server.signInBrowser(owner);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.text('Club'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-athletes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('athlete-${athlete.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('power-curve-card')), findsOneWidget);
    expect(find.byKey(const Key('coach-wellbeing')), findsOneWidget);
    expect(find.textContaining('A private note'), findsNothing);
    expect(find.textContaining('RPE 7/10'), findsOneWidget);
  });

  testWidgets(
    'CoachAthletesScreen_ShouldReturnToTheClub_WhenTheSystemBackIsPressed',
    (tester) async {
      final owner = server.add(
        'owner@example.com',
        name: 'Owner Rina',
        clubRole: 'owner',
      );
      server.add('athlete@example.com', name: 'Athlete Luca');
      server.sharingChoices['rides'] = 'coaches';
      server.signInBrowser(owner);
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await startApp(tester, server.session(useCookies: true));
      await tester.tap(find.text('Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-athletes')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('open-athletes')), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Back goes to the club, not out of the app.
      expect(find.byKey(const Key('open-athletes')), findsOneWidget);
    },
  );

  testWidgets(
    'CoachAthleteScreen_ShouldHideNotesAndReadiness_WhenTheCoachHasAGrant',
    (tester) async {
      final owner = server.add(
        'owner@example.com',
        name: 'Owner Rina',
        clubRole: 'owner',
      );
      final athlete = server.add('athlete@example.com', name: 'Athlete Luca');
      server.sharingChoices['analytics'] = 'coaches';
      server.sharingChoices['wellbeing'] = 'coaches';
      server.wellbeingConsent = true;
      server.checkIns.add({
        'date': '2026-11-08',
        'fatigue': 4,
        'soreness': 2,
        'mood': 4,
        'stress': 2,
        'motivation': 5,
      });
      server.rideFeels['r1'] = {'rpe': 7, 'notes': 'A private note'};
      server.signInBrowser(owner);
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await startApp(tester, server.session(useCookies: true));
      await tester.tap(find.text('Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-athletes')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('athlete-${athlete.id}')));
      await tester.pumpAndSettle();

      // Scores and RPE arrive; the member's notes and their readiness never do.
      expect(find.byKey(const Key('coach-wellbeing')), findsOneWidget);
      expect(find.textContaining('A private note'), findsNothing);
      expect(find.byKey(const Key('readiness-card')), findsNothing);
      expect(find.byKey(const Key('readiness-score')), findsNothing);
    },
  );

  for (final width in [390.0, 600.0, 820.0, 1300.0]) {
    testWidgets(
      'CoachAthleteScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
        final owner = server.add(
          'owner@example.com',
          name: 'Owner Rina',
          clubRole: 'owner',
        );
        final athlete = server.add('athlete@example.com', name: 'Athlete Luca');
        server.sharingChoices['analytics'] = 'coaches';
        server.sharingChoices['wellbeing'] = 'coaches';
        server.wellbeingConsent = true;
        server.signInBrowser(owner);
        tester.view.physicalSize = Size(width, 2600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await startApp(tester, server.session(useCookies: true));
        await goTo(tester, '/club');
        await tester.ensureVisible(find.byKey(const Key('open-athletes')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('open-athletes')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('athlete-${athlete.id}')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('coach-wellbeing')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  /// Opens the Athletes page of a coach whose athlete shares everything the fake server can offer.
  Future<void> openAthletes(WidgetTester tester) async {
    server.signInBrowser(
      server.add('owner@example.com', name: 'Owner Rina', clubRole: 'owner'),
    );
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/club');
    await tester.ensureVisible(find.byKey(const Key('open-athletes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-athletes')));
    await tester.pumpAndSettle();
  }

  testWidgets('CoachAthletesScreen_ShouldListEveryoneInOneCard_WhenOpened', (
    tester,
  ) async {
    final athlete = server.add('athlete@example.com', name: 'Athlete Luca');
    server.sharingChoices['rides'] = 'coaches';
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await openAthletes(tester);

    // One list card holds every athlete, not a card each.
    expect(find.byKey(const Key('athletes-card')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('athletes-card')),
        matching: find.byKey(Key('athlete-${athlete.id}')),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'CoachAthletesScreen_ShouldBadgeWhatEachAthleteShares_WhenTheAthleteHasRides',
    (tester) async {
      final athlete = server.add('athlete@example.com', name: 'Athlete Luca');
      server.sharingChoices['rides'] = 'coaches';
      server.sharingChoices['analytics'] = 'coaches';
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await openAthletes(tester);

      // The sharing is a badge beside the name even when the line already says the last ride.
      final card = find.byKey(Key('athlete-${athlete.id}'));
      expect(
        find.descendant(of: card, matching: find.text('Rides')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('Training')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('Wellbeing')),
        findsNothing,
      );
    },
  );

  testWidgets('CoachRideScreen_ShouldShowTheNumbersInACard_WhenShared', (
    tester,
  ) async {
    final athlete = server.add('athlete@example.com', name: 'Athlete Luca');
    server.sharingChoices['rides'] = 'coaches';
    server.sharingChoices['routes'] = 'coaches';
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await openAthletes(tester);
    await tester.tap(find.byKey(Key('athlete-${athlete.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('coach-ride-r1')));
    await tester.pumpAndSettle();

    final numbers = find.byKey(const Key('coach-ride-numbers'));
    expect(numbers, findsOneWidget);
    expect(
      find.descendant(of: numbers, matching: find.text('Distance')),
      findsOneWidget,
    );
    // The map reads before the numbers it belongs to.
    expect(
      tester.getTopLeft(find.byKey(const Key('route-map'))).dy,
      lessThan(tester.getTopLeft(numbers).dy),
    );
  });

  testWidgets('CoachRideScreen_ShouldNameTheRideAndTheAthlete_WhenShared', (
    tester,
  ) async {
    final athlete = server.add('athlete@example.com', name: 'Athlete Luca');
    server.rides.first['title'] = 'Sunday long ride';
    server.sharingChoices['rides'] = 'coaches';
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await openAthletes(tester);
    await tester.tap(find.byKey(Key('athlete-${athlete.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('coach-ride-r1')));
    await tester.pumpAndSettle();

    // The ride's name is the title, the athlete the caption above it.
    expect(find.text('Sunday long ride'), findsOneWidget);
    expect(find.text('Athlete Luca'), findsWidgets);
  });

  for (final width in [390.0, 1300.0]) {
    testWidgets(
      'CoachAthletesScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
        final athlete = server.add('athlete@example.com', name: 'Athlete Luca');
        server.sharingChoices['rides'] = 'coaches';
        server.sharingChoices['analytics'] = 'coaches';
        server.sharingChoices['wellbeing'] = 'coaches';
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await openAthletes(tester);

        expect(find.byKey(Key('athlete-${athlete.id}')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'CoachRideScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
        final athlete = server.add('athlete@example.com', name: 'Athlete Luca');
        server.sharingChoices['rides'] = 'coaches';
        server.sharingChoices['analytics'] = 'coaches';
        server.sharingChoices['routes'] = 'coaches';
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await openAthletes(tester);
        await tester.tap(find.byKey(Key('athlete-${athlete.id}')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('coach-ride-r1')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('coach-ride-r1')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('coach-ride-numbers')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  /// Opens one athlete's page as a coach, with this week's plan on the fake server.
  Future<void> openAthletePlan(
    WidgetTester tester, {
    List<Map<String, Object?>>? sessions,
    double width = 1000,
  }) async {
    final athlete = server.add('athlete@example.com', name: 'Athlete Luca');
    server.sharingChoices['rides'] = 'coaches';
    server.coachPlan = coachPlanJson(
      start: DateTime(2026, 11, 23),
      sessions:
          sessions ??
          [
            coachPlanSessionJson(
              DateTime(2026, 11, 24),
              minutes: 60,
              state: 'done',
              riddenMinutes: 64,
              englishName: 'Easy ride',
              italianName: 'Giro tranquillo',
            ),
            coachPlanSessionJson(
              DateTime(2026, 11, 26),
              englishName: 'Strong and steady',
              italianName: 'Forte e costante',
            ),
            // The server hides "Ill or injured" without the wellbeing grant: the row reads Skipped alone.
            coachPlanSessionJson(
              DateTime(2026, 11, 27),
              minutes: 60,
              state: 'skipped',
              englishName: 'Easy spin',
              italianName: 'Giro defaticante',
            ),
          ],
    );
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await openAthletes(tester);
    await tester.tap(find.byKey(Key('athlete-${athlete.id}')));
    await tester.pumpAndSettle();
  }

  for (final width in [390.0, 600.0, 820.0, 1300.0]) {
    testWidgets(
      'CoachAthleteScreen_ShouldNotOverflow_WhenThePlanIsShownAtWidthIs${width.toInt()}',
      (tester) async {
        await openAthletePlan(tester, width: width);

        expect(find.byKey(const Key('coach-plan')), findsOneWidget);
        // Two cards across on a medium or a desktop window, one under the other on a phone.
        final plan = tester.getTopLeft(find.byKey(const Key('coach-plan'))).dy;
        final rides = tester
            .getTopLeft(find.byKey(const Key('coach-rides-card')))
            .dy;
        expect(plan == rides, width >= 600);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('CoachAthleteScreen_ShouldShowThePlan_WhenRidesAreShared', (
    tester,
  ) async {
    await openAthletePlan(tester);

    final card = find.byKey(const Key('coach-plan'));
    expect(card, findsOneWidget);
    expect(
      find.descendant(
        of: card,
        matching: find.text('Get fitter · 6 h a week · 1 of 3 done this week'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('Strong and steady')),
      findsOneWidget,
    );
    // Planned beside done: the time only, as the mock-up draws it.
    expect(
      find.descendant(
        of: card,
        matching: find.text('1 h planned · 1 h 04 ridden'),
      ),
      findsOneWidget,
    );
    // The reason was withheld (the illness case without the wellbeing grant): the day reads "Skipped" once, in its
    // badge, and keeps its length like every other day instead of saying the word twice.
    expect(
      find.descendant(of: card, matching: find.text('Skipped')),
      findsOneWidget,
    );
    expect(find.descendant(of: card, matching: find.text('1 h')), findsWidgets);
    // The score stays with the rider: the badge says Done and nothing more.
    expect(
      find.descendant(of: card, matching: find.textContaining('Done ·')),
      findsNothing,
    );
  });

  testWidgets(
    'CoachAthleteScreen_ShouldShowTheSkipReason_WhenTheRidesGrantCarriesIt',
    (tester) async {
      await openAthletePlan(
        tester,
        sessions: [
          coachPlanSessionJson(
            DateTime(2026, 11, 27),
            minutes: 60,
            state: 'skipped',
            skipReason: 'no_time',
            englishName: 'Easy spin',
          ),
        ],
      );

      // The reason the rides grant carries reads in the row, in the rider's words, as the mock-up writes it.
      expect(find.text('Skipped · no time'), findsOneWidget);
      expect(find.byKey(const Key('coach-plan')), findsOneWidget);
    },
  );

  testWidgets('CoachAthleteScreen_ShouldHideThePlan_WhenTheAthleteHasNone', (
    tester,
  ) async {
    final athlete = server.add('athlete@example.com', name: 'Athlete Luca');
    server.sharingChoices['rides'] = 'coaches';
    // No plan on the server: auto training is off, or the athlete never turned it on.
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await openAthletes(tester);
    await tester.tap(find.byKey(Key('athlete-${athlete.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('coach-plan')), findsNothing);
  });
}
