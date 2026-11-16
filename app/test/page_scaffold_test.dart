import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/theme.dart';
import 'package:velomine/core/widgets/eyebrow.dart';
import 'package:velomine/core/widgets/page_scaffold.dart';

Future<void> pumpPage(
  WidgetTester tester, {
  required double width,
  bool showOnPhone = false,
  VoidCallback? onBack,
  Widget? primaryAction,
  Widget? menu,
  Widget? actions,
  String? eyebrow,
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
            title: 'Garage',
            titleKey: titleKey,
            eyebrow: eyebrow,
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

  testWidgets('Eyebrow_ShouldUppercaseText_WhenBuilt', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: dayTheme(),
        home: const Scaffold(body: Eyebrow('your bikes')),
      ),
    );
    expect(find.text('YOUR BIKES'), findsOneWidget);
  });
}
