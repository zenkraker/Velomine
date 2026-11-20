import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/server_config.dart';
import 'package:velomine/features/auth/server_setup_screen.dart';
import 'package:velomine/l10n/generated/app_localizations.dart';
import 'package:velomine_api/api.dart';
import 'package:velomine/core/l10n.dart';
import 'package:velomine/root.dart';
import 'package:velomine/core/providers.dart';

import 'fake_server.dart';

ServerInfoResponse info() => ServerInfoResponse(
  name: 'Velomine',
  version: '0.1.0',
  mapTileUrl: 'https://tile.example/{z}/{x}/{y}.png',
  mapAttribution: '© Test Maps',
  emailAvailable: false,
  telemetryEnabled: false,
  sentryDsn: null,
  telemetryTermsVersion: 1,
  demo: false,
);

class _MemoryStore implements ServerConfigStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String? value) async => this.value = value;
}

void main() {
  Future<_MemoryStore> pump(
    WidgetTester tester, {
    required Future<ServerInfoResponse?> Function(String url) check,
    String initialUrl = '',
  }) async {
    final store = _MemoryStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serverInfoCheckProvider.overrideWithValue(check),
          serverConfigStoreProvider.overrideWithValue(store),
          isWebProvider.overrideWithValue(false),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ServerSetupScreen(initialUrl: initialUrl),
        ),
      ),
    );
    return store;
  }

  testWidgets(
    'ServerSetupScreen_ShouldCheckAndSaveAddress_WhenAddressIsValid',
    (tester) async {
      final store = await pump(tester, check: (_) async => info());

      await tester.enterText(
        find.byKey(const Key('server-url')),
        'https://velo.example/',
      );
      await tester.ensureVisible(find.byKey(const Key('server-save')));
      await tester.ensureVisible(find.byKey(const Key('server-save')));
      await tester.tap(find.byKey(const Key('server-save')));
      await tester.pumpAndSettle();

      expect(store.value, 'https://velo.example');
    },
  );

  testWidgets('ServerSetupScreen_ShouldRejectAddress_WhenItIsMalformed', (
    tester,
  ) async {
    var checked = false;
    final store = await pump(
      tester,
      check: (_) async {
        checked = true;
        return info();
      },
    );

    await tester.enterText(find.byKey(const Key('server-url')), 'velo.example');
    await tester.ensureVisible(find.byKey(const Key('server-save')));
    await tester.tap(find.byKey(const Key('server-save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('server-error')), findsOneWidget);
    expect(checked, isFalse);
    expect(store.value, isNull);
  });

  testWidgets('ServerSetupScreen_ShouldExplainUnreachable_WhenServerIsAbsent', (
    tester,
  ) async {
    final store = await pump(tester, check: (_) async => null);

    await tester.enterText(
      find.byKey(const Key('server-url')),
      'https://elsewhere.example',
    );
    await tester.ensureVisible(find.byKey(const Key('server-save')));
    await tester.tap(find.byKey(const Key('server-save')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not reach'), findsOneWidget);
    expect(store.value, isNull);
  });

  testWidgets('ServerSetupScreen_ShouldTimeOut_WhenUnanswered', (tester) async {
    final store = await pump(
      tester,
      check: (_) => Completer<ServerInfoResponse?>().future,
    );

    await tester.enterText(
      find.byKey(const Key('server-url')),
      'http://192.168.10.193:8080',
    );
    await tester.ensureVisible(find.byKey(const Key('server-save')));
    await tester.tap(find.byKey(const Key('server-save')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('server-save')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('server-error')), findsOneWidget);
    expect(find.textContaining('same network'), findsOneWidget);
    expect(store.value, isNull);
  });

  testWidgets('ServerSetupScreen_ShouldFillLastAddress_WhenAfterServerChange', (
    tester,
  ) async {
    await pump(
      tester,
      initialUrl: 'https://old.example',
      check: (_) async => info(),
    );

    expect(find.text('https://old.example'), findsOneWidget);
  });

  testWidgets('ServerSetupScreen_ShouldBeSkipped_WhenTheWindowIsTheWeb', (
    tester,
  ) async {
    // The web app is served by its own server, so it never asks which one to use.
    final server = FakeServer();
    final session = server.session(useCookies: true);
    await tester.runAsync(session.restore);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isWebProvider.overrideWithValue(true),
          serverConfigStoreProvider.overrideWithValue(_MemoryStore()),
          sessionProvider.overrideWith((ref) => session),
        ],
        child: const VelomineRoot(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ServerSetupScreen), findsNothing);
    expect(find.byKey(const Key('sign-in')), findsOneWidget);
  });
}
