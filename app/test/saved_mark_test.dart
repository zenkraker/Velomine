import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/l10n.dart';
import 'package:velomine/core/saved_mark_view_model.dart';
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

  testWidgets(
    'SavedMarkHost_ShouldPinTheBadgeToTheBottomRight_WhenASaveIsShown',
    (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SavedMarkHost(child: Scaffold(body: SizedBox.expand())),
          ),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SavedMarkHost)),
      );
      double opacity() => tester
          .widget<AnimatedOpacity>(
            find.descendant(
              of: find.byKey(const Key('saved-mark')),
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .opacity;
      expect(opacity(), 0);

      container.read(savedMarkViewModelProvider.notifier).show();
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(opacity(), 1);
      final box = tester.getRect(find.byKey(const Key('saved-mark')));
      expect(box.right, lessThan(390));
      expect(box.right, greaterThan(390 - 40));
      expect(box.bottom, greaterThan(800 / 2));

      await tester.pump(
        SavedMarkViewModel.shownFor + const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();
      expect(opacity(), 0);
    },
  );
}
