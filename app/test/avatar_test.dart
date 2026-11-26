import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/theme.dart';
import 'package:velomine/core/tokens.dart';
import 'package:velomine/core/widgets/avatar.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: nightTheme(),
    home: Scaffold(body: Center(child: child)),
  );

  Color? groundOf(WidgetTester tester) {
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(Avatar),
        matching: find.byType(Container),
      ),
    );
    return (container.decoration! as BoxDecoration).color;
  }

  test('Avatar_ShouldTakeTwoInitials_WhenTheNameHasTwoWords', () {
    expect(Avatar.initialsOf('Marco Riva'), 'MR');
    expect(Avatar.initialsOf('  anna  maria greco '), 'AG');
  });

  test('Avatar_ShouldTakeOneInitial_WhenTheNameIsOneWord', () {
    expect(Avatar.initialsOf('Marco'), 'M');
    expect(Avatar.initialsOf(''), '?');
  });

  testWidgets('Avatar_ShouldShowTheInitials_WhenBuiltWithAName', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const Avatar('Giulia Ferri')));

    expect(find.text('GF'), findsOneWidget);
  });

  testWidgets('Avatar_ShouldLabelTheFullName_ForAScreenReader', (tester) async {
    await tester.pumpWidget(wrap(const Avatar('Luca Conti')));

    expect(find.bySemanticsLabel('Luca Conti'), findsOneWidget);
  });

  testWidgets('Avatar_ShouldKeepItsGround_WhenTheSameNameIsBuiltTwice', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const Avatar('Marco Riva')));
    final first = groundOf(tester);
    await tester.pumpWidget(wrap(const Avatar('Anyone Else')));
    await tester.pumpWidget(wrap(const Avatar('Marco Riva')));

    expect(groundOf(tester), first);
  });

  testWidgets('Avatar_ShouldTakeItsColourFromTheTheme_WhenAToneIsShown', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const Avatar('Marco Riva')));

    final colors = nightTheme().extension<VelomineColors>()!;
    final palette = [colors.accentSoft, colors.cardRaised, colors.signalSoft];
    expect(palette, contains(groundOf(tester)));
  });

  testWidgets('Avatar_ShouldKeepTheDesignSize_WhenNoSizeIsGiven', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const Avatar('Marco Riva')));

    expect(tester.getSize(find.byType(Avatar)).width, AppAvatar.size);
  });

  testWidgets('Avatar_ShouldNotClip_WhenTheSystemTextIsHuge', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(wrap(const Avatar('Marco Riva')));

    expect(tester.takeException(), isNull);
    expect(find.text('MR'), findsOneWidget);
  });
}
