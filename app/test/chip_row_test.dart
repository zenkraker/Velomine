import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/theme.dart';
import 'package:velomine/core/widgets/chip_row.dart';

void main() {
  testWidgets('ChipRow_ShouldScrollTheChosenChipIntoView_WhenItIsOffTheEdge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: dayTheme(),
        home: Scaffold(
          body: ChipRow(
            selected: 5,
            chips: [
              for (var i = 0; i < 6; i++)
                ChoiceChip(
                  key: Key('chip-$i'),
                  label: Text('A fairly long label $i'),
                  selected: i == 5,
                  onSelected: (_) {},
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    final chosen = tester.getRect(find.byKey(const Key('chip-5')));
    expect(chosen.left, greaterThanOrEqualTo(0));
    expect(chosen.right, lessThanOrEqualTo(390));
  });
}
