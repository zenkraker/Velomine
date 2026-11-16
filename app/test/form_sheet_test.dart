import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/widgets/form_sheet.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';

/// A page with a button that opens [sheet] and records what it returned.
class _Host extends StatefulWidget {
  const _Host(this.sheet);

  final WidgetBuilder sheet;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  Object? result = 'unset';

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        TextButton(
          key: const Key('open'),
          onPressed: () async {
            final r = await showSheet<String>(context, builder: widget.sheet);
            setState(() => result = r);
          },
          child: const Text('open'),
        ),
        Text('result: $result', key: const Key('result')),
      ],
    ),
  );
}

Widget _app(WidgetBuilder sheet) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: _Host(sheet),
);

void main() {
  testWidgets('SheetFrame_ShouldShowItsTitleAndContent_WhenOpened', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app((_) => const SheetFrame(title: 'A title', children: [Text('Body')])),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    expect(find.text('A title'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
  });

  testWidgets('SheetFrame_ShouldReturnNull_WhenDismissedByTheBarrier', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app((_) => const SheetFrame(title: 'A title', children: [])),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('A title'), findsNothing);
    expect(find.text('result: null'), findsOneWidget);
  });

  testWidgets('FormSheet_ShouldKeepSaveVisible_WhenTheKeyboardIsOpen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        (_) => FormSheet(
          title: 'Form',
          saveKey: const Key('save'),
          onSave: () {},
          error: 'Wrong',
          children: const [TextField(key: Key('field'))],
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    // A keyboard of 300 logical pixels.
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    await tester.pumpAndSettle();
    final save = tester.getRect(find.byKey(const Key('save')));
    expect(save.bottom, lessThanOrEqualTo(600 - 300 + 0.1));
    expect(save.width, greaterThan(300));
    expect(find.byKey(const Key('form-error')), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('FormSheet_ShouldKeepSaveVisible_WhenTheContentIsLong', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        (context) => FormSheet(
          title: 'Form',
          saveKey: const Key('save'),
          onSave: () => Navigator.of(context).pop('saved'),
          children: [for (var i = 0; i < 40; i++) TextField(key: Key('f$i'))],
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    final save = tester.getRect(find.byKey(const Key('save')));
    expect(save.bottom, lessThanOrEqualTo(600));
    // The last field is scrolled out of view while Save stays on screen.
    expect(tester.getRect(find.byKey(const Key('f39'))).top, greaterThan(600));
    await tester.tap(find.byKey(const Key('save')));
    await tester.pumpAndSettle();
    expect(find.text('result: saved'), findsOneWidget);
  });

  testWidgets('FormSheet_ShouldNotAddSafeAreaToKeyboard_WhenBothApply', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        (_) => FormSheet(
          title: 'Form',
          saveKey: const Key('save'),
          onSave: () {},
          children: const [],
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    // Save rests above the keyboard (1200 - 300) with the sheet's own gap, not 34 dp higher.
    expect(
      tester.getBottomLeft(find.byKey(const Key('save'))).dy,
      1200 - 300 - 16,
    );
  });
}
