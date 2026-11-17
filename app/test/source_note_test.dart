import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/widgets/source_note.dart';

void main() {
  testWidgets('SourceNote_ShouldReadItsTextToScreenReaders_WhenShown', (
    tester,
  ) async {
    const text = 'Set by you on 12 Nov 2026';
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SourceNote(text))),
    );

    expect(find.bySemanticsLabel(text), findsOneWidget);
    expect(find.text(text), findsOneWidget);
    handle.dispose();
  });
}
