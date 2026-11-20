import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/theme.dart';
import 'package:velomine/core/widgets/segmented_control.dart';

Widget page(Widget child) => MaterialApp(
  theme: nightTheme(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('SegmentedControl_ShouldKeepButtonKey_WhenWrapped', (
    tester,
  ) async {
    await tester.pumpWidget(
      page(
        SegmentedControl<String>(
          buttonKey: const Key('range'),
          segments: const [
            ButtonSegment(value: 'week', label: Text('Weeks')),
            ButtonSegment(value: 'month', label: Text('Months')),
          ],
          selected: 'week',
          onChanged: (_) {},
        ),
      ),
    );

    expect(
      tester.widget<SegmentedButton<String>>(find.byKey(const Key('range'))),
      isA<SegmentedButton<String>>(),
    );
    expect(find.byType(SegmentedButton<String>), findsOneWidget);
  });

  testWidgets('SegmentedControl_ShouldCallOnChanged_WhenSegmentIsTapped', (
    tester,
  ) async {
    String? chosen;
    await tester.pumpWidget(
      page(
        SegmentedControl<String>(
          buttonKey: const Key('range'),
          segments: const [
            ButtonSegment(value: 'week', label: Text('Weeks')),
            ButtonSegment(value: 'month', label: Text('Months')),
          ],
          selected: 'week',
          onChanged: (value) => chosen = value,
        ),
      ),
    );

    await tester.tap(find.text('Months'));
    await tester.pumpAndSettle();
    expect(chosen, 'month');
  });
}
