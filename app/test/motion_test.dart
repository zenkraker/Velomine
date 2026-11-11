import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:velomine/core/motion.dart';
import 'package:velomine/core/theme.dart';

void main() {
  testWidgets('motionDuration_ShouldReturnZero_WhenTheSystemReducesMotion', (
    tester,
  ) async {
    late Duration result;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            result = motionDuration(context, const Duration(milliseconds: 250));
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(result, Duration.zero);
  });

  testWidgets('motionDuration_ShouldReturnTheDuration_WhenMotionIsAllowed', (
    tester,
  ) async {
    late Duration result;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(
          builder: (context) {
            result = motionDuration(context, const Duration(milliseconds: 250));
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(result, const Duration(milliseconds: 250));
  });

  testWidgets(
    'Router_ShouldChangePageWithoutTransition_WhenTheSystemReducesMotion',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('first')),
          ),
          GoRoute(
            path: '/second',
            builder: (_, _) => const Scaffold(body: Text('second')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: dayTheme(),
          routerConfig: router,
          builder: (context, child) => reduceMotion(context)
              ? Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(pageTransitionsTheme: noAnimationPageTransitions),
                  child: child!,
                )
              : child!,
        ),
      );

      router.go('/second');
      await tester.pump();

      expect(find.text('second'), findsOneWidget);
    },
  );
}
