import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
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

    await tester.tap(find.byKey(const Key('import-strava')));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(server.requests, contains('POST /api/v1/rides/imports'));
    expect(find.byKey(const Key('import-imported')), findsOneWidget);
    expect(find.text('2 rides imported'), findsOneWidget);
    expect(find.text('1 ride was already here'), findsOneWidget);
  });

  testWidgets('RidesScreen_ShouldImportNothing_WhenThePickerIsCancelled', (
    tester,
  ) async {
    await startApp(tester, server.session(useCookies: true));

    await tester.tap(find.byKey(const Key('import-strava')));
    await tester.pumpAndSettle();

    expect(server.requests, isNot(contains('POST /api/v1/rides/imports')));
  });
}
