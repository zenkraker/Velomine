import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/theme.dart';
import 'package:velomine/core/widgets/area_chart.dart';
import 'package:velomine/core/widgets/bar_chart.dart';

Widget page(Widget child, {double width = 800}) => MaterialApp(
  theme: nightTheme(),
  home: MediaQuery(
    data: MediaQueryData(size: Size(width, 900)),
    child: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

Widget bars({List<double> values = const [10, 20, 5], double width = 800}) =>
    page(
      BarChart(
        values: values,
        labels: [for (var i = 0; i < values.length; i++) 'W$i'],
        format: (value) => '${value.round()} km',
        semanticLabel: 'Distance per week',
        emptyMessage: 'No rides yet.',
      ),
      width: width,
    );

void main() {
  testWidgets('BarChart_ShouldShowEmptyState_WhenValuesAreEmptyOrAllZero', (
    tester,
  ) async {
    await tester.pumpWidget(bars(values: const []));
    expect(find.text('No rides yet.'), findsOneWidget);

    await tester.pumpWidget(bars(values: const [0, 0, 0]));
    expect(find.text('No rides yet.'), findsOneWidget);
  });

  testWidgets('BarChart_ShouldNotOverflow_WhenWidthIs390_600_820And1300', (
    tester,
  ) async {
    for (final width in [390.0, 600.0, 820.0, 1300.0]) {
      await tester.pumpWidget(
        bars(values: const [101, 4, 33, 12, 8, 60], width: width),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
  });

  testWidgets('BarChart_ShouldExposeSemanticLabel_WhenShown', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(bars());
    expect(find.bySemanticsLabel('Distance per week'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('AreaChart_ShouldShowEmptyState_WhenNoValues', (tester) async {
    await tester.pumpWidget(
      page(
        AreaChart(
          values: const [],
          labels: const [],
          format: (value) => value.toStringAsFixed(2),
          semanticLabel: 'Efficiency',
          emptyMessage: 'Needs steady rides.',
        ),
      ),
    );
    expect(find.text('Needs steady rides.'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('AreaChart_ShouldDrawDotOnly_WhenOneValue', (tester) async {
    await tester.pumpWidget(
      page(
        AreaChart(
          key: const Key('area'),
          paintKey: const Key('area-paint'),
          values: const [1.32],
          labels: const ['Oct 26'],
          format: (value) => value.toStringAsFixed(2),
          semanticLabel: 'Efficiency',
          emptyMessage: 'Needs steady rides.',
        ),
      ),
    );
    expect(find.byKey(const Key('area-paint')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
