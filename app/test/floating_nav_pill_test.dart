import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/theme.dart';
import 'package:velomine/core/tokens.dart';
import 'package:velomine/core/widgets/floating_nav_pill.dart';

void main() {
  Future<double> blurOn(
    WidgetTester tester,
    TargetPlatform platform, {
    bool highContrast = false,
  }) async {
    debugDefaultTargetPlatformOverride = platform;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    late double blur;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(highContrast: highContrast),
        child: Builder(
          builder: (context) {
            blur = pillBlurOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return blur;
  }

  testWidgets('pillBlurOf_ShouldKeepTheBlur_WhenTheDeviceIsAnAndroidPhone', (
    tester,
  ) async {
    expect(await blurOn(tester, TargetPlatform.android), AppNav.pillBlur);
  });

  testWidgets('pillBlurOf_ShouldKeepTheBlur_WhenTheDeviceIsAnIPhone', (
    tester,
  ) async {
    expect(await blurOn(tester, TargetPlatform.iOS), AppNav.pillBlur);
  });

  testWidgets('pillBlurOf_ShouldBeZero_WhenTheSystemAsksForHighContrast', (
    tester,
  ) async {
    expect(await blurOn(tester, TargetPlatform.iOS, highContrast: true), 0);
  });

  testWidgets(
    'FloatingNavPill_ShouldFillWithTheGlassColourAndBlur_WhenTheSystemAllowsBoth',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: nightTheme(),
          home: Scaffold(
            body: Stack(
              children: [
                FloatingNavPill(
                  items: [
                    (
                      key: null,
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home),
                      label: 'One',
                    ),
                  ],
                  selected: 0,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(FloatingNavPill));
      final surface = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(FloatingNavPill),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(surface.color, VelomineColors.of(context).glass);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.text('One'), findsOneWidget);
    },
  );

  testWidgets(
    'FloatingNavPill_ShouldFillWithNearlySolidGlass_WhenTheSystemAsksForHighContrast',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(highContrast: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: nightTheme(),
          home: Scaffold(
            body: Stack(
              children: [
                FloatingNavPill(
                  items: [
                    (
                      key: null,
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home),
                      label: 'One',
                    ),
                  ],
                  selected: 0,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(FloatingNavPill));
      final surface = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(FloatingNavPill),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(
        surface.color,
        VelomineColors.of(context).glass
            .withValues(alpha: AppNav.pillOpacityNoBlur),
      );
      expect(find.byType(BackdropFilter), findsNothing);
    },
  );

  testWidgets(
    'FloatingNavPill_ShouldPaintSelectedItemOnAccentSoft_WhenSelected',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.pumpWidget(
        MaterialApp(
          theme: nightTheme(),
          home: Scaffold(
            body: Stack(
              children: [
                FloatingNavPill(
                  items: const [
                    (
                      key: Key('one'),
                      icon: Icon(Icons.flag_outlined),
                      selectedIcon: Icon(Icons.flag),
                      label: 'One',
                    ),
                    (
                      key: Key('two'),
                      icon: Icon(Icons.groups_outlined),
                      selectedIcon: Icon(Icons.groups),
                      label: 'Two',
                    ),
                  ],
                  selected: 0,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      final scheme = Theme.of(tester.element(find.byType(FloatingNavPill)))
          .colorScheme;
      ShapeDecoration decorationOf(String key) =>
          tester
                  .widget<AnimatedContainer>(
                    find.descendant(
                      of: find.byKey(Key(key)),
                      matching: find.byType(AnimatedContainer),
                    ),
                  )
                  .decoration!
              as ShapeDecoration;

      expect(decorationOf('one').color, scheme.primaryContainer);
      expect(decorationOf('two').color, Colors.transparent);
      // The chosen one is filled, the other outlined.
      expect(find.byIcon(Icons.flag), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsNothing);
      expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
    },
  );

  for (final labels in [
    ['Rides', 'Training', 'Progress', 'Goals', 'Club'],
    ['Giri', 'Allenamento', 'Progressi', 'Obiettivi', 'Club'],
  ]) {
    testWidgets(
      'FloatingNavPill_ShouldKeepEveryLabelWhole_WhenFiveDestinationsShowAt390Wide(${labels.first})',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: nightTheme(),
            home: Scaffold(
              body: Stack(
                children: [
                  FloatingNavPill(
                    items: [
                      for (final label in labels)
                        (
                          key: null,
                          icon: const Icon(Icons.home_outlined),
                          selectedIcon: const Icon(Icons.home),
                          label: label,
                        ),
                    ],
                    selected: 2,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );
        final pill = tester.getRect(find.byType(FloatingNavPill));
        final texts = [
          for (final label in labels) tester.getRect(find.text(label)),
        ];
        for (final (i, rect) in texts.indexed) {
          expect(rect.left, greaterThanOrEqualTo(pill.left));
          expect(rect.right, lessThanOrEqualTo(pill.right));
          if (i > 0) {
            expect(rect.left, greaterThanOrEqualTo(texts[i - 1].right));
          }
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
