import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
  });

  /// Scrolls the page until [finder] is on screen.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  /// Profile, at the width where its cards fit, with the auto-training switch in view.
  Future<void> openProfile(WidgetTester tester, {double width = 700}) async {
    tester.view.physicalSize = Size(width, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await goTo(tester, '/profile');
    await reveal(tester, find.byKey(const Key('profile-auto-training')));
  }

  /// The setup form as the switch opens it.
  Future<void> openSetup(WidgetTester tester, {double width = 700}) async {
    await openProfile(tester, width: width);
    await tester.tap(find.byKey(const Key('profile-auto-training')));
    await tester.pumpAndSettle();
  }

  Future<void> chooseDays(WidgetTester tester) async {
    for (final day in ['tuesday', 'thursday', 'sunday']) {
      await reveal(tester, find.byKey(Key('training-day-$day')));
      await tester.tap(find.byKey(Key('training-day-$day')));
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
    'ProfileScreen_ShouldShowTheAutoTrainingSwitchAndItsSentence_WhenTheOperatorAllowsIt',
    (tester) async {
      await openProfile(tester);

      expect(find.byKey(const Key('profile-auto-training')), findsOneWidget);
      expect(
        find.textContaining('Velomine plans your week from your rides.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('training-feedback')), findsOneWidget);
    },
  );

  testWidgets(
    'ProfileScreen_ShouldHideTheAutoTrainingSwitch_WhenTheOperatorTurnsItOff',
    (tester) async {
      server.autoTrainingEnabled = false;

      await startApp(tester, server.session(useCookies: true));
      await goTo(tester, '/profile');
      await reveal(tester, find.byKey(const Key('profile-ride-privacy')));

      expect(find.byKey(const Key('profile-auto-training')), findsNothing);
    },
  );

  testWidgets(
    'TrainingSetupScreen_ShouldSelectTheSuggestedGoalWithItsReason_WhenTheRiderOpensIt',
    (tester) async {
      server.suggestedTrainingGoal = 'aerobic';
      server.trainingSuggestionReason = 'not_enough_riding';

      await openSetup(tester);

      expect(find.text('Set up auto training'), findsOneWidget);
      expect(find.text('Suggested'), findsOneWidget);
      expect(
        find.textContaining('We have not seen enough of your riding yet'),
        findsOneWidget,
      );
      // The suggested goal is the one on the form.
      final radio = tester.widget<RadioListTile<String>>(
        find.byKey(const Key('training-goal-aerobic')),
      );
      expect(radio.value, 'aerobic');
    },
  );

  testWidgets(
    'TrainingSetupScreen_ShouldPutTheIntroSentenceInTheHeader_WhenTheRiderOpensIt',
    (tester) async {
      await openSetup(tester);

      // The sub-line carries the sentence the body used to hold, with no copy left under the title.
      expect(
        find.descendant(
          of: find.byType(SliverPersistentHeader),
          matching: find.textContaining(
            'Velomine plans your week from your rides. It is new: tell us what feels wrong.',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Velomine plans your week from your rides.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'TrainingSetupScreen_ShouldNotOfferAnAddEventAction_WhenTheRiderHasNoEvent',
    (tester) async {
      await openSetup(tester);
      await reveal(tester, find.byKey(const Key('training-goal-event')));

      // No picker exists to open, so the row states nothing rather than offering a button that does nothing.
      expect(find.text('Add an event'), findsNothing);
      // The goal itself is still one the rider can pick, and it saves.
      await tester.tap(find.byKey(const Key('training-goal-event')));
      await tester.pumpAndSettle();
      await chooseDays(tester);
      await reveal(tester, find.byKey(const Key('training-hours')));
      await tester.enterText(find.byKey(const Key('training-hours')), '6');
      await tester.enterText(
        find.byKey(const Key('training-birth-year')),
        '1988',
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('training-start')));
      await tester.tap(find.byKey(const Key('training-start')));
      await tester.pumpAndSettle();

      expect(server.lastTrainingSave!['goal'], 'event');
    },
  );

  testWidgets(
    'TrainingSetupScreen_ShouldKeepStartDisabled_WhenTheYearOfBirthIsMissing',
    (tester) async {
      await openSetup(tester);
      await reveal(tester, find.byKey(const Key('training-start')));
      // Start does nothing while the year of birth is missing: the form is still the one on screen.
      await tester.tap(find.byKey(const Key('training-start')));
      await tester.pumpAndSettle();

      expect(server.lastTrainingSave, isNull);
      expect(find.text('Set up auto training'), findsOneWidget);
    },
  );

  testWidgets(
    'TrainingSetupScreen_ShouldSaveTheSetupAndShowTheDestination_WhenTheRiderStarts',
    (tester) async {
      await openSetup(tester);
      await chooseDays(tester);
      await reveal(tester, find.byKey(const Key('training-hours')));
      await tester.enterText(find.byKey(const Key('training-hours')), '6');
      await tester.enterText(
        find.byKey(const Key('training-birth-year')),
        '1988',
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('training-start')));
      await tester.tap(find.byKey(const Key('training-start')));
      await tester.pumpAndSettle();

      final saved = server.lastTrainingSave!;
      expect(saved['goal'], 'fitter');
      expect(saved['days'], ['tuesday', 'thursday', 'sunday']);
      expect(saved['hoursPerWeek'], 6);
      expect(saved['birthYear'], 1988);
      // The plan is on, so Training is a destination now (the rail at this width).
      expect(find.byKey(const Key('rail-training')), findsOneWidget);
    },
  );

  testWidgets(
    'TrainingSetupScreen_ShouldSaveATypedMaximumOfTwoHundredAndTwentyFive_WhenTheRiderTypesIt',
    (tester) async {
      // The account keeps 120-230 (HeartRates.MaxMax), so the setup must accept the same range.
      await openSetup(tester);
      await chooseDays(tester);
      await reveal(tester, find.byKey(const Key('training-hours')));
      await tester.enterText(find.byKey(const Key('training-hours')), '6');
      await tester.enterText(
        find.byKey(const Key('training-birth-year')),
        '1988',
      );
      await tester.tap(find.byKey(const Key('training-heart-unknown')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('training-max-heart-rate')));
      await tester.enterText(
        find.byKey(const Key('training-max-heart-rate')),
        '225',
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('training-start')));
      await tester.tap(find.byKey(const Key('training-start')));
      await tester.pumpAndSettle();

      expect(server.lastTrainingSave!['maxHeartRate'], 225);
      expect(server.trainingMaxHeartRate, 225);
    },
  );

  testWidgets(
    'TrainingScreen_ShouldNameTheMembersFirstDayOfTheWeek_WhenThePlanHasNotStarted',
    (tester) async {
      server.trainingPlan = {
        'on': true,
        'goal': 'fitter',
        'days': ['tuesday', 'sunday'],
        'hoursPerWeek': 6,
        'longRideDay': null,
        'birthYear': 1988,
      };
      server.profiles['rider@example.com'] = {
        'displayName': 'Test Rider',
        'birthYear': 1988,
        'firstDayOfWeek': 'sunday',
      };

      tester.view.physicalSize = const Size(700, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));
      await goTo(tester, '/training');

      expect(find.text('Your plan starts Sunday.'), findsOneWidget);
    },
  );

  testWidgets(
    'TrainingScreen_ShouldStayOnAColdStart_WhenThePlanHasNotLoadedYet',
    (tester) async {
      server.trainingPlan = {
        'on': true,
        'goal': 'fitter',
        'days': ['tuesday'],
        'hoursPerWeek': 6,
        'longRideDay': null,
        'birthYear': 1988,
      };
      final gate = server.delayNext('/api/v1/training/plan');

      tester.view.physicalSize = const Size(700, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late GoRouter router;
      await startApp(
        tester,
        server.session(useCookies: true),
        onRouter: (created) => router = created,
      );
      // A deep link opened before the plan answered: the address must not be replaced by /rides.
      router.go('/training');
      await tester.pumpAndSettle();
      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('training-plan-starts')), findsOneWidget);
      expect(find.byKey(const Key('training-goal')), findsOneWidget);
    },
  );

  testWidgets(
    'TrainingSetupScreen_ShouldRefuseADaylessSetup_WhenTheRiderStartsWithoutOne',
    (tester) async {
      await openSetup(tester);
      await reveal(tester, find.byKey(const Key('training-hours')));
      await tester.enterText(find.byKey(const Key('training-hours')), '6');
      await tester.enterText(
        find.byKey(const Key('training-birth-year')),
        '1988',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('training-start')));
      await tester.pumpAndSettle();

      expect(
        find.text('Choose at least one day you can ride.'),
        findsOneWidget,
      );
      expect(server.lastTrainingSave, isNull);
    },
  );

  testWidgets(
    'TrainingSetupScreen_ShouldOpenPrefilled_WhenTheRiderChangesTheSetup',
    (tester) async {
      server.trainingPlan = {
        'on': true,
        'goal': 'faster',
        'days': ['tuesday', 'sunday'],
        'hoursPerWeek': 8,
        'longRideDay': 'sunday',
        'birthYear': 1988,
      };
      server.trainingMaxHeartRate = 181;
      server.trainingMaxHeartRateSource = 'manual';

      tester.view.physicalSize = const Size(700, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));
      await goTo(tester, '/training');
      await tester.tap(find.byKey(const Key('training-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('training-change-setup')));
      await tester.pumpAndSettle();

      final hours = tester.widget<TextField>(
        find.byKey(const Key('training-hours')),
      );
      expect(hours.controller!.text, '8');
      final heart = tester.widget<TextField>(
        find.byKey(const Key('training-max-heart-rate')),
      );
      expect(heart.controller!.text, '181');
      // A day that was saved is on.
      final tuesday = tester.widget<FilterChip>(
        find.byKey(const Key('training-day-tuesday')),
      );
      expect(tuesday.selected, isTrue);
    },
  );

  testWidgets(
    'TrainingScreen_ShouldTurnAutoTrainingOff_WhenTheRiderConfirmsIt',
    (tester) async {
      server.trainingPlan = {
        'on': true,
        'goal': 'fitter',
        'days': ['tuesday', 'thursday'],
        'hoursPerWeek': 6,
        'longRideDay': null,
        'birthYear': 1988,
      };
      tester.view.physicalSize = const Size(700, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await startApp(tester, server.session(useCookies: true));
      await goTo(tester, '/training');
      await tester.tap(find.byKey(const Key('training-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('training-turn-off')));
      await tester.pumpAndSettle();

      expect(find.text('Turn off auto training?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('training-off-confirm')));
      await tester.pumpAndSettle();

      expect(server.trainingPlan!['on'], isFalse);
      // The destination goes with it.
      expect(find.byKey(const Key('rail-training')), findsNothing);
    },
  );

  testWidgets(
    'HomeShell_ShouldShowTheTrainingDestinationAtEveryWidth_WhenAutoTrainingIsOn',
    (tester) async {
      server.trainingPlan = {
        'on': true,
        'goal': 'fitter',
        'days': ['tuesday'],
        'hoursPerWeek': 6,
        'longRideDay': null,
        'birthYear': 1988,
      };

      for (final (width, key) in [
        (390.0, 'tab-training'),
        (700.0, 'rail-training'),
        (1300.0, 'sidebar-training'),
      ]) {
        tester.view.physicalSize = Size(width, 2000);
        tester.view.devicePixelRatio = 1;
        await startApp(tester, server.session(useCookies: true));
        await goTo(tester, '/training');
        await tester.pumpAndSettle();

        expect(find.byKey(Key(key)), findsOneWidget, reason: 'at $width dp');
        expect(find.text('Training'), findsWidgets);
      }
      addTearDown(tester.view.reset);
    },
  );

  for (final width in [390.0, 600.0, 820.0, 1300.0]) {
    testWidgets(
      'TrainingSetupScreen_ShouldNotOverflow_WhenWidthIs${width.toInt()}',
      (tester) async {
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await startApp(tester, server.session(useCookies: true));
        await goTo(tester, '/training/setup');
        await tester.pumpAndSettle();

        expect(find.text('Set up auto training'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
