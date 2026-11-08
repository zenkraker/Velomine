import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/features/auth/server_setup_screen.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';
import 'package:velomine_api/api.dart';

ServerInfoResponse info() => ServerInfoResponse(
  name: 'Velomine',
  version: '0.1.0',
  mapTileUrl: null,
  mapAttribution: null,
  emailAvailable: false,
);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required Future<ServerInfoResponse?> Function(String url) check,
    required Future<void> Function(String url) onSaved,
    String initialUrl = '',
  }) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ServerSetupScreen(
        initialUrl: initialUrl,
        check: check,
        onSaved: onSaved,
      ),
    ),
  );

  testWidgets(
    'a valid address is checked and saved without the trailing slash',
    (tester) async {
      String? saved;
      await pump(
        tester,
        check: (_) async => info(),
        onSaved: (url) async => saved = url,
      );

      await tester.enterText(
        find.byKey(const Key('server-url')),
        'https://velo.example/',
      );
      await tester.tap(find.byKey(const Key('server-save')));
      await tester.pumpAndSettle();

      expect(saved, 'https://velo.example');
    },
  );

  testWidgets('a malformed address is rejected before any request', (
    tester,
  ) async {
    var checked = false;
    await pump(
      tester,
      check: (_) async {
        checked = true;
        return info();
      },
      onSaved: (_) async {},
    );

    await tester.enterText(find.byKey(const Key('server-url')), 'velo.example');
    await tester.tap(find.byKey(const Key('server-save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('server-error')), findsOneWidget);
    expect(checked, isFalse);
  });

  testWidgets('an address with no Velomine server is explained', (
    tester,
  ) async {
    var saved = false;
    await pump(
      tester,
      check: (_) async => null,
      onSaved: (_) async => saved = true,
    );

    await tester.enterText(
      find.byKey(const Key('server-url')),
      'https://elsewhere.example',
    );
    await tester.tap(find.byKey(const Key('server-save')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not reach'), findsOneWidget);
    expect(saved, isFalse);
  });

  testWidgets('an address that never answers is given up on', (tester) async {
    var saved = false;
    await pump(
      tester,
      check: (_) => Completer<ServerInfoResponse?>().future,
      onSaved: (_) async => saved = true,
    );

    await tester.enterText(
      find.byKey(const Key('server-url')),
      'http://192.168.10.193:8080',
    );
    await tester.tap(find.byKey(const Key('server-save')));
    await tester.pump();

    expect(find.text('Checking…'), findsOneWidget);

    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('server-error')), findsOneWidget);
    expect(find.textContaining('same network'), findsOneWidget);
    expect(saved, isFalse);
  });

  testWidgets('the last address is filled in after Change server', (
    tester,
  ) async {
    await pump(
      tester,
      initialUrl: 'https://old.example',
      check: (_) async => info(),
      onSaved: (_) async {},
    );

    expect(find.text('https://old.example'), findsOneWidget);
  });
}
