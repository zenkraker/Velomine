import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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

  testWidgets('pillBlurOf_ShouldBeZero_WhenTheDeviceIsAnAndroidPhone', (
    tester,
  ) async {
    expect(await blurOn(tester, TargetPlatform.android), 0);
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

  testWidgets('FloatingNavPill_ShouldDrawNoBackdropFilter_WhenBlurIsOff', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.pumpWidget(
      MaterialApp(
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

    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.text('One'), findsOneWidget);
  });
}
