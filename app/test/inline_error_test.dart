import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/widgets/inline_error.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ThemeData(colorScheme: const ColorScheme.light()),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('InlineError_ShouldShowTextInErrorColour_WhenGivenAMessage', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const InlineError('Wrong password')));

    final text = tester.widget<Text>(find.text('Wrong password'));
    expect(text.style?.color, const ColorScheme.light().error);
  });

  testWidgets('InlineError_ShouldBeFoundByKey_WhenAKeyIsGiven', (tester) async {
    await tester.pumpWidget(
      _host(const InlineError('Nope', key: Key('form-error'))),
    );

    expect(find.byKey(const Key('form-error')), findsOneWidget);
  });

  testWidgets('InlineError_ShouldAnnounceItself_WhenItAppears', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(const InlineError('Nope')));

    expect(
      tester.getSemantics(find.text('Nope')),
      matchesSemantics(label: 'Nope', isLiveRegion: true),
    );
    handle.dispose();
  });

  testWidgets('InlineError_ShouldDrawAnIcon_WhenShowIconIsSet', (tester) async {
    await tester.pumpWidget(_host(const InlineError('Nope', showIcon: true)));

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
