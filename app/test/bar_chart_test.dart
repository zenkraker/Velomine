import 'package:fl_chart/fl_chart.dart' show LineChart;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/theme.dart';
import 'package:velomine/core/widgets/area_chart.dart';
import 'package:velomine/core/widgets/bar_chart.dart';
import 'package:velomine/core/widgets/line_chart.dart';

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
        currentIndex: values.length - 1,
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

  testWidgets('AreaChart_ShouldNotOverflow_WhenWidthIs390_600_820And1300', (
    tester,
  ) async {
    for (final width in [390.0, 600.0, 820.0, 1300.0]) {
      await tester.pumpWidget(
        page(
          AreaChart(
            values: const [1.32, 1.28, 1.4, 1.36, 1.31],
            labels: const ['Oct 5', 'Oct 12', 'Oct 19', 'Oct 26', 'Nov 2'],
            format: (value) => value.toStringAsFixed(2),
            semanticLabel: 'Efficiency',
            emptyMessage: 'Needs steady rides.',
          ),
          width: width,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
  });

  testWidgets('AreaChart_ShouldFillTheAreaAt35Percent_WhenItDrawsTheLine', (
    tester,
  ) async {
    await tester.pumpWidget(
      page(
        AreaChart(
          values: const [10, 14, 18],
          labels: const ['Nov 1', 'Nov 2', 'Nov 3'],
          format: (value) => value.round().toString(),
          semanticLabel: 'Efficiency',
          emptyMessage: 'Needs steady rides.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The design's fill: the line's colour at 35 % under the line, gone at the base.
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final fill = chart.data.lineBarsData.single.belowBarData;
    expect(fill.show, isTrue);
    final colors = (fill.gradient! as LinearGradient).colors;
    expect(colors.first.a, closeTo(0.35, 0.01));
    expect(colors.last.a, 0);
  });

  testWidgets('FitnessChart_ShouldShowEmptyState_WhenFewerThanTwoDays', (
    tester,
  ) async {
    await tester.pumpWidget(
      page(
        const FitnessChart(
          labels: ['Nov 2'],
          fitness: [18],
          fatigue: [22],
          form: [-4],
          emptyMessage: 'No training load in this range.',
        ),
      ),
    );
    expect(find.text('No training load in this range.'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('FitnessChart_ShouldNotOverflow_WhenWidthIs390_600_820And1300', (
    tester,
  ) async {
    for (final width in [390.0, 600.0, 820.0, 1300.0]) {
      await tester.pumpWidget(
        page(
          FitnessChart(
            labels: [for (var i = 0; i < 14; i++) 'Nov ${i + 1}'],
            fitness: [for (var i = 0; i < 14; i++) 18.0 + i],
            fatigue: [for (var i = 0; i < 14; i++) 22.0 + i],
            form: [for (var i = 0; i < 14; i++) i.isEven ? 4 : -4],
            emptyMessage: 'No training load in this range.',
          ),
          width: width,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
  });

  testWidgets('PowerCurveChart_ShouldShowEmptyState_WhenThereAreNoPoints', (
    tester,
  ) async {
    await tester.pumpWidget(
      page(
        const PowerCurveChart(
          seconds: [],
          watts: [],
          marks: [],
          emptyMessage: 'No power data in this range.',
        ),
      ),
    );
    expect(find.text('No power data in this range.'), findsOneWidget);
  });

  testWidgets('PowerCurveChart_ShouldNameTheDurations_WhenItDrawsTheCurve', (
    tester,
  ) async {
    await tester.pumpWidget(
      page(
        const PowerCurveChart(
          seconds: [5, 60, 300, 1200],
          watts: [900, 500, 350, 280],
          marks: [
            (seconds: 1, label: '1s'),
            (seconds: 60, label: '1m'),
            (seconds: 300, label: '5m'),
            (seconds: 3600, label: '1h'),
          ],
          emptyMessage: 'No power data in this range.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // A curve read against its FTP says so on the chart line.
    for (final label in ['1s', '1m', '5m', '1h']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
  });

  testWidgets('PowerCurveChart_ShouldDrawInAccentStrong_WhenItDrawsTheCurve', (
    tester,
  ) async {
    await tester.pumpWidget(
      page(
        const PowerCurveChart(
          seconds: [5, 60, 300, 1200],
          watts: [900, 500, 350, 280],
          marks: [(seconds: 1, label: '1s'), (seconds: 3600, label: '1h')],
          emptyMessage: 'No power data in this range.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // PowerPage.md draws the curve as a mark on this page, in `accent-strong`, not as one of the
    // ride's signals in `series-power`.
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final colors = VelomineColors.of(tester.element(find.byType(LineChart)));
    expect(chart.data.lineBarsData.single.color, colors.accentStrong);
    expect(chart.data.lineBarsData.single.color, isNot(colors.series['power']));
  });

  testWidgets(
    'SeriesLineChart_ShouldNotOverflow_WhenAValueIsMissingInTheMiddle',
    (tester) async {
      final selected = ValueNotifier<int?>(null);
      addTearDown(selected.dispose);
      await tester.pumpWidget(
        page(
          SeriesLineChart(
            time: const [0, 10, 20, 30],
            values: const [180, null, 220, 200],
            marks: const [
              (seconds: 0, label: '0:00'),
              (seconds: 30, label: '0:30'),
            ],
            color: const Color(0xFF123456),
            emptyMessage: 'No data',
            selected: selected,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // The gap stays a gap: fl_chart breaks the line at the null spot.
      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.lineBarsData.single.spots.length, 4);
    },
  );
}
