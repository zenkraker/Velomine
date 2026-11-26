import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/theme.dart';
import 'package:velomine/core/tokens.dart';
import 'package:velomine/core/widgets/page_scaffold.dart';

Future<void> pumpPage(
  WidgetTester tester, {
  required double width,
  bool showOnPhone = false,
  VoidCallback? onBack,
  Widget? primaryAction,
  Widget? menu,
  Widget? actions,
  String? parent,
  String title = 'Garage',
  Key? titleKey,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: dayTheme(),
      home: PageHeaderScope(
        showOnPhone: showOnPhone,
        child: Scaffold(
          body: PageScaffold(
            title: title,
            titleKey: titleKey,
            parent: parent,
            subtitle: 'Everything you ride',
            onBack: onBack,
            primaryAction: primaryAction,
            menu: menu,
            actions: actions,
            children: [
              for (var i = 0; i < 40; i++)
                SizedBox(height: 80, child: Text('row $i')),
            ],
          ),
        ),
      ),
    ),
  );
}

/// A page whose last child asks to reach the bottom of the window.
Future<void> pumpFillLast(
  WidgetTester tester, {
  required Size size,
  required double lastHeight,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: dayTheme(),
      home: Scaffold(
        body: PageScaffold(
          title: 'Progress',
          subtitle: 'How am I today?',
          fillLast: true,
          children: [
            const SizedBox(height: 80, child: Text('above')),
            SizedBox(
              key: const Key('last'),
              height: lastHeight,
              child: const Text('chart'),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('PageScaffold_ShouldCollapseTitle_WhenContentScrolls', (
    tester,
  ) async {
    await pumpPage(tester, width: 1000, titleKey: const Key('t'));
    expect(find.byKey(const Key('t')), findsOneWidget);
    expect(find.text('Everything you ride'), findsOneWidget);
    expect(find.text('Garage'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('t')), findsNothing);
    expect(find.text('Everything you ride'), findsNothing);
    expect(find.text('Garage'), findsOneWidget);
  });

  testWidgets('PageScaffold_ShouldShowBackArrow_WhenOnBackIsSet', (
    tester,
  ) async {
    var back = 0;
    await pumpPage(tester, width: 1000, onBack: () => back++);
    await tester.tap(find.byType(BackButton));
    expect(back, 1);
  });

  testWidgets('PageScaffold_ShouldHideBackArrow_WhenOnBackIsNull', (
    tester,
  ) async {
    await pumpPage(tester, width: 1000);
    expect(find.byType(BackButton), findsNothing);
  });

  for (final width in [400.0, 1300.0]) {
    testWidgets(
      'PageScaffold_ShouldShowPrimaryAction_WhenWidthIs${width.toInt()}',
      (tester) async {
        await pumpPage(
          tester,
          width: width,
          showOnPhone: true,
          primaryAction: FilledButton(
            onPressed: () {},
            child: const Text('Add bike'),
          ),
          menu: const Icon(Icons.more_horiz, key: Key('menu')),
        );
        expect(find.text('Add bike'), findsOneWidget);
        expect(find.byKey(const Key('menu')), findsOneWidget);
      },
    );
  }

  testWidgets('PageScaffold_ShouldHideHeader_WhenPhoneHasNoScope', (
    tester,
  ) async {
    await pumpPage(
      tester,
      width: 400,
      primaryAction: FilledButton(
        onPressed: () {},
        child: const Text('Add bike'),
      ),
    );
    expect(find.text('Garage'), findsNothing);
    expect(find.text('Add bike'), findsNothing);
    expect(find.text('row 0'), findsOneWidget);
  });

  testWidgets('PageScaffold_ShouldShowLegacyActions_WhenWindowIsWide', (
    tester,
  ) async {
    await pumpPage(tester, width: 1000, actions: const Text('old actions'));
    expect(find.text('old actions'), findsOneWidget);
  });

  testWidgets('PageScaffold_ShouldKeepTitleKeyOnOneWidget_WhenHeaderShows', (
    tester,
  ) async {
    await pumpPage(tester, width: 1000, titleKey: const Key('page-title'));
    expect(find.byKey(const Key('page-title')), findsOneWidget);
  });

  testWidgets(
    'PageScaffold_ShouldShowParentCaptionAboveTitle_WhenParentGiven',
    (tester) async {
      await pumpPage(tester, width: 1000, parent: 'Progress');

      expect(find.text('Progress'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Progress')).dy,
        lessThan(tester.getTopLeft(find.text('Garage')).dy),
      );
    },
  );

  testWidgets('PageScaffold_ShouldKeepTitleInSentenceCase_WhenTitleGiven', (
    tester,
  ) async {
    await pumpPage(tester, width: 1000, title: 'your bikes');

    expect(find.text('your bikes'), findsOneWidget);
    expect(find.text('YOUR BIKES'), findsNothing);
  });

  for (final width in [390.0, 1300.0]) {
    testWidgets(
      'PageScaffold_ShouldPinTheMenuToTheTitleRowsEnd_WhenWidthIs${width.toInt()}',
      (tester) async {
        await pumpPage(
          tester,
          width: width,
          showOnPhone: width < 600,
          primaryAction: const FilledButton(
            onPressed: null,
            child: Text('Add'),
          ),
          menu: IconButton(
            key: const Key('menu'),
            tooltip: 'More actions',
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          ),
        );

        // The page's action and its menu belong in the corner of the title row,
        // never halfway across the page: the trailing edge of the menu stays
        // within one gutter of the window's edge.
        final menu = tester.getRect(find.byKey(const Key('menu')));
        expect(
          menu.right,
          greaterThan(width - 3 * AppSpacing.xxl),
          reason: 'the menu sits at ${menu.right} in a $width window',
        );
      },
    );
  }

  for (final size in [const Size(390, 600), const Size(1300, 500)]) {
    testWidgets(
      'PageScaffold_ShouldGrowTheLastChildToTheWindowBottom_WhenFillLastIsSetAt${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await pumpFillLast(tester, size: size, lastHeight: 40);

        expect(tester.takeException(), isNull);
        // The short card takes the room left over, and ends above the bottom padding.
        final last = tester.getRect(find.byKey(const Key('last')));
        expect(last.height, greaterThan(40));
        expect(last.bottom, closeTo(size.height - AppSpacing.xl, 1));
      },
    );

    testWidgets(
      'PageScaffold_ShouldScrollInsteadOfOverflowing_WhenTheLastChildIsTallerThanTheWindowAt${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await pumpFillLast(tester, size: size, lastHeight: 2000);

        expect(tester.takeException(), isNull);
        // The tall card keeps its own height, and the page scrolls over it.
        expect(
          tester.getRect(find.byKey(const Key('last'))).height,
          greaterThan(size.height),
        );
      },
    );
  }

  testWidgets(
    'PageScaffold_ShouldWrapTheWholeSubtitle_WhenItIsLongerThanTwoLines',
    (tester) async {
      const long =
          'A sentence long enough that it needs four lines on a phone, which the header has to make room '
          'for instead of cutting it off with an ellipsis after the second line, as it used to do.';
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: dayTheme(),
          home: PageHeaderScope(
            showOnPhone: true,
            child: Scaffold(
              body: PageScaffold(
                title: 'Garage',
                subtitle: long,
                children: const [SizedBox(height: 80, child: Text('row'))],
              ),
            ),
          ),
        ),
      );
      final text = tester.widget<Text>(find.text(long));
      expect(text.overflow, isNot(TextOverflow.ellipsis));
      expect(text.maxLines, isNull);
      expect(tester.getSize(find.text(long)).height, greaterThan(3 * 20));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'PageScaffold_ShouldKeepTheMainActionFullSize_WhenThePhoneHeaderHoldsFourControls',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: dayTheme(),
          home: PageHeaderScope(
            showOnPhone: true,
            trailing: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.person)),
            ],
            child: Scaffold(
              body: PageScaffold(
                title: 'Rides',
                primaryAction: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload ride'),
                ),
                menu: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert),
                ),
                children: const [SizedBox(height: 80, child: Text('row'))],
              ),
            ),
          ),
        ),
      );
      // The button's own minimum is 52 dp tall; half that means the cluster was scaled down.
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(52),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
