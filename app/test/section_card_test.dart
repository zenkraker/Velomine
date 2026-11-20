import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/theme.dart';
import 'package:velomine/core/tokens.dart';
import 'package:velomine/core/widgets/section_card.dart';

void main() {
  testWidgets('SectionCard_ShouldShowItsMenu_WhenAMenuIsGiven', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SectionCard(
            title: 'Wellbeing',
            menu: Icon(Icons.more_vert, key: Key('card-menu')),
            children: [Text('Body')],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('card-menu')), findsOneWidget);
    expect(find.text('Wellbeing'), findsOneWidget);
  });

  testWidgets('SectionCard_ShouldShowNoMenu_WhenNoneIsGiven', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SectionCard(title: 'Plain', children: [Text('Body')]),
        ),
      ),
    );

    expect(find.byKey(const Key('card-menu')), findsNothing);
    expect(find.text('Plain'), findsOneWidget);
  });

  testWidgets('SectionCard_ShouldShowMenuAtCardEdge_WhenMenuGiven', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: nightTheme(),
        home: const Scaffold(
          body: SectionCard(
            title: 'Wellbeing',
            menu: Icon(Icons.more_vert, key: Key('card-menu')),
            children: [Text('Body')],
          ),
        ),
      ),
    );

    final card = tester.getRect(find.byType(SectionCard));
    final menu = tester.getRect(find.byKey(const Key('card-menu')));
    // The menu's tap area hangs over the card's padding, so it reads at the card's edge.
    expect(menu.right, greaterThan(card.right - AppSpacing.xl));
  });
}
