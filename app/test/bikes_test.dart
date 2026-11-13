import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
  });

  Future<void> openBikes(WidgetTester tester) async {
    // Tall enough that the forms and the parts list are on screen.
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.text('Bikes'));
    await tester.pumpAndSettle();
  }

  /// Opens the bike's actions menu and picks one of its rare jobs.
  Future<void> chooseBikeAction(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(const Key('bike-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  Future<void> addBike(WidgetTester tester, String name) async {
    await tester.tap(find.byKey(const Key('add-bike')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('bike-name')), name);
    await tester.enterText(find.byKey(const Key('bike-initial')), '1200');
    await tester.tap(find.byKey(const Key('bike-save')));
    await tester.pumpAndSettle();
  }

  testWidgets('BikesScreen_ShouldExplainBikes_WhenThereAreNone', (
    tester,
  ) async {
    await openBikes(tester);

    expect(find.byKey(const Key('no-bikes')), findsOneWidget);
  });

  testWidgets('BikesScreen_ShouldOpenNewBikeAsDefault_WhenBikeIsAdded', (
    tester,
  ) async {
    await openBikes(tester);
    await addBike(tester, 'Climber');

    expect(find.text('Climber'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    expect(find.text('1200 km'), findsOneWidget);
    expect(server.bikes.single['initialDistanceM'], 1200000.0);
    expect(server.bikes.single['wheelCircumferenceMm'], 2105);
    expect(find.byKey(const Key('no-parts')), findsOneWidget);
  });

  testWidgets('BikesScreen_ShouldRejectBike_WhenNameEmpty', (tester) async {
    await openBikes(tester);
    await tester.tap(find.byKey(const Key('add-bike')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bike-save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('form-error')), findsOneWidget);
    expect(server.bikes, isEmpty);
  });

  testWidgets('BikeForm_ShouldOpenAsASheet_WhenAddingABike', (tester) async {
    await openBikes(tester);
    await tester.tap(find.byKey(const Key('add-bike')));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byKey(const Key('bike-name')), findsOneWidget);
    expect(find.byKey(const Key('bike-save')), findsOneWidget);
  });

  testWidgets('BikesScreen_ShouldFillWheelSize_WhenPicked', (tester) async {
    await openBikes(tester);
    await tester.tap(find.byKey(const Key('add-bike')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('bike-name')), 'Gravel');
    await tester.tap(find.text('700×40c gravel · 2200'));
    await tester.tap(find.byKey(const Key('bike-save')));
    await tester.pumpAndSettle();

    expect(server.bikes.single['wheelCircumferenceMm'], 2200);
  });

  testWidgets('BikeDetailScreen_ShouldAddPartAndShowWear_WhenAdded', (
    tester,
  ) async {
    await openBikes(tester);
    await addBike(tester, 'Climber');

    await tester.tap(find.byKey(const Key('add-part')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('part-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chain (Drivetrain)').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('part-km')))
          .controller!
          .text,
      '4000',
    ); // the typical limit is offered
    await tester.tap(find.byKey(const Key('part-save')));
    await tester.pumpAndSettle();

    final part = server.parts['bike-1']!.single;
    expect(part['type'], 'chain');
    expect(part['expectedDistanceM'], 4000000.0);
    expect(find.text('Chain'), findsOneWidget);

    // The server computes the wear; the screen shows it.
    part
      ..['usedDistanceM'] = 3400000.0
      ..['wearPercent'] = 85
      ..['status'] = 'soon';
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bike-bike-1')));
    await tester.pumpAndSettle();

    expect(find.text('Getting worn'), findsOneWidget);
    expect(find.text('3400 of 4000 km'), findsOneWidget);
  });

  testWidgets('BikeDetailScreen_ShouldRetireOldPartAndFitNewOne_WhenReplaced', (
    tester,
  ) async {
    server.bikes.add({
      'id': 'bike-1',
      'name': 'Climber',
      'kind': 'road',
      'wheelCircumferenceMm': 2105,
      'initialDistanceM': 0.0,
      'isDefault': true,
    });
    server.parts['bike-1'] = [
      {
        'id': 'part-1',
        'type': 'chain',
        'typeName': 'Chain',
        'brand': null,
        'model': null,
        'installedOn': '2026-01-01',
        'removedOn': null,
        'expectedDistanceM': 4000000.0,
        'expectedHours': null,
        'expectedMonths': null,
        'usedDistanceM': 4200000.0,
        'usedHours': 150.0,
        'usedMonths': 10.0,
        'wearPercent': 105,
        'status': 'worn',
      },
    ];
    await openBikes(tester);
    await tester.tap(find.byKey(const Key('bike-bike-1')));
    await tester.pumpAndSettle();
    expect(find.text('Replace it'), findsOneWidget);

    await tester.tap(find.byKey(const Key('replace-part-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('part-save')));
    await tester.pumpAndSettle();

    final list = server.parts['bike-1']!;
    expect(list, hasLength(2));
    expect(list[0]['removedOn'], isNotNull);
    expect(list[0]['status'], 'retired');
    expect(list[1]['removedOn'], isNull);
    expect(list[1]['expectedDistanceM'], 4000000.0); // same limit as before
    expect(find.text('Replaced parts'), findsOneWidget);
  });

  testWidgets('BikeDetailScreen_ShouldDefaultArchiveAndDelete_WhenUsed', (
    tester,
  ) async {
    await openBikes(tester);
    await addBike(tester, 'First');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await addBike(tester, 'Second');
    await tester.tap(find.byKey(const Key('bike-actions')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('make-default')), findsOneWidget);
    await tester.tap(find.byKey(const Key('make-default')));
    await tester.pumpAndSettle();
    expect(server.bikes.last['isDefault'], isTrue);

    await chooseBikeAction(tester, 'toggle-archive');
    expect(find.text('Archived'), findsOneWidget);
    expect(server.bikes.last['isActive'], isFalse);

    await chooseBikeAction(tester, 'delete-bike');
    await tester.tap(find.byKey(const Key('confirm-delete-bike')));
    await tester.pumpAndSettle();

    expect(server.bikes.map((b) => b['name']), ['First']);
    expect(find.byKey(const Key('bike-bike-1')), findsOneWidget);
  });

  testWidgets('RideDetailScreen_ShouldChangeBike_WhenAnotherPicked', (
    tester,
  ) async {
    server.bikes.addAll([
      {
        'id': 'b1',
        'name': 'Climber',
        'kind': 'road',
        'wheelCircumferenceMm': 2105,
        'initialDistanceM': 0.0,
        'isDefault': true,
      },
      {
        'id': 'b2',
        'name': 'Gravel',
        'kind': 'gravel',
        'wheelCircumferenceMm': 2200,
        'initialDistanceM': 0.0,
        'isDefault': false,
      },
    ]);
    server.rides.add(
      rideJson('r1', 'ready', distanceM: 20000, movingS: 3000, bikeId: 'b1'),
    );
    server.streams['r1'] = streamsJson();
    await startApp(tester, server.session(useCookies: true));
    await tester.tap(find.byKey(const Key('ride-r1')));
    await tester.pumpAndSettle();

    expect(
      find.text('Climber'),
      findsOneWidget,
    ); // the dropdown's current value

    // The map is now above the numbers, so the bike picker sits further down the page.
    await tester.scrollUntilVisible(
      find.byType(DropdownButtonFormField<String?>),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gravel').last);
    await tester.pumpAndSettle();

    expect(server.rides.first['bikeId'], 'b2');
    expect(find.text('Gravel'), findsOneWidget);
  });

  testWidgets('BikeDetailScreen_ShouldShowNotFound_WhenBikeIsNotYours', (
    tester,
  ) async {
    await startApp(tester, server.session(useCookies: true));
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/bikes/nope');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('not-found')), findsOneWidget);
  });

  testWidgets('BikesScreen_ShouldSaveTheModelYearAndSize_WhenFilled', (
    tester,
  ) async {
    await openBikes(tester);
    await tester.tap(find.byKey(const Key('add-bike')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('bike-name')), 'Climber');
    await tester.enterText(find.byKey(const Key('bike-brand')), 'Trek');
    await tester.enterText(find.byKey(const Key('bike-model')), 'Domane');
    await tester.enterText(find.byKey(const Key('bike-year')), '2023');
    await tester.enterText(find.byKey(const Key('bike-spec')), 'SL 7');
    await tester.enterText(find.byKey(const Key('bike-size')), '56');
    await tester.tap(find.byKey(const Key('bike-save')));
    await tester.pumpAndSettle();

    final bike = server.bikes.single;
    expect(bike['brand'], 'Trek');
    expect(bike['model'], 'Domane');
    expect(bike['modelYear'], 2023);
    expect(bike['buildSpec'], 'SL 7');
    expect(bike['frameSize'], '56');
  });

  testWidgets('BikeDetailScreen_ShouldKeepAPartCustom_WhenCustomIsChecked', (
    tester,
  ) async {
    await openBikes(tester);
    await addBike(tester, 'Climber');
    await tester.tap(find.byKey(const Key('add-part')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('part-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chain (Drivetrain)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('part-custom')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('part-save')));
    await tester.pumpAndSettle();

    final part = server.parts['bike-1']!.single;
    expect(part['isCustom'], isTrue);
    expect(find.text('Custom'), findsOneWidget);
  });

  testWidgets('BikeDetailScreen_ShouldSaveTheBuildAsATemplate_WhenNamed', (
    tester,
  ) async {
    await openBikes(tester);
    await addBike(tester, 'Climber');
    await tester.tap(find.byKey(const Key('add-part')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('part-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chain (Drivetrain)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('part-save')));
    await tester.pumpAndSettle();

    await chooseBikeAction(tester, 'save-template');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('template-name')),
      'Gravel build',
    );
    await tester.tap(find.byKey(const Key('template-save')));
    await tester.pumpAndSettle();

    expect(server.templates.single['name'], 'Gravel build');
    expect((server.templates.single['parts'] as List), hasLength(1));
    expect((server.templates.single['parts'] as List).single['type'], 'chain');
  });

  testWidgets(
    'BikeDetailScreen_ShouldFillOnlyMissingParts_WhenATemplateIsApplied',
    (tester) async {
      server.templates.add({
        'id': 'template-1',
        'name': 'Gravel build',
        'createdAt': '2026-11-09T08:00:00Z',
        'parts': [
          {
            'id': 'tplpart-1',
            'type': 'chain',
            'typeName': 'Chain',
            'brand': 'Shimano',
            'model': 'CN-M8100',
            'mpn': 'CN-M8100',
            'gtin': null,
            'expectedDistanceM': 4000000.0,
            'expectedHours': null,
            'expectedMonths': null,
          },
          {
            'id': 'tplpart-2',
            'type': 'cassette',
            'typeName': 'Cassette',
            'brand': 'Shimano',
            'model': 'CS-M8100',
            'mpn': 'CS-M8100',
            'gtin': null,
            'expectedDistanceM': 12000000.0,
            'expectedHours': null,
            'expectedMonths': null,
          },
        ],
      });
      await openBikes(tester);
      await addBike(tester, 'Climber');
      await tester.tap(find.byKey(const Key('add-part')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('part-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chain (Drivetrain)').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('part-save')));
      await tester.pumpAndSettle();

      await chooseBikeAction(tester, 'apply-template');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('template-template-1')));
      await tester.pumpAndSettle();

      final parts = server.parts['bike-1']!;
      expect(parts, hasLength(2));
      expect(parts.where((p) => p['type'] == 'chain'), hasLength(1));
      expect(
        parts.singleWhere((p) => p['type'] == 'cassette')['mpn'],
        'CS-M8100',
      );
    },
  );

  testWidgets('BikeDetailScreen_ShouldExplainTemplates_WhenThereAreNone', (
    tester,
  ) async {
    await openBikes(tester);
    await addBike(tester, 'Climber');

    await chooseBikeAction(tester, 'apply-template');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('no-templates')), findsOneWidget);
  });

  testWidgets('BikeDetailScreen_ShouldFillThePart_WhenAKnownPartIsPicked', (
    tester,
  ) async {
    server.partCatalogue.add({
      'id': 'part-known',
      'type': 'chain',
      'brand': 'Shimano',
      'model': 'Ultegra CN-M8100',
      'mpn': 'CN-M8100',
      'gtin': null,
      'confirmations': 2,
    });
    await openBikes(tester);
    await addBike(tester, 'Climber');

    await tester.tap(find.byKey(const Key('add-part')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('part-search')), 'Shimano');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shimano Ultegra CN-M8100').last);
    await tester.pumpAndSettle();

    String field(String key) =>
        tester.widget<TextField>(find.byKey(Key(key))).controller!.text;
    expect(field('part-brand'), 'Shimano');
    expect(field('part-model'), 'Ultegra CN-M8100');
    expect(field('part-mpn'), 'CN-M8100');

    await tester.tap(find.byKey(const Key('part-save')));
    await tester.pumpAndSettle();

    final part = server.parts['bike-1']!.single;
    expect(part['type'], 'chain');
    expect(part['mpn'], 'CN-M8100');
  });
}
