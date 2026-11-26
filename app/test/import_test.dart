import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
  });

  testWidgets('RidesScreen_ShouldOpenTheImport_WhenAStravaArchiveIsChosen', (
    tester,
  ) async {
    await startApp(
      tester,
      server.session(useCookies: true),
      pickFile: () async => XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'export_166520172.zip',
      ),
    );

    await tester.tap(find.byKey(const Key('rides-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('import-strava')));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(server.requests, contains('POST /api/v1/rides/imports'));
    expect(find.byKey(const Key('import-imported')), findsOneWidget);
    expect(find.text('2 rides imported'), findsOneWidget);
    expect(find.text('1 ride was already here'), findsOneWidget);
    // The count read of the total is the card's number, and the way out is the quiet button under it.
    expect(find.byKey(const Key('import-progress')), findsOneWidget);
    expect(find.textContaining('of 3 activities read'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Back to rides'),
      findsOneWidget,
    );
  });

  testWidgets(
    'ImportScreen_ShouldShowWhatCameOfThem_WhenTheImportIsStillRunning',
    (tester) async {
      // The second status poll waits on this gate, so the screen stays on the running state.
      const path = '/api/v1/rides/imports/import-1';
      final first = server.delayNext(path);
      final second = server.delayNext(path);
      first.complete();

      await startApp(
        tester,
        server.session(useCookies: true),
        pickFile: () async => XFile.fromData(
          Uint8List.fromList([1, 2, 3]),
          name: 'export_166520172.zip',
        ),
      );

      await tester.tap(find.byKey(const Key('rides-actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('import-strava')));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Still reading: the outcome row is there already, with the bar, as the mock-up draws it.
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('import-imported')), findsOneWidget);
      expect(find.text('1 ride imported'), findsOneWidget);
      expect(find.byKey(const Key('import-back')), findsNothing);

      second.complete();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('import-duplicates')), findsOneWidget);
      expect(find.text('1 ride was already here'), findsOneWidget);
      expect(find.byKey(const Key('import-back')), findsOneWidget);
    },
  );

  testWidgets('RidesScreen_ShouldImportNothing_WhenThePickerIsCancelled', (
    tester,
  ) async {
    await startApp(tester, server.session(useCookies: true));

    await tester.tap(find.byKey(const Key('rides-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('import-strava')));
    await tester.pumpAndSettle();

    expect(server.requests, isNot(contains('POST /api/v1/rides/imports')));
  });
}
