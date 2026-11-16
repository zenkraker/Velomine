import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/widgets/bottom_action_bar.dart';
import 'package:velomine/core/widgets/page_scaffold.dart';

const _save = Key('save');
const _last = Key('last');

Widget _page({
  int fields = 3,
  TextScaler? scaler,
  VoidCallback? onSave,
  bool resizingScaffold = false,
}) {
  final page = PageScaffold(
    title: 'Form',
    bottomAction: BottomActionBar.button(
      buttonKey: _save,
      label: 'Save',
      onPressed: onSave ?? () {},
    ),
    children: [
      for (var i = 0; i < fields; i++)
        SizedBox(height: 120, child: Text('field $i')),
      const SizedBox(key: _last, height: 60, child: Text('last')),
    ],
  );
  return MaterialApp(
    builder: (context, child) => scaler == null
        ? child!
        : MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: scaler),
            child: child!,
          ),
    // A bare Material leaves the keyboard inset to the bar; a Scaffold resizes for it and hides it.
    home: resizingScaffold ? Scaffold(body: page) : Material(child: page),
  );
}

void _size(WidgetTester tester, Size logical) {
  tester.view.physicalSize = logical;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets(
    'BottomActionBar_ShouldStayAboveTheKeyboard_WhenViewInsetsAreSet',
    (tester) async {
      _size(tester, const Size(400, 800));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(_page());
      final bottom = tester.getBottomLeft(find.byKey(_save)).dy;
      expect(bottom, lessThanOrEqualTo(800 - 300));
      expect(find.byKey(_save), findsOneWidget);
    },
  );

  testWidgets(
    'BottomActionBar_ShouldClearTheHomeIndicator_WhenThereIsASafeArea',
    (tester) async {
      _size(tester, const Size(400, 800));
      tester.view.padding = const FakeViewPadding(bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await tester.pumpWidget(_page());
      expect(
        tester.getBottomLeft(find.byKey(_save)).dy,
        lessThanOrEqualTo(800 - 34),
      );
    },
  );

  testWidgets('BottomActionBar_ShouldNotAddSafeAreaToKeyboard_WhenBothApply', (
    tester,
  ) async {
    _size(tester, const Size(400, 800));
    tester.view.padding = const FakeViewPadding(bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(_page());
    // The button rests on the keyboard's top edge with one gap: 800 - 300 - 8, not 800 - 334 - 8.
    expect(tester.getBottomLeft(find.byKey(_save)).dy, 800 - 300 - 8);
  });

  testWidgets('BottomActionBar_ShouldStayTappable_WhenTextIsScaledTwice', (
    tester,
  ) async {
    _size(tester, const Size(400, 800));
    var taps = 0;
    await tester.pumpWidget(
      _page(scaler: const TextScaler.linear(2), onSave: () => taps++),
    );
    final rect = tester.getRect(find.byKey(_save));
    expect(rect.bottom, lessThanOrEqualTo(800));
    expect(rect.height, greaterThanOrEqualTo(48));
    await tester.tap(find.byKey(_save));
    expect(taps, 1);
  });

  testWidgets('BottomActionBar_ShouldFillTheWidth_WhenThePhoneIsNarrow', (
    tester,
  ) async {
    _size(tester, const Size(400, 800));
    await tester.pumpWidget(_page());
    expect(tester.getSize(find.byKey(_save)).width, 400 - 2 * 16);
  });

  testWidgets('BottomActionBar_ShouldKeepItsNaturalWidth_WhenTheWindowIsWide', (
    tester,
  ) async {
    _size(tester, const Size(1300, 800));
    await tester.pumpWidget(_page());
    final size = tester.getSize(find.byKey(_save));
    expect(size.width, lessThan(300));
    // Right-aligned under the content column: the column is 1160 wide, centred, inside a 32 gutter.
    expect(tester.getRect(find.byKey(_save)).right, closeTo(1300 - 70, 1));
  });

  testWidgets(
    'PageScaffold_ShouldScrollTheLastChildAboveTheBar_WhenThePageIsLong',
    (tester) async {
      _size(tester, const Size(400, 600));
      await tester.pumpWidget(_page(fields: 12));
      expect(find.byKey(_last).hitTestable(), findsNothing);
      await tester.dragUntilVisible(
        find.byKey(_last),
        find.byType(CustomScrollView),
        const Offset(0, -200),
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      final barTop = tester.getTopLeft(find.byKey(_save)).dy;
      expect(
        tester.getBottomLeft(find.byKey(_last)).dy,
        lessThanOrEqualTo(barTop),
      );
      expect(find.byKey(_save).hitTestable(), findsOneWidget);
    },
  );
}
