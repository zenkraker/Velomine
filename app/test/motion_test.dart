import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/motion.dart';

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
}
