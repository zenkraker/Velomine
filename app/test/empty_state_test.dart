import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/widgets/empty_state.dart';

void main() {
  testWidgets('EmptyState_ShouldReadAsOneLine_WhenTheListIsEmptyOnAPhone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            key: Key('empty'),
            message: 'Nothing is here yet. Record a ride or import one.',
            icon: Icons.directions_bike,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('empty')), findsOneWidget);
    expect(find.byIcon(Icons.directions_bike), findsOneWidget);
  });
}
