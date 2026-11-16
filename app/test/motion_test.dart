import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/motion.dart';
import 'package:velomine/core/tokens.dart';

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

  Future<Curve> curveFor(WidgetTester tester, bool reduce) async {
    late Curve result;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Builder(
          builder: (context) {
            result = motionCurve(context, AppMotion.spring);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return result;
  }

  testWidgets('motionCurve_ShouldReturnLinear_WhenTheSystemReducesMotion', (
    tester,
  ) async {
    expect(await curveFor(tester, true), Curves.linear);
  });

  testWidgets('motionCurve_ShouldReturnTheCurve_WhenMotionIsAllowed', (
    tester,
  ) async {
    expect(await curveFor(tester, false), AppMotion.spring);
  });
}
