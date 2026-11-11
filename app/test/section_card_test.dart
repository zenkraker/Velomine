import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/widgets/section_card.dart';

void main() {
  testWidgets(
    'SectionCard_ShouldFitItsContent_WhenTextIsTwiceTheSizeOnAPhone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                SectionCard(
                  title: 'Notifications',
                  description: 'What the club may send you.',
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: true,
                      title: const Text('Email'),
                      subtitle: const Text('A weekly summary of the club.'),
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    },
  );
}
