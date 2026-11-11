import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/widgets/range_selector.dart';

void main() {
  testWidgets(
    'RangeSelector_ShouldNotOverflow_WhenWindowIsThreeHundredTwenty',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var days = 30;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => RangeSelector<int>(
                title: 'Training load',
                segmentKey: const Key('range'),
                segments: const [
                  ButtonSegment(value: 30, label: Text('30 days')),
                  ButtonSegment(value: 90, label: Text('90 days')),
                  ButtonSegment(value: 365, label: Text('1 year')),
                ],
                selected: days,
                onChanged: (value) => setState(() => days = value),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Training load'), findsOneWidget);

      await tester.tap(find.text('90 days'));
      await tester.pumpAndSettle();
      expect(days, 90);
    },
  );
}
