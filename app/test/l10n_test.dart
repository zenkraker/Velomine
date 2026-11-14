import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';

Map<String, Object?> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, Object?>;

/// The messages, without the "@key" metadata entries.
Map<String, Object?> _messages(Map<String, Object?> arb) => {
  for (final e in arb.entries)
    if (!e.key.startsWith('@')) e.key: e.value,
};

void main() {
  test('L10n_ShouldHaveSameKeysAndNoEmptyValues_WhenComparingLocales', () {
    final en = _arb('en');
    final it = _arb('it');

    final enKeys = _messages(en).keys.toSet();
    final itKeys = _messages(it).keys.toSet();
    expect(
      itKeys,
      enKeys,
      reason: 'app_it.arb must have every key of app_en.arb',
    );
    for (final e in _messages(it).entries) {
      expect(e.value, isA<String>());
      expect((e.value! as String).trim(), isNotEmpty, reason: e.key);
    }
  });

  test('L10n_ShouldKeepEveryPlaceholder_WhenTranslatingToItalian', () {
    final en = _arb('en');
    final it = _messages(_arb('it'));

    for (final entry in en.entries) {
      if (!entry.key.startsWith('@') || entry.key == '@@locale') continue;
      final metadata = entry.value! as Map<String, Object?>;
      final placeholders =
          (metadata['placeholders'] as Map<String, Object?>?)?.keys ?? const [];
      final message = it[entry.key.substring(1)]! as String;
      for (final placeholder in placeholders) {
        expect(
          message,
          contains('{$placeholder'),
          reason: '${entry.key.substring(1)} lost {$placeholder}',
        );
      }
    }
  });

  testWidgets('AppLocalizations_ShouldFollowDeviceLanguage_WhenNoneIsChosen', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = [const Locale('it')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
    await startApp(tester, server.session(useCookies: true));

    expect(find.text('Uscite'), findsWidgets);
    expect(find.text('Rides'), findsNothing);
  });

  testWidgets('ProfileScreen_ShouldSwitchTheLanguage_WhenOneIsChosen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final server = FakeServer();
    final rider = server.add('rider@example.com');
    server.signInBrowser(rider);
    await startApp(tester, server.session(useCookies: true));

    expect(find.text('Rides'), findsWidgets);

    await openAccount(tester, 'profile');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profile-language')));
    await tester.tap(find.byKey(const Key('profile-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Italiano').last);
    await tester.pumpAndSettle();

    expect(find.text('Uscite'), findsWidgets);
    expect(find.text('Rides'), findsNothing);
    expect(server.accounts[rider.email]!.language, 'it');
  });

  testWidgets('L10n_ShouldLocalizeSignInScreen_WhenItalian', (tester) async {
    tester.platformDispatcher.localesTestValue = [const Locale('it')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final server = FakeServer();
    await startApp(tester, server.session(useCookies: true));

    expect(find.text('Accedi'), findsOneWidget);
    expect(find.text('Crea un account'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('L10n_ShouldLocalizeProgressDates_WhenItalian', (tester) async {
    final server = FakeServer();
    server.signInBrowser(server.add('rider@example.com', language: 'it'));
    await startApp(tester, server.session(useCookies: true));

    await tester.tap(find.text('Progressi'));
    await tester.pumpAndSettle();

    expect(find.text('Carico di allenamento'), findsOneWidget);
    expect(find.text('Obiettivi'), findsOneWidget);
    // The training range end (4 Nov 2026) in Italian: a short month name, not "Nov".
    expect(find.textContaining('4 nov'), findsOneWidget);
  });

  testWidgets('AppLocalizations_ShouldTranslateRidesList_WhenItalian', (
    tester,
  ) async {
    final server = FakeServer();
    server.signInBrowser(server.add('rider@example.com', language: 'it'));
    await startApp(tester, server.session(useCookies: true));

    expect(
      find.text('Nessuna uscita. Carica un file FIT, GPX o TCX.'),
      findsOneWidget,
    );
    expect(find.text('Carica uscita'), findsOneWidget);
  });
}
