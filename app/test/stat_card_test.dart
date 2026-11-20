import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/theme.dart';
import 'package:velomine/core/widgets/stat_card.dart';

Widget page(Widget child, {double width = 800, double textScale = 1}) =>
    MaterialApp(
      theme: nightTheme(),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 900),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );

void main() {
  testWidgets('StatCard_ShouldFindPlainText_WhenUnitIsSplit', (tester) async {
    await tester.pumpWidget(
      page(const StatCard(title: 'FTP', value: '211', unit: 'W')),
    );

    expect(find.text('211 W'), findsOneWidget);
  });

  testWidgets('StatCard_ShouldShowStateChipAfterNumber_WhenStateGiven', (
    tester,
  ) async {
    await tester.pumpWidget(
      page(
        const StatCard(
          title: 'Readiness',
          value: '50',
          state: 'Go easy',
          stateCare: true,
          sentence: 'Keep it easy: endurance pace, no hard efforts.',
        ),
      ),
    );

    expect(find.text('Go easy'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Go easy')).dx,
      greaterThan(tester.getTopLeft(find.text('50')).dx),
    );
  });

  testWidgets('StatCard_ShouldCallBack_WhenLinkIsTapped', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      page(
        StatCard(
          title: 'This week',
          value: '69.7',
          unit: 'km',
          link: 'All weeks',
          onLink: () => tapped++,
        ),
      ),
    );

    await tester.tap(find.text('All weeks'));
    expect(tapped, 1);
  });

  testWidgets('StatCard_ShouldWrapSentence_WhenTextScaleIsTwo', (tester) async {
    await tester.pumpWidget(
      page(
        const StatCard(
          title: 'Readiness',
          value: '50',
          state: 'Go easy',
          sentence: 'Keep it easy: endurance pace, no hard efforts, and stay out of the wind.',
        ),
        width: 390,
        textScale: 2,
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('StatCardRow_ShouldGiveEqualHeights_WhenOneSentenceIsLong', (
    tester,
  ) async {
    await tester.pumpWidget(
      page(
        const StatCardRow(
          children: [
            StatCard(title: 'Power', value: '211', unit: 'W', sentence: 'One.'),
            StatCard(
              title: 'This week',
              value: '69.7',
              unit: 'km',
              sentence: 'Two rides, a long climb and a short spin, in one sentence that wraps over more than one line.',
            ),
          ],
        ),
        width: 1300,
      ),
    );

    expect(
      tester.getSize(find.byType(StatCard).at(0)).height,
      tester.getSize(find.byType(StatCard).at(1)).height,
    );
  });

  for (final (width, across, rows) in [
    (1300.0, 'Four', 1),
    (820.0, 'Two', 2),
    (600.0, 'Two', 2),
    (390.0, 'One', 4),
  ]) {
    testWidgets(
      'StatCardRow_ShouldShow${across}Across_WhenWidthIs${width.toInt()}',
      (tester) async {
        await tester.pumpWidget(
          page(
            StatCardRow(
              children: [
                for (var i = 0; i < 4; i++)
                  StatCard(title: 'Card $i', value: '$i'),
              ],
            ),
            width: width,
          ),
        );

        final tops = [
          for (var i = 0; i < 4; i++)
            tester.getTopLeft(find.byType(StatCard).at(i)).dy,
        ];
        expect(<double>{...tops}.length, rows);
      },
    );
  }
}
