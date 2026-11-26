import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/theme.dart';
import 'package:velomine/core/tokens.dart';
import 'package:velomine/core/widgets/fact_grid.dart';

Future<void> pumpGrid(WidgetTester tester, double width) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: dayTheme(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: const FactGrid(
              facts: [
                ('Distance', '2.7 km'),
                ('Moving time', '20 min'),
                ('Average speed', '8.2 km/h'),
                ('Average heart rate', '135 bpm'),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('FactGrid_ShouldKeepEachNumberOnOneLine_WhenTheCardIsPhoneWide', (
    tester,
  ) async {
    await pumpGrid(tester, 326);
    for (final value in ['2.7 km', '20 min', '8.2 km/h', '135 bpm']) {
      expect(tester.getSize(find.text(value)).height, lessThan(24));
    }
  });

  testWidgets(
    'FactGrid_ShouldFillColumnsOfAtLeastTheMinimum_WhenTheCardIsWide',
    (tester) async {
      await pumpGrid(tester, 700);
      final first = tester.getTopLeft(find.text('Distance'));
      final last = tester.getTopLeft(find.text('Average heart rate'));
      // 700 dp holds four columns of 110 dp and more, so all four facts share one row.
      expect(last.dy, first.dy);
      expect(
        tester.getSize(find.byType(FactGrid)).width,
        greaterThanOrEqualTo(4 * AppFacts.minColumn),
      );
    },
  );

  testWidgets('FactGrid_ShouldWrapToTwoRows_WhenTheCardIsPhoneWide', (
    tester,
  ) async {
    await pumpGrid(tester, 326);
    final first = tester.getTopLeft(find.text('Distance'));
    final last = tester.getTopLeft(find.text('Average heart rate'));
    expect(last.dy, greaterThan(first.dy));
  });
}
