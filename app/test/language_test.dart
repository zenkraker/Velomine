import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/core/language_choice.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;

  setUp(() => server = FakeServer());

  testWidgets('App_ShouldApplyTheAccountLanguage_WhenSignedIn', (tester) async {
    final rider = server.add('rider@example.com', language: 'it');
    server.signInBrowser(rider);
    final choice = LanguageChoice(store: MemoryLanguageStore());

    await startApp(
      tester,
      server.session(useCookies: true),
      languageChoice: choice,
    );

    expect(choice.code, 'it');
  });

  testWidgets('LanguageChoiceButton_ShouldSaveToTheAccount_WhenChanged', (
    tester,
  ) async {
    final rider = server.add('rider@example.com');
    server.signInBrowser(rider);
    final choice = LanguageChoice(store: MemoryLanguageStore());
    await startApp(
      tester,
      server.session(useCookies: true),
      languageChoice: choice,
    );

    await tester.tap(find.byKey(const Key('language-choice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-en')));
    await tester.pumpAndSettle();

    expect(choice.code, 'en');
    expect(server.accounts[rider.email]!.language, 'en');
  });
}
