import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/l10n.dart';
import 'package:velomine/core/widgets/saved_mark.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pumpMark(WidgetTester tester, {required bool visible}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SavedMark(visible: visible)),
      ),
    );
    await tester.pumpAndSettle();
  }

  double opacityOf(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(SavedMark),
          matching: find.byType(AnimatedOpacity),
        ),
      )
      .opacity;

  testWidgets('SavedMark_ShouldShowTheWord_WhenVisible', (tester) async {
    await pumpMark(tester, visible: true);

    expect(find.text('Saved.'), findsOneWidget);
    expect(opacityOf(tester), 1);
  });

  testWidgets('SavedMark_ShouldFadeOutAndKeepItsText_WhenHidden', (
    tester,
  ) async {
    await pumpMark(tester, visible: false);

    expect(opacityOf(tester), 0);
    expect(find.text('Saved.'), findsOneWidget);
  });
}
