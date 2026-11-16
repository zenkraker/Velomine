import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:velomine/core/confirm.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';

/// Opens the dialog and returns a reader for what it resolved to.
Future<bool? Function()> _open(WidgetTester tester) async {
  bool? result;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await confirmDestructive(
              context,
              title: 'Delete it?',
              body: 'Gone for good.',
              action: 'Delete',
              key: const Key('sure'),
            );
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return () => result;
}

void main() {
  testWidgets('confirmDestructive_ShouldReturnTrue_WhenActionIsTapped', (
    tester,
  ) async {
    final result = await _open(tester);
    await tester.tap(find.byKey(const Key('sure')));
    await tester.pumpAndSettle();

    expect(result(), isTrue);
  });

  testWidgets('confirmDestructive_ShouldReturnFalse_WhenCancelIsTapped', (
    tester,
  ) async {
    final result = await _open(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result(), isFalse);
  });

  testWidgets('confirmDestructive_ShouldReturnFalse_WhenBarrierIsTapped', (
    tester,
  ) async {
    final result = await _open(tester);
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();

    expect(result(), isFalse);
  });

  testWidgets('confirmDestructive_ShouldColourActionWithError_WhenShown', (
    tester,
  ) async {
    await _open(tester);
    final scheme = Theme.of(tester.element(find.byKey(const Key('sure'))))
        .colorScheme;
    final button = tester.widget<FilledButton>(find.byKey(const Key('sure')));

    expect(button.style?.backgroundColor?.resolve({}), scheme.error);
  });
}
