import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/widgets/app_text_field.dart';

void main() {
  testWidgets('AppTextField_ShouldWrapTheHelperText_WhenTheStringIsLong', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    const helper =
        'Functional threshold power. Used for training load and power zones.';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTextField(
            fieldKey: const Key('ftp'),
            controller: controller,
            label: 'FTP',
            helper: helper,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.widget<Text>(find.text(helper)).maxLines, 3);
    expect(find.byKey(const Key('ftp')), findsOneWidget);
  });
}
