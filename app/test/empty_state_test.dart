import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/theme.dart';
import 'package:velomine/core/widgets/app_card.dart';
import 'package:velomine/core/widgets/empty_state.dart';

Widget page(Widget child) => MaterialApp(
  theme: nightTheme(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('EmptyState_ShouldDrawFilledCard_WhenFramed', (tester) async {
    await tester.pumpWidget(page(const EmptyState(message: 'No rides yet.')));

    expect(find.byType(AppCard), findsOneWidget);
    expect(find.text('No rides yet.'), findsOneWidget);
  });

  testWidgets('EmptyState_ShouldDrawNoCard_WhenNotFramed', (tester) async {
    await tester.pumpWidget(
      page(const EmptyState(message: 'No rides that day.', framed: false)),
    );

    expect(find.byType(AppCard), findsNothing);
    expect(find.text('No rides that day.'), findsOneWidget);
  });
}
