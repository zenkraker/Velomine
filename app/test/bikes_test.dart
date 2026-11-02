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

  Future<void> addBike(WidgetTester tester, String name) async {
    await tester.tap(find.byKey(const Key('add-bike')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('bike-name')), name);
    await tester.enterText(find.byKey(const Key('bike-initial')), '1200');
    await tester.tap(find.byKey(const Key('bike-save')));
    await tester.pumpAndSettle();
  }

  testWidgets('with no bikes the screen explains what they are for', (
    tester,
  ) async {
    await openBikes(tester);

    expect(find.byKey(const Key('no-bikes')), findsOneWidget);
  });

  testWidgets('adding a bike opens it, and the first one is the default', (
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

  testWidgets('a bike with a name that is empty is not sent', (tester) async {
    await openBikes(tester);
    await tester.tap(find.byKey(const Key('add-bike')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bike-save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('form-error')), findsOneWidget);
    expect(server.bikes, isEmpty);
  });

  testWidgets('a wheel size chip fills in the circumference', (tester) async {
    await openBikes(tester);
    await tester.tap(find.byKey(const Key('add-bike')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('bike-name')), 'Gravel');
    await tester.tap(find.text('700×40c gravel · 2200'));
    await tester.tap(find.byKey(const Key('bike-save')));
    await tester.pumpAndSettle();

    expect(server.bikes.single['wheelCircumferenceMm'], 2200);
  });

  testWidgets('a part is added with its typical limit, and shows its wear', (
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
    await tester.tap(find.byKey(const Key('back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bike-bike-1')));
    await tester.pumpAndSettle();

    expect(find.text('Getting worn'), findsOneWidget);
    expect(find.text('3400 of 4000 km'), findsOneWidget);
  });

  testWidgets('replacing a part retires the old one and fits a new one', (
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

  testWidgets('a bike can be made the default, archived and deleted', (
    tester,
  ) async {
    await openBikes(tester);
    await addBike(tester, 'First');
    await tester.tap(find.byKey(const Key('back')));
    await tester.pumpAndSettle();
    await addBike(tester, 'Second');
    expect(find.byKey(const Key('make-default')), findsOneWidget);

    await tester.tap(find.byKey(const Key('make-default')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('make-default')), findsNothing);
    expect(server.bikes.last['isDefault'], isTrue);

    await tester.tap(find.byKey(const Key('toggle-archive')));
    await tester.pumpAndSettle();
    expect(find.text('Archived'), findsOneWidget);
    expect(server.bikes.last['isActive'], isFalse);

    await tester.tap(find.byKey(const Key('delete-bike')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-bike')));
    await tester.pumpAndSettle();

    expect(server.bikes.map((b) => b['name']), ['First']);
    expect(find.byKey(const Key('bike-bike-1')), findsOneWidget);
  });

  testWidgets('a ride says which bike was ridden, and it can be changed', (
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
    await tester.tap(find.byType(Card).first);
    await tester.pumpAndSettle();

    expect(
      find.text('Climber'),
      findsOneWidget,
    ); // the dropdown's current value

    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gravel').last);
    await tester.pumpAndSettle();

    expect(server.rides.first['bikeId'], 'b2');
    expect(find.text('Gravel'), findsOneWidget);
  });

  testWidgets('a bike that is not yours says so', (tester) async {
    await startApp(tester, server.session(useCookies: true));
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/bikes/nope');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('not-found')), findsOneWidget);
  });
}
