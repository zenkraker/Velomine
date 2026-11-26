import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/theme.dart';
import 'package:velomine/core/widgets/chart_chrome.dart';

void main() {
  testWidgets(
    'ChartHeader_ShouldEndTheReadoutAtTheRowsEdge_WhenTheTitleIsShort',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: dayTheme(),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 600,
                child: ChartHeader(
                  title: 'Elevation',
                  color: Colors.grey,
                  readout: 'avg 250 m · max 260 m',
                ),
              ),
            ),
          ),
        ),
      );
      final row = tester.getRect(find.byType(ChartHeader));
      final readout = tester.getRect(find.text('avg 250 m · max 260 m'));
      expect(readout.right, closeTo(row.right, 1));
      // One line: the readout does not break at the unit.
      expect(readout.height, lessThan(20));
    },
  );
}
