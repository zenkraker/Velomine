import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/language_choice.dart';

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
  test('English and Italian have the same keys and no empty translations', () {
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

  test('every declared placeholder appears in the Italian message', () {
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

  test(
    'a saved language is read back, and anything unknown means the device',
    () async {
      final italian = LanguageChoice(store: MemoryLanguageStore('it'));
      await italian.load();
      expect(italian.locale, const Locale('it'));

      final odd = LanguageChoice(store: MemoryLanguageStore('de'));
      await odd.load();
      expect(odd.locale, isNull);
    },
  );

  testWidgets('the app follows the device language until one is chosen', (
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

  testWidgets('choosing a language switches the app and is kept', (
    tester,
  ) async {
    final server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
    final store = MemoryLanguageStore();
    await startApp(
      tester,
      server.session(useCookies: true),
      languageChoice: LanguageChoice(store: store),
    );

    expect(find.text('Rides'), findsWidgets);

    await tester.tap(find.byKey(const Key('language-choice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-it')));
    await tester.pumpAndSettle();

    expect(find.text('Uscite'), findsWidgets);
    expect(find.text('Rides'), findsNothing);
    expect(store.value, 'it');

    // Back to following the device, which in tests is English.
    await tester.tap(find.byKey(const Key('language-choice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-system')));
    await tester.pumpAndSettle();
    expect(find.text('Rides'), findsWidgets);
    expect(store.value, 'system');
  });

  testWidgets('the sign-in screen is Italian too', (tester) async {
    final server = FakeServer();
    await startApp(
      tester,
      server.session(useCookies: true),
      languageChoice: LanguageChoice(store: MemoryLanguageStore('it')),
    );

    expect(find.text('Accedi'), findsOneWidget);
    expect(find.text('Crea un account'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('progress and dates render in Italian', (tester) async {
    final server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
    await startApp(
      tester,
      server.session(useCookies: true),
      languageChoice: LanguageChoice(store: MemoryLanguageStore('it')),
    );

    await tester.tap(find.text('Progressi'));
    await tester.pumpAndSettle();

    expect(find.text('Carico di allenamento'), findsOneWidget);
    expect(find.text('Obiettivi'), findsOneWidget);
    // The training range end (4 Nov 2026) in Italian: a short month name, not "Nov".
    expect(find.textContaining('4 nov'), findsOneWidget);
  });

  testWidgets('the rides list is Italian, including its empty state', (
    tester,
  ) async {
    final server = FakeServer();
    server.signInBrowser(server.add('rider@example.com'));
    await startApp(
      tester,
      server.session(useCookies: true),
      languageChoice: LanguageChoice(store: MemoryLanguageStore('it')),
    );

    expect(
      find.text('Nessuna uscita. Carica un file FIT, GPX o TCX.'),
      findsOneWidget,
    );
    expect(find.text('Carica uscita'), findsOneWidget);
  });
}
