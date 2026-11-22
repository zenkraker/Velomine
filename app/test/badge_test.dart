import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/theme.dart';
import 'package:velomine/core/widgets/badge.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: nightTheme(),
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('AppBadge_ShouldShowItsLabel_WhenBuiltWithOne', (tester) async {
    await tester.pumpWidget(wrap(const AppBadge('Gravel')));

    expect(find.text('Gravel'), findsOneWidget);
  });

  testWidgets('AppBadge_ShouldUseTheSignalColour_WhenTheToneAsksForCare', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const AppBadge('Due soon', tone: AppBadgeTone.care)),
    );

    final text = tester.widget<Text>(find.text('Due soon'));
    expect(text.style?.color, nightTheme().extension<VelomineColors>()!.signal);
  });
}
