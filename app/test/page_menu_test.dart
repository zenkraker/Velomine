import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/widgets/page_menu.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';

Widget _host(List<PageMenuEntry> entries) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    appBar: AppBar(actions: [PageMenu(entries: entries)]),
  ),
);

void main() {
  late List<String> picked;
  late List<PageMenuEntry> entries;

  setUp(() {
    picked = [];
    entries = [
      PageMenuEntry(
        key: const Key('delete'),
        label: 'Delete',
        icon: Icons.delete,
        destructive: true,
        onSelected: () => picked.add('delete'),
      ),
      PageMenuEntry(
        key: const Key('edit'),
        label: 'Edit',
        onSelected: () => picked.add('edit'),
      ),
    ];
  });

  testWidgets(
    'PageMenu_ShouldPutDestructiveEntryLastAfterDivider_WhenItIsGivenFirst',
    (tester) async {
      await tester.pumpWidget(_host(entries));
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      final edit = tester.getTopLeft(find.byKey(const Key('edit'))).dy;
      final delete = tester.getTopLeft(find.byKey(const Key('delete'))).dy;
      final divider = tester.getTopLeft(find.byType(Divider)).dy;
      expect(edit, lessThan(divider));
      expect(divider, lessThan(delete));
    },
  );

  testWidgets('PageMenu_ShouldDrawDestructiveEntryInErrorColour_WhenOpened', (
    tester,
  ) async {
    await tester.pumpWidget(_host(entries));
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    final error = Theme.of(tester.element(find.byKey(const Key('delete'))))
        .colorScheme
        .error;
    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('delete')),
        matching: find.byType(Icon),
      ),
    );
    expect(icon.color, error);
    final button = tester.widget<MenuItemButton>(
      find.byKey(const Key('delete')),
    );
    expect(button.style?.foregroundColor?.resolve({}), error);
  });

  testWidgets('PageMenu_ShouldCallOnSelected_WhenEntryIsTapped', (
    tester,
  ) async {
    await tester.pumpWidget(_host(entries));
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit')));
    await tester.pumpAndSettle();

    expect(picked, ['edit']);
  });

  testWidgets('PageMenu_ShouldShowNoDivider_WhenThereAreNoDestructiveEntries', (
    tester,
  ) async {
    await tester.pumpWidget(_host([entries.last]));
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.byType(Divider), findsNothing);
  });
}
