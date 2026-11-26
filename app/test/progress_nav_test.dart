import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/back_guard.dart';
import 'package:velomine/core/widgets/page_scaffold.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
    server.totals['week'] = [
      totalsJson('2026-11-02', '2026-11-08', rides: 2, distanceM: 42500),
    ];
  });

  Future<void> start(
    WidgetTester tester, {
    Size size = const Size(1000, 2400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, server.session(useCookies: true));
  }

  testWidgets('ProgressSidebar_ShouldListTheFivePages_WhenExpanded', (
    tester,
  ) async {
    await start(tester, size: const Size(1300, 1000));
    await goTo(tester, '/progress');
    await tester.pumpAndSettle();

    // The Progress section opens by itself on its page and lists every sub-page.
    for (final key in [
      'nav-overview',
      'nav-fitness',
      'nav-power',
      'nav-totals',
      'nav-wellbeing',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
  });

  testWidgets('ProgressTabs_ShouldShowAllFivePages_WhenOnAPhone', (
    tester,
  ) async {
    await start(tester, size: const Size(390, 844));
    await goTo(tester, '/progress');
    await tester.pumpAndSettle();

    for (final key in [
      'progress-tab-overview',
      'progress-tab-fitness',
      'progress-tab-power',
      'progress-tab-totals',
      'progress-tab-wellbeing',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
  });

  testWidgets('ProgressTabs_ShouldOpenTheSubPage_WhenItsChipIsTapped', (
    tester,
  ) async {
    // The tabs are the phone's way between the sub-pages; a wider window has the rail or the sidebar.
    await start(tester, size: const Size(390, 2400));
    await goTo(tester, '/progress');
    await tester.pumpAndSettle();

    // The five chips scroll sideways on a phone; the last one is off the right edge.
    await tester.scrollUntilVisible(
      find.byKey(const Key('progress-tab-totals')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('progress-tab-totals')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('total-0')), findsOneWidget);

    // The row now keeps the chosen chip in view, so the one to its left is off the edge: scroll back to it.
    await tester.ensureVisible(find.byKey(const Key('progress-tab-fitness')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('progress-tab-fitness')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fitness-chart')), findsOneWidget);
    // The chosen chip is the page on screen.
    final chip = tester.widget<ChoiceChip>(
      find.byKey(const Key('progress-tab-fitness')),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('ProgressTabs_ShouldOpenTheSubPage_WhenAPhoneTapsAChip', (
    tester,
  ) async {
    await start(tester, size: const Size(390, 844));
    await goTo(tester, '/progress');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('progress-tab-fitness')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fitness-chart')), findsOneWidget);
  });

  testWidgets(
    'FitnessScreen_ShouldOpenTheSportFilter_WhenItsMenuEntryIsChosen',
    (tester) async {
      await start(tester);
      await goTo(tester, '/progress/fitness');
      await tester.pumpAndSettle();

      // The guideline gives Fitness a `⋯` menu; the sport filter is its one entry.
      await tester.tap(find.byKey(const Key('fitness-actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fitness-filter')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byKey(const Key('progress-filter-gravel')),
        ),
      );
      await tester.pumpAndSettle();

      expect(server.analyticsFilters, contains('gravel'));
    },
  );

  testWidgets('ProgressPages_ShouldShowTheProgressCaption_WhenWide', (
    tester,
  ) async {
    await start(tester);
    await goTo(tester, '/progress/power');
    await tester.pumpAndSettle();

    final page = tester.widget<PageScaffold>(find.byType(PageScaffold));
    expect(page.parent, 'Progress');
    expect(page.title, 'Power');
  });

  testWidgets('ProgressPages_ShouldShowTheCaption_WhenOnAPhone', (
    tester,
  ) async {
    await start(tester, size: const Size(390, 844));
    await goTo(tester, '/progress/fitness');
    await tester.pumpAndSettle();

    // The design gives every sub-page its parent's name as a caption, at every width.
    final page = tester.widget<PageScaffold>(find.byType(PageScaffold));
    expect(page.parent, 'Progress');
    expect(page.title, 'Fitness');
  });

  testWidgets('ProgressPages_ShouldOpenEverySubPage_WhenItsAddressIsUsed', (
    tester,
  ) async {
    await start(tester, size: const Size(390, 2400));
    for (final (path, key) in [
      ('/progress', 'progress-tab-overview'),
      ('/progress/fitness', 'fitness-chart'),
      ('/progress/power', 'power-curve-card'),
      ('/progress/totals', 'total-0'),
      ('/progress/wellbeing', 'wellbeing-consent-card'),
    ]) {
      await goTo(tester, path);
      await tester.pumpAndSettle();
      expect(find.byKey(Key(key)), findsOneWidget, reason: path);
    }
  });

  test(
    'ProgressPages_ShouldLeadBackToTheOverview_WhenThePhoneAsksForTheParent',
    () {
      // Backed out of a deep link, the sub-pages lead to the overview instead of closing the app.
      for (final path in [
        '/progress/fitness',
        '/progress/power',
        '/progress/totals',
        '/progress/wellbeing',
      ]) {
        expect(backParentOf(path), '/progress', reason: path);
      }
    },
  );

  testWidgets('ProgressPages_ShouldGoToTheOverview_WhenThePhoneGoesBack', (
    tester,
  ) async {
    await start(tester, size: const Size(390, 844));
    await goTo(tester, '/progress/power');
    await tester.pumpAndSettle();

    // The sub-page is a destination of Progress: back leads to the overview, not to Rides or out of
    // the app.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('progress-period')), findsOneWidget);
  });
}
